import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LikeService {
  static const String _boxName = 'likesBox';
  static const String _keyLikeCounts = 'likeCounts';   // نقشهٔ شمارش لوکال (اگر لازم شد)
  static const String _keyLikedMeta = 'likedMeta';     // id -> {name, image}

  // ---------------- Boot ----------------
  static Future<void> initHiveBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  static Box get _box => Hive.box(_boxName);

  // ---------------- Toggle / State ----------------
  /// فقط وضعیت لایک را ذخیره می‌کنیم (true/false) با کلید خودِ id بازی.
  /// اگر name/image پاس داده شوند، متادیتا برای نمایش در Likes ذخیره می‌شود.
  static Future<void> toggleLike(
    String gameId, {
    String? name,
    String? image,
  }) async {
    // اطمینان از باز بودن باکس
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }

    final isCurrentlyLiked = _box.get(gameId, defaultValue: false) as bool;
    final Map likeCounts = Map<String, int>.from(_box.get(_keyLikeCounts, defaultValue: {}));

    // شمارش لوکال فقط برای هم‌خوانی با نسخهٔ قبلی‌ات نگه‌داری می‌شود
    int currentCount = likeCounts[gameId] ?? 0;
    if (isCurrentlyLiked) {
      // Unlike
      currentCount = currentCount > 0 ? currentCount - 1 : 0;

      // متادیتا را هم پاک کن
      final meta = Map<String, dynamic>.from(_box.get(_keyLikedMeta, defaultValue: {}));
      if (meta.containsKey(gameId)) {
        meta.remove(gameId);
        await _box.put(_keyLikedMeta, meta);
      }
    } else {
      // Like
      currentCount += 1;

      // اگر متادیتا داریم ذخیره کنیم تا Likes بدون allGames هم رندر شود
      if (name != null || image != null) {
        final meta = Map<String, dynamic>.from(_box.get(_keyLikedMeta, defaultValue: {}));
        meta[gameId] = {
          if (name != null) 'name': name,
          if (image != null) 'image': image,
        };
        await _box.put(_keyLikedMeta, meta);
      }
    }

    // وضعیت نهایی را ذخیره کن
    await _box.put(gameId, !isCurrentlyLiked);
    likeCounts[gameId] = currentCount;
    await _box.put(_keyLikeCounts, likeCounts);

    if (kDebugMode) {
      print('Like toggled: $gameId -> ${!isCurrentlyLiked} (local delta=$currentCount)');
    }
  }

  static bool isLiked(String gameId) {
    return _box.get(gameId, defaultValue: false) as bool;
  }

  /// فقط ورودی‌های بولی (کلید=gameId، value=bool) را برمی‌گردانیم.
  static Map<String, bool> getAllLikes() {
    final map = _box.toMap();
    final result = <String, bool>{};
    for (final entry in map.entries) {
      if (entry.key is String && entry.value is bool) {
        result[entry.key as String] = entry.value as bool;
      }
    }
    return result;
  }

  static Future<void> clearAllLikes() async {
    await _box.clear();
  }

  // ---------------- Count (نمایش) ----------------
  /// نمایش شمارش لایک:
  /// عدد پایه از بازی (initialValue) + 1 اگر کاربر لایک کرده باشد؛ وگرنه همان پایه.
  /// توجه: این تابع هیچ شمارنده‌ای را در Hive تغییر نمی‌دهد.
  static Future<int> getLikeCount(String gameId, {int initialValue = 0}) async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    final liked = _box.get(gameId, defaultValue: false) as bool;
    return initialValue + (liked ? 1 : 0);
  }

  // ---------------- Optional local delta helpers (همان نسخهٔ قبلی‌ات) ----------------
  static Future<void> incrementLikeCount(String gameId) async {
    final counts = Map<String, int>.from(_box.get(_keyLikeCounts, defaultValue: {}));
    final updatedCount = (counts[gameId] ?? 0) + 1;
    counts[gameId] = updatedCount;
    await _box.put(_keyLikeCounts, counts);
  }

  static Future<void> decrementLikeCount(String gameId) async {
    final counts = Map<String, int>.from(_box.get(_keyLikeCounts, defaultValue: {}));
    final updatedCount = (counts[gameId] ?? 1) - 1;
    counts[gameId] = updatedCount < 0 ? 0 : updatedCount;
    await _box.put(_keyLikeCounts, counts);
  }

  // ---------------- Server Sync (همان امضای قبلی بدون آرگومان) ----------------
  static Future<void> syncLikesToServer() async {
    final likesBool = getAllLikes();
    final filteredIds = likesBool.entries.where((e) => e.value == true).map((e) => e.key).toList();

    final payload = {'likes': filteredIds};

    try {
      final response = await http.post(
        Uri.parse('http://192.168.164.101:5000/syncLikes'), // ← همون IP خودت
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) print('✅ Likes synced to server!');
      } else {
        if (kDebugMode) print('❌ Sync failed: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Sync error: $e');
    }
  }

  // ---------------- For LikesPage fallback ----------------
  /// وقتی `allGames` پاس داده نشده، از این استفاده کن:
  /// خروجی: [{id, name, image}]
  static List<Map<String, String>> getLikedItemsForDisplay() {
    final likes = getAllLikes();
    final likedIds = likes.entries.where((e) => e.value).map((e) => e.key).toSet();
    if (likedIds.isEmpty) return const [];

    final meta = Map<String, dynamic>.from(_box.get(_keyLikedMeta, defaultValue: {}));
    return likedIds.map((id) {
      final m = Map<String, dynamic>.from(meta[id] ?? {});
      return {
        'id': id,
        'name': (m['name'] ?? id).toString(),
        'image': (m['image'] ?? '').toString(),
      };
    }).toList();
  }
}
