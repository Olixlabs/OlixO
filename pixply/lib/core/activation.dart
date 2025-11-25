// lib/core/activation.dart
// Unified activation client for Pixply app to work with Make.com scenario.
// - Normalizes code (removes hyphens, uppercases) and also sends original form
// - Sends device/app metadata fields expected by your Make scenario
// - Treats unlock as valid **only** when body == "allow" (HTTP 200)
// - Anything else maps to deny/invalid/error and does NOT unlock the app

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum ActivationResult { allow, deny, invalid, error }

class ActivationService {
  ActivationService({
    Uri? webhookUrl,
    this.timeout = const Duration(seconds: 12),
    SharedPreferences? prefs,
    bool? enforce16CharCodes,
  })  : webhookUrl = webhookUrl ?? Uri.parse(_webhookUrl),
        _prefsFuture = prefs != null
            ? Future.value(prefs)
            : SharedPreferences.getInstance(),
        _enforce16Len = enforce16CharCodes ?? true;

  /// Make.com custom webhook URL (the "App activation" one)
  final Uri webhookUrl;
  final Duration timeout;
  final Future<SharedPreferences> _prefsFuture;
  final bool _enforce16Len;

  // Prefs keys
  static const String _webhookUrl =
      'https://hook.eu2.make.com/oovwvz2wit1sen3ckrbv9wlgqi4u4ulc';
  static const _kActivated = 'pixply_activated';
  static const _kActivatedAt = 'pixply_activated_at';
  static const _kActivatedCodeDisplay = 'pixply_activated_code_display';

  /// Public: check if previously activated (persisted)
  Future<bool> isActivated() async {
    final p = await _prefsFuture;
    return p.getBool(_kActivated) ?? false;
  }

  /// Attempt to activate with a raw code typed by user.
  /// You may pass optional [extra] fields to be merged into the payload
  /// (e.g., BLE device details). Returns server's decision.
  Future<ActivationResult> activate(String rawCode,
      {Map<String, dynamic>? extra}) async {
    // Harden client-side behaviour so app doesn't unlock on malformed input.
    final codePlain = _normalizeCode(rawCode);
    if (codePlain == null) {
      return ActivationResult.invalid;
    }

    // Collect device + app info expected by Make
    final device = await _getDeviceSummary();
    final pkg = await PackageInfo.fromPlatform();

    final payload = <String, dynamic>{
      // Keep both forms for convenience in Make / Sheets
      'code': _formatDisplay(codePlain), // grouped by 4 (UI friendly)
      'code_plain': codePlain, // normalized without hyphens

      // Expected by your sheet's columns / scenario
      'deviceModel': device.model,
      'sdk': device.sdk, // e.g., iOS 18.0 / Android 34
      'appVersion': '${pkg.version}+${pkg.buildNumber}',
      // 'ip': await _bestEffortIp(), // may be null if offline
      'sentAt': DateTime.now().toUtc().toIso8601String(),
    };
    if (extra != null && extra.isNotEmpty) {
      // Merge caller-provided fields (override defaults if duplicated)
      payload.addAll(extra);
    }

    final result = await _postToWebhook(payload);

    // Persist only on ALLOW
    if (result == ActivationResult.allow) {
      final p = await _prefsFuture;
      await p.setBool(_kActivated, true);
      await p.setString(
          _kActivatedAt, DateTime.now().toUtc().toIso8601String());
      await p.setString(_kActivatedCodeDisplay, _formatDisplay(codePlain));
    }

    return result;
  }

  /// Normalize user input -> uppercase A-Z0-9 (any length > 0), or null if empty.
  /// Normalize user input -> uppercase A‑Z0‑9 (removing any separators).  Only
  /// codes that result in exactly 16 characters are considered valid; any
  /// other length returns null to prevent accidental unlock.  This prevents
  /// arbitrary 16‑digit strings with non‑alphanumeric characters from being
  /// accepted and mirrors the 16‑character codes stored in the Google Sheet.
  String? _normalizeCode(String input) {
    if (input.isEmpty) return null;
    final cleaned = input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (_enforce16Len && cleaned.length != 16) return null;
    if (cleaned.isEmpty) return null;
    return cleaned;
  }

  /// Group plain code for display in chunks of 4
  String _formatDisplay(String plain) {
    if (plain.isEmpty) return '';
    final b = StringBuffer();
    for (var i = 0; i < plain.length; i++) {
      b.write(plain[i]);
      if (i % 4 == 3 && i != plain.length - 1) b.write('-');
    }
    return b.toString();
  }

  Future<_DeviceSummary> _getDeviceSummary() async {
    final info = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        return _DeviceSummary(model: 'Web', sdk: 'Web');
      } else if (Platform.isAndroid) {
        final a = await info.androidInfo;
        final model = '${a.manufacturer} ${a.model}'.trim();
        final sdk = 'Android ${a.version.sdkInt}';
        return _DeviceSummary(model: model, sdk: sdk);
      } else if (Platform.isIOS) {
        final i = await info.iosInfo;
        final model = i.utsname.machine ?? i.model ?? 'iPhone';
        final sdk = 'iOS ${i.systemVersion ?? ""}'.trim();
        return _DeviceSummary(model: model, sdk: sdk);
      } else if (Platform.isMacOS) {
        final m = await info.macOsInfo;
        return _DeviceSummary(
            model: m.model ?? 'Mac', sdk: 'macOS ${m.osRelease ?? ""}');
      }
    } catch (_) {
      // ignore and fall through
    }
    return _DeviceSummary(model: 'Unknown', sdk: 'Unknown');
  }

  Future<String?> _bestEffortIp() async {
    // We avoid external requests here; leave null and let Make log the source IP.
    // If you later add a local IP fetch, ensure it never blocks activation.
    return null;
  }

  Future<ActivationResult> _postToWebhook(Map<String, dynamic> payload) async {
    try {
      final res = await http
          .post(
            webhookUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      final status = res.statusCode;
      final rawBody = res.body;
      final body = rawBody.trim().toLowerCase();

      // Strict contract: only 200 + "allow" unlocks the app.
      if (status != 200) return ActivationResult.error;
      if (body == 'allow') return ActivationResult.allow;
      // Treat Make.com's "duplicate" as a used/denied code
      if (body == 'deny' || body == 'duplicate') return ActivationResult.deny;
      if (body == 'invalid' || body.isEmpty) return ActivationResult.invalid;

      // Fallback: some scenarios may return JSON (e.g. filterRows output);
      // if it's a non-empty list, treat as ALLOW; empty list is INVALID.
      try {
        final decoded = jsonDecode(rawBody);
        if (decoded is List) {
          return decoded.isEmpty
              ? ActivationResult.invalid
              : ActivationResult.allow;
        }
      } catch (_) {
        // ignore parse errors and fall through
      }

      return ActivationResult.invalid;
    } catch (_) {
      return ActivationResult.error;
    }
  }
}

class _DeviceSummary {
  final String model;
  final String sdk;
  _DeviceSummary({required this.model, required this.sdk});
}
