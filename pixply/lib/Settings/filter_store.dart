import 'package:flutter/material.dart';

class FilterStore extends ChangeNotifier {
  // ---------- State ----------
  String? selectedDifficulty;            // Easy | Medium | Hard | Professional
  final Set<String> selectedMindEffects = {}; // Creativity, Math, Memory, Risk, Social, Focus, Logic
  int? selectedPlayerCount;              // 2 | 3 | 4
  int? minAge;
  int? maxAge;

  // Play time (هر دو را پشتیبانی می‌کنیم؛ اگر Category ست باشد، Range نادیده گرفته می‌شود)
  String? selectedPlayTimeCategory;      // 'Under 15 min' | '15–30 min' | '30–60 min' | '60+ min'
  int? minPlayTime;                      // دقیقه؛ مثلا 0/15/30/60
  int? maxPlayTime;

  final Set<String> selectedCategories = {};
  String? selectedCountry;               // هم‌معنی selectedRegion

  // اگر UI هنوز از selectedRegion استفاده می‌کند:
  String? get selectedRegion => selectedCountry;
  set selectedRegion(String? v) {
    selectedCountry = v;
    notifyListeners();
  }
  final Set<String> selectedDifficulties = {};

  // ---------- Mutations ----------
  void setDifficulty(String? value) {
    selectedDifficulty = value == null ? null : _canonDifficulty(value);
    notifyListeners();
  }
  void toggleDifficulty(String value) {
  final v = _canonDifficulty(value);
  if (selectedDifficulties.contains(v)) {
    selectedDifficulties.remove(v);
  } else {
    selectedDifficulties.add(v);
  }
  // وقتی چندتایی فعال است، مقدار تکی را خنثی نگه می‌داریم
  selectedDifficulty = null;
  notifyListeners();
}

void clearDifficulties() {
  selectedDifficulties.clear();
  notifyListeners();
}
bool _setEquals(Set<String> a, Set<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final x in a) {
    if (!b.contains(x)) return false;
  }
  return true;
}



  void toggleMindEffect(String effect) {
    final v = _canonMind(effect);
    if (selectedMindEffects.contains(v)) {
      selectedMindEffects.remove(v);
    } else {
      selectedMindEffects.add(v);
    }
    notifyListeners();
  }

  void setPlayerCount(int? value) {
    selectedPlayerCount = value;
    notifyListeners();
  }

  void setAgeRange(int? min, int? max) {
    minAge = min;
    maxAge = max;
    notifyListeners();
  }

  void setPlayTimeCategory(String? value) {
    selectedPlayTimeCategory = value == null ? null : _canonPlayTime(value);
    notifyListeners();
  }

  void setPlayTimeRange(int? min, int? max) {
    minPlayTime = min;
    maxPlayTime = max;
    notifyListeners();
  }

  void toggleCategory(String value) {
    final v = _canonCategory(value);
    if (selectedCategories.contains(v)) {
      selectedCategories.remove(v);
    } else {
      selectedCategories.add(v);
    }
    notifyListeners();
  }

  void clearCategories() {
    selectedCategories.clear();
    notifyListeners();
  }

  void setCountry(String? value) {
    selectedCountry = value == null ? null : _canonCountry(value);
    notifyListeners();
  }

  void clearAll() {
    selectedDifficulty = null;
    selectedMindEffects.clear();
    selectedPlayerCount = null;
    minAge = null;
    maxAge = null;

    selectedPlayTimeCategory = null;
    minPlayTime = null;
    maxPlayTime = null;

    selectedCategories.clear();
    selectedCountry = null;
    selectedDifficulties.clear();
    notifyListeners();
  }

  bool get hasActiveFilters {
    return selectedDifficulty != null ||
        selectedDifficulties.isNotEmpty ||
        selectedMindEffects.isNotEmpty ||
        selectedPlayerCount != null ||
        minAge != null ||
        maxAge != null ||
        selectedPlayTimeCategory != null ||
        minPlayTime != null ||
        maxPlayTime != null ||
        selectedCategories.isNotEmpty ||
        selectedCountry != null;
  }

  // ---------- Core filtering (AND بین خانواده‌ها، OR داخل هر خانواده) ----------
  List<Map<String, dynamic>> applyTo(List<Map<String, dynamic>> games) {
    final allCategories = _collectAllCategories(games);

    return games.where((game) {
      final gDiff   = _extractDifficulty(game);         // Set<String>
      final gPlayers= _extractPlayers(game);           // Set<int>
      final gAge    = _extractAge(game);               // (min,max)?
      final gPTimeC = _canonPlayTime((game['playTimeCategory'] ?? '').toString());
      final gCats   = _extractCategories(game);        // Set<String>
      final gCountry= _canonCountry((game['country'] ?? '').toString());
      final gMind   = _extractMind(game);              // Set<String>

      bool ok = true;

      // Difficulty
      if (selectedDifficulties.isNotEmpty) {
          final wanted = selectedDifficulties.map(_canonDifficulty).toSet();
  ok = ok && _setEquals(gDiff, wanted);
} else if (selectedDifficulty != null) {
    final wanted = {_canonDifficulty(selectedDifficulty!)};
  ok = ok && _setEquals(gDiff, wanted);
      }

      // MindEffect: OR داخلی (intersection)
      if (selectedMindEffects.isNotEmpty) {
        ok = ok && gMind.intersection(selectedMindEffects.map(_canonMind).toSet()).isNotEmpty;
      }

      // Players
      if (selectedPlayerCount != null) {
        ok = ok && gPlayers.contains(selectedPlayerCount);
      }

      // Age overlap
      if (minAge != null || maxAge != null) {
        if (gAge == null) return false;
        final selMin = minAge ?? 0;
        final selMax = maxAge ?? 999;
        ok = ok && _rangesOverlap(gAge.$1, gAge.$2, selMin, selMax);
      }

      // PlayTime (Category اولویت دارد بر Range)
      if (selectedPlayTimeCategory != null && selectedPlayTimeCategory!.isNotEmpty) {
        ok = ok && gPTimeC == _canonPlayTime(selectedPlayTimeCategory!);
      } else if (minPlayTime != null || maxPlayTime != null) {
        final (gMin, gMax) = _playTimeBandToRange(gPTimeC); // نگاشت برچسب دیتاست به بازه
        final selMin = minPlayTime ?? 0;
        final selMax = maxPlayTime ?? 999;
        ok = ok && _rangesOverlap(gMin, gMax, selMin, selMax);
      }

      // Category: اگر همه انتخاب شدند → بدون فیلتر
 if (selectedCategories.isNotEmpty) {
  final wanted = selectedCategories.map(_canonCategory).toSet();
   final effective = wanted.intersection(allCategories);
   if (effective.isNotEmpty && effective.length < allCategories.length) {
     ok = ok && gCats.intersection(effective).isNotEmpty;
   }
 }

      // Country
      if (selectedCountry != null && selectedCountry!.isNotEmpty) {
        ok = ok && _countryMatches(selectedCountry!, gCountry);
      }

      return ok;
    }).toList();
  }

  // ---------- Helpers ----------
  Set<String> _extractDifficulty(Map<String, dynamic> game) {
    final raw = game['difficulty'];
    final set = <String>{};
    if (raw is String && raw.trim().isNotEmpty) {
      set.add(_canonDifficulty(raw));
    } else if (raw is List) {
      for (final v in raw) {
        if (v != null) set.add(_canonDifficulty(v.toString()));
      }
    }
    // سفت‌وسخت در برابر داده‌ی اشتباه
    set.removeWhere((e) => e.toLowerCase() == 'difficulty');
    return set;
  }

  Set<int> _extractPlayers(Map<String, dynamic> game) {
    final raw = (game['players'] ?? '').toString().trim();
    if (raw.isEmpty) return {};
    final normalized = raw.replaceAll('_', '-');
    if (RegExp(r'^\d+$').hasMatch(normalized)) {
      return {int.parse(normalized)};
    }
    final m = RegExp(r'^(\d+)\s*-\s*(\d+)$').firstMatch(normalized);
    if (m != null) {
      final a = int.parse(m.group(1)!);
      final b = int.parse(m.group(2)!);
      final set = <int>{};
      for (var i = a; i <= b; i++) {
        set.add(i);
      }
      return set;
    }
    return {};
  }

  (int,int)? _extractAge(Map<String, dynamic> game) {
    final age = game['ageRange'];
    if (age is Map) {
      final min = int.tryParse(age['min'].toString());
      final max = int.tryParse(age['max'].toString());
      if (min != null && max != null) return (min, max);
    }
    return null;
  }

  Set<String> _extractCategories(Map<String, dynamic> game) {
    final raw = game['category'];
    final out = <String>{};
    if (raw is List) {
      for (final v in raw) {
        if (v == null) continue;
        out.add(_canonCategory(v.toString()));
      }
    } else if (raw is String && raw.isNotEmpty) {
      out.add(_canonCategory(raw));
    }
    // پاک‌سازی خطاهای دیتاست
    out.removeWhere((e) => e.toLowerCase() == 'category');
    return out;
  }

  Set<String> _extractMind(Map<String, dynamic> game) {
    final raw = game['mindEffect'];
    final out = <String>{};
    if (raw is List) {
      for (final v in raw) {
        if (v == null) continue;
        out.add(_canonMind(v.toString()));
      }
       } else if (raw is String && raw.trim().isNotEmpty) {
  out.add(_canonMind(raw));
    }
    out.removeWhere((e) => e.toLowerCase() == 'mindeffect');
    return out;
  }

  Set<String> _collectAllCategories(List<Map<String, dynamic>> games) {
    final set = <String>{};
    for (final g in games) {
      set.addAll(_extractCategories(g));
    }
    return set;
  }

  bool _rangesOverlap(int aMin, int aMax, int bMin, int bMax) {
    return aMin <= bMax && bMin <= aMax;
  }

  // --- Canonicalizers ---
  String _canonDifficulty(String v) {
    final s = v.trim().toLowerCase();
    switch (s) {
      case 'easy': return 'Easy';
      case 'medium': return 'Medium';
      case 'hard': return 'Hard';
      case 'professional': return 'Professional';
      default: return v.trim();
    }
  }

  String _canonCategory(String v) {
    final s = v.trim();
    if (s.toLowerCase() == 'asymmetrical') return 'Asymmetric';
    if (s.toLowerCase() == 'capture') return 'Capturing';
    if (s.replaceAll(' ', '').toLowerCase() == 'deduction/mindgames') return 'Deduction/MindGames';
    return s;
  }

  String _canonMind(String v) {
    final s = v.trim();
    switch (s.toLowerCase()) {
      case 'creativity': return 'Creativity';
      case 'math': return 'Math';
      case 'memory': return 'Memory';
      case 'risk': return 'Risk';
      case 'social': return 'Social';
      case 'focus': return 'Focus';
      case 'logic': return 'Logic';
      default: return s;
    }
  }

  String _canonPlayTime(String v) {
    final s = v.trim()
        .replaceAll('–', '-') // en dash -> hyphen
        .replaceAll('—', '-') // em dash -> hyphen
        .replaceAll(RegExp(r'\s+'), ' ');
    switch (s.toLowerCase()) {
      case 'under 15 min': return 'Under 15 min';
      case '15-30 min':    return '15–30 min';
      case '30-60 min':    return '30–60 min';
      case '60+ min':      return '60+ min';
      default: return v.trim();
    }
  }

  String _canonCountry(String v) {
    final s = v.trim();
    if (s.toLowerCase() == 'usa') return 'United States';
    if (s.toLowerCase() == 'mexic') return 'Mexico';
     final low = s.toLowerCase();
 if (low == 'usa' || low == 'us' || low == 'u.s.' || low == 'u.s.a.' || low == 'united states of america') {
  return 'United States';
 }
 if (low == 'uk' || low == 'u.k.') return 'United Kingdom';
 if (low == 'persia') return 'Iran';
 if (low == 'mexic') return 'Mexico';
    return s;
  }
bool _countryMatches(String selected, String gameCountry) {
  final s = _canonCountry(selected);
  final g = _canonCountry(gameCountry);
  if (s == g) return true;

  const Map<String, Set<String>> synonyms = {
    'United Kingdom': {'United Kingdom','UK','England','Scotland','Wales','Ireland'},
    'United States': {'United States','USA','US','United States of America'},
    'Iran': {'Iran','Persia'},
  };

  final set = synonyms[s];
  return set != null && set.contains(g);
}

  // نگاشت برچسب دیتاست به بازهٔ زمانی
  (int,int) _playTimeBandToRange(String band) {
    final b = _canonPlayTime(band);
    switch (b) {
      case 'Under 15 min': return (0, 14);
      case '15–30 min':    return (15, 30);
      case '30–60 min':    return (30, 60);
      case '60+ min':      return (61, 999);
      default:             return (0, 999);
    }
  }
}
