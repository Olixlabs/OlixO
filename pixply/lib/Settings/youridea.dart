// youridea.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:pixply/env.dart';

// 🔗 Paste your Make.com webhook URL here:

class YourIdeaPage extends StatefulWidget {
  const YourIdeaPage({super.key});

  @override
  State<YourIdeaPage> createState() => _YourIdeaPageState();
}

class _YourIdeaPageState extends State<YourIdeaPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _nameC  = TextEditingController();
  final _commentC = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _emailC.dispose();
    _nameC.dispose();
    _commentC.dispose();
    super.dispose();
  }

  String? _emailValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null; // optional
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!re.hasMatch(s)) return 'Enter a valid email';
    return null;
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _send() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _sending = true);
    try {
      final uri = Uri.parse(ideaWebhookUrl);
      // Payload sent to Make → Google Sheets
      final body = {
        'source': 'idea',
        'submitted_at': DateTime.now().toIso8601String(),
        'email': _emailC.text.trim(),
        'name': _nameC.text.trim(),
        'comment': _commentC.text.trim(),
      };

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks! We’ll review your idea.')),
        );
        _commentC.clear(); // keep email/name so they can submit again easily
      } else {
        // Only show generic error; never expose backend details.
        _showError('Send failed (${res.statusCode}). Try again.');
      }
    } on SocketException catch (e) {
      // Offline or DNS issues. Log internally, show friendly text.
      debugPrint('SocketException while sending idea: $e');
      _showError('No internet connection. Check and try again.');
    } on http.ClientException catch (e) {
      // Network/client error from package:http (may wrap SocketException).
      debugPrint('HTTP ClientException while sending idea: ${e.message} uri=${e.uri}');
      _showError('Network error. Please try again.');
    } catch (e, st) {
      // Any other unexpected errors
      debugPrint('Unexpected error while sending idea: $e\n$st');
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  InputDecoration _deco({required String label, required String hint}) {
    final base = Colors.white.withValues(alpha: 0.35);
    final focus = Colors.white.withValues(alpha: 0.85);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 14),
      hintStyle: const TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontSize: 14),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: base, width: 1)),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: focus, width: 1.2)),
      errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.red)),
      focusedErrorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.red)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              SizedBox(
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 71, height: 71,
                          decoration: const BoxDecoration(
                            color: Colors.black, shape: BoxShape.circle),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/back.svg',
                              width: 35, height: 35,
                              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      'Your Ideas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Description
              const Text(
                "Got an idea for Pixply? Whether it’s a new game, a feature for the app, a hardware add-on, UI improvement, or anything else—share it with us here. "
                "You can add your email or name if you want us to get back to you, or keep it anonymous. "
                "We review every submission and will reach out if we need more details.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 26),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email (optional)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Email (optional)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400)),
                    ),
                    TextFormField(
                      controller: _emailC,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w400),
                      decoration: _deco(label: '', hint: 'Enter Email'),
                      validator: _emailValidator,
                    ),
                    const SizedBox(height: 24),

                    // Name (optional)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Your Name (optional)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400)),
                    ),
                    TextFormField(
                      controller: _nameC,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w400),
                      decoration: _deco(label: '', hint: 'Write your name'),
                    ),
                    const SizedBox(height: 24),

                    // Comment (required)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Your comment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400)),
                    ),
                    TextFormField(
                      controller: _commentC,
                      minLines: 3, maxLines: 7,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w400),
                      decoration: _deco(label: '', hint: 'Write your comment'),
                      validator: _required,
                    ),

                    const SizedBox(height: 30),

                    // Send button
                    SizedBox(
                      height: 82,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _sending ? null : _send,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: _sending
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Send',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins')),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
