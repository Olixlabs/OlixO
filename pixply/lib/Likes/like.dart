import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:led_ble_lib/led_ble_lib.dart';
import 'package:pixply/games.dart';
import 'package:pixply/Settings/settinggeneral.dart';
import 'package:pixply/explore/explore.dart';
import 'package:pixply/data/data.dart';
import 'dart:math' as math;

class LikesPage extends StatelessWidget {
  final LedBluetooth bluetooth;
  final bool isConnected;
  final List<Map<String, dynamic>>? allGames;

  const LikesPage({
    super.key,
    required this.bluetooth,
    required this.isConnected,
    this.allGames,
  });

  @override
  Widget build(BuildContext context) {
    const double footerHeight = 82;
    const double footerBottomGap = 20;
    const double listBottomPadding = footerHeight + footerBottomGap + 8;

    final likesBox = Hive.box('likesBox');

    return Scaffold(
      backgroundColor: const Color.fromRGBO(49, 49, 49, 1),
      body: Stack(
        children: [
          SafeArea(
            child: ValueListenableBuilder(
              valueListenable: likesBox.listenable(),
              builder: (context, box, _) {
                final likedIds = box
                    .toMap()
                    .entries
                    .where((e) => e.key is String && e.value == true)
                    .map((e) => e.key as String)
                    .toSet();

                List<Map<String, dynamic>> all = allGames ?? <Map<String, dynamic>>[];
                if (all.isEmpty) {
                  final data = GameData.getGamesData();
                  all = data.map((g) {
                    final m = Map<String, dynamic>.from(g);
                    if (m['page'] == null && m['pageBuilder'] != null) {
                      final builder = m['pageBuilder'] as dynamic Function(LedBluetooth, bool);
                      m['page'] = builder(bluetooth, isConnected);
                    }
                    return m;
                  }).toList();
                }
                final likedGames = all.where((g) => likedIds.contains(g['id'])).toList();

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Liked',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 45,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) {
                                    return LikedSearchSheet(
                                      likedGames: likedGames,
                                      onOpenGame: (game) {
                                        final page = game['page'];
                                        if (page != null && page is Widget) {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
                                        } else {
                                          Navigator.of(context).pop();
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => GamesScreen(
                                                bluetooth: bluetooth,
                                                isConnected: isConnected,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  },
                                );
                              },
                              child: Container(
                                width: 71,
                                height: 71,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(51, 255, 255, 255), // 20% alpha = 51/255
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/search.svg',
                                    width: 35,
                                    height: 35,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                   const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    // no games
                    if (likedGames.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(90, 90, 90, 1),
                              // borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Text('No game has been liked.',
                                  style: TextStyle(color: Colors.white70)),
                            ),
                          ),
                        ),
                      )
                    else
                      // grid of liked games
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, listBottomPadding),
                        sliver: SliverLayoutBuilder(
                          builder: (context, constraints) {
                            final double width = constraints.crossAxisExtent; 
                            const double gap = 20; 
                            const double minCardWidth = 130; 
                            int crossAxisCount = math.max(
                              2,
                              ( (width + gap) / (minCardWidth + gap) ).floor(),
                            );
                            crossAxisCount = crossAxisCount.clamp(2, 5);

                            final double totalGaps = gap * (crossAxisCount - 1);
                            final double cardSize = (width - totalGaps) / crossAxisCount;

                            return SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: gap,
                                crossAxisSpacing: gap,
                                childAspectRatio: 1.0, 
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, i) {
                                  final game = likedGames[i];
                                  return _GameImageCard(
                                    id: game['id'],
                                    imagePath: game['image'],
                                    size: cardSize,
                                    onOpen: () {
                                      final page = game['page'];
                                      if (page != null && page is Widget) {
                                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
                                      } else {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => GamesScreen(
                                              bluetooth: bluetooth,
                                              isConnected: isConnected,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                                childCount: likedGames.length,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // footer navigation
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 323,
                height: footerHeight,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(41),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavItem(context, 'assets/planet-saturn 1.svg', 0),
                    _buildNavItem(context, 'assets/dices.svg', 1),
                    _buildNavItem(context, 'assets/Heart 1.svg', 2),
                    _buildNavItem(context, 'assets/Setting.svg', 3),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String asset, int index) {
    final bool isSelected = (index == 2);

    return GestureDetector(
      onTap: () {
        if (index == 2) return;

        if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => GamesScreen(
                bluetooth: bluetooth,
                isConnected: isConnected,
              ),
            ),
          );
        } else if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DiscoverPage(
                bluetooth: bluetooth,
                isConnected: isConnected,
              ),
            ),
          );
        } else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SettingsGeneral(
                bluetooth: bluetooth,
                isConnected: isConnected,
              ),
            ),
          );
        }
      },
      child: Container(
        width: 71,
        height: 71,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color.fromRGBO(50, 50, 50, 1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.asset(
            asset,
            width: 36,
            height: 36,
            colorFilter: ColorFilter.mode(
              isSelected ? Colors.black : Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

/// card for each liked game in the grid
class _GameImageCard extends StatelessWidget {
  final String id;
  final String? imagePath;
  final double size; 
  final VoidCallback onOpen;

  const _GameImageCard({
    required this.id,
    required this.imagePath,
    required this.size,
    required this.onOpen,
  });

  void _toggleUnlike() {
    final box = Hive.box('likesBox');
    // because we only store liked games with true value
    if (box.containsKey(id)) {
      box.delete(id); // set false
    }
  }
Future<bool?> _showLikeConfirmDialog(BuildContext context, {required bool isCurrentlyLiked}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color.fromRGBO(90, 90, 90, 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text(
        "Are you sure?",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontFamily: "Poppins",
          fontSize: 24,
        ),
        textAlign: TextAlign.center,
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      contentPadding: const EdgeInsets.only(top: 8, left: 16, right: 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              // Confirm action (Like/Unlike) — green like your filter popup
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF93FF83),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                  ),
                  child: Text(
                    isCurrentlyLiked ? "Unlike" : "Like",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color.fromARGB(179, 0, 0, 0),
                      fontWeight: FontWeight.w600,
                      fontFamily: "Poppins",
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Cancel — white
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                  ),
                  child: const Text(
                    "Keep Liked",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromARGB(179, 0, 0, 0),
                      fontWeight: FontWeight.w600,
                      fontFamily: "Poppins",
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // image or placeholder
            if (imagePath != null)
              Image.asset(imagePath!, fit: BoxFit.cover)
            else
              Container(color: const Color(0xFF5A5A5A)),

            
            Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: Container(
                  height: 36,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black38],
                    ),
                  ),
                ),
              ),
            ),

            // unlike button
Positioned(
  right: 6,
  top: 6,
  child: GestureDetector(
    onTap: () async {
      // In LikesPage items are currently liked
      final confirm = await _showLikeConfirmDialog(context, isCurrentlyLiked: true);
      if (confirm == true) {
        _toggleUnlike(); // remove from likes
        // Optional feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from Likes')),
        );
      }
      // if confirm == false or null => do nothing (keep liked)
    },
    child: const Icon(Icons.favorite, color: Colors.white, size: 18),
    // یا SVG قلب خودت:
    // child: SvgPicture.asset('assets/Heart 1.svg', width: 18, height: 18,
    //   colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
  ),
),


          ],
        ),
      ),
    );
  }
}

// ------------------ search sheet ------------------

class LikedSearchSheet extends StatefulWidget {
  final List<Map<String, dynamic>> likedGames;
  final void Function(Map<String, dynamic> game) onOpenGame;

  const LikedSearchSheet({
    super.key,
    required this.likedGames,
    required this.onOpenGame,
  });

  @override
  State<LikedSearchSheet> createState() => _LikedSearchSheetState();
}

class _LikedSearchSheetState extends State<LikedSearchSheet> {
  final TextEditingController _controller = TextEditingController();

  // نتایج پیشنهاد‌شده
  List<Map<String, dynamic>> _suggestions = [];
  bool _hasQuery = false;

  // دی‌بونسر ساده با Timer
  Timer? _debounce; // import 'dart:async';

  // تنظیمات
  static const _debounceMs = 250;
  static const _maxSuggestions = 10;
  static const _minQueryLen = 1; // از اولین کاراکتر شروع کند

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    // دی‌بونس ورودی کاربر
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), _runFilter);
  }

  void _runFilter() {
    final qRaw = _controller.text;
    final q = qRaw.trim().toLowerCase();

    if (q.length < _minQueryLen) {
      setState(() {
        _hasQuery = false;
        _suggestions = []; // وقتی خالی‌ست چیزی نشان نده
      });
      return;
    }

    // امتیازدهی ساده: startsWith > contains > (اختیاری: فازی)
    int scoreOf(String name) {
      if (name.startsWith(q)) return 0;   // بهترین
      if (name.contains(q)) return 1;     // خوب
      return 2;                            // ضعیف/فازی
    }

    // فهرست را فیلتر و مرتب کن
    final filtered = <Map<String, dynamic>>[];
    for (final g in widget.likedGames) {
      final name = (g['name'] ?? g['id'] ?? '').toString().toLowerCase();
      if (name.contains(q)) filtered.add(g);
      // اگر فازی می‌خواهی، می‌توانی اینجا هم اضافه کنی (مثلاً اگر فاصله Levenshtein <= 2 بود).
    }

    filtered.sort((a, b) {
      final na = (a['name'] ?? a['id'] ?? '').toString().toLowerCase();
      final nb = (b['name'] ?? b['id'] ?? '').toString().toLowerCase();
      final sa = scoreOf(na);
      final sb = scoreOf(nb);
      if (sa != sb) return sa.compareTo(sb);
      // تای‌بریک: طول کمتر نزدیک‌تر است
      return na.length.compareTo(nb.length);
    });

    setState(() {
      _hasQuery = true;
      _suggestions = filtered.take(_maxSuggestions).toList();
    });
  }

  void _submit(String _) {
    if (_suggestions.length == 1) {
      widget.onOpenGame(_suggestions.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(49, 49, 49, 1),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 5,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(height: 16),

              // نوار جستجو
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 71,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(35)),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      SvgPicture.asset('assets/search.svg', width: 24, height: 24,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          onSubmitted: _submit,
                          style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 16),
                          decoration: const InputDecoration(
                            isDense: true, border: InputBorder.none,
                            hintText: 'Search liked games...',
                            hintStyle: TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontSize: 16),
                          ),
                        ),
                      ),
                      if (_hasQuery)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            _controller.clear();
                            FocusScope.of(context).unfocus();
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // فقط وقتی کاربر تایپ کرده نمایش بده
              if (!_hasQuery)
                const SizedBox.shrink()
              else
                Expanded(
                  child: _suggestions.isEmpty
                      ? const Center(child: Text('No results', style: TextStyle(color: Colors.white70)))
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 16),
                          itemBuilder: (context, i) {
                            final game = _suggestions[i];
                            return _SearchRow(
                              title: (game['name'] ?? game['id']).toString(),
                              onTap: () => widget.onOpenGame(game),
                              query: _controller.text,
                            );
                          },
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ردیف مینیمال شبیه پیشنهادهای اینستاگرام (فقط متن)
class _SearchRow extends StatelessWidget {
  final String title;
  final String query;
  final VoidCallback onTap;

  const _SearchRow({required this.title, required this.onTap, required this.query});

  @override
  Widget build(BuildContext context) {
    final t = title;
    // برجسته‌سازی ساده بخش منطبق (اختیاری)
    final lower = t.toLowerCase();
    final q = query.trim().toLowerCase();
    final idx = lower.indexOf(q);
    TextSpan span;
    if (idx >= 0 && q.isNotEmpty) {
      span = TextSpan(
        children: [
          TextSpan(text: t.substring(0, idx)),
          TextSpan(text: t.substring(idx, idx + q.length),
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          TextSpan(text: t.substring(idx + q.length)),
        ],
        style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Poppins'),
      );
    } else {
      span = TextSpan(text: t,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Poppins'));
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: RichText(text: span, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
