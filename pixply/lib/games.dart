import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:led_ble_lib/led_ble_lib.dart';
import 'package:provider/provider.dart';
import 'package:pixply/Settings/filter_store.dart';
import 'package:pixply/Settings/filter_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pixply/Likes/like_service.dart';
import 'package:pixply/explore/explore.dart';
import 'package:pixply/Settings/settinggeneral.dart';
import 'package:pixply/Likes/like.dart';
import 'package:pixply/game_list.dart';
import 'package:flutter/services.dart';
// Function to sync likes to the server
Future<void> syncLikesToServer() async {
  final results =
      await Connectivity().checkConnectivity(); // List<ConnectivityResult>
  if (results.contains(ConnectivityResult.none)) return; // offline

  final likesBox = Hive.box('likesBox');
  final unsynced = likesBox.toMap().entries.where(
        (entry) => entry.value is Map && entry.value['synced'] == false,
      );

  final payload = unsynced
      .map((entry) => {
            'gameId': entry.key,
            'liked': entry.value['liked'],
          })
      .toList();

  if (payload.isEmpty) return;

  try {
    final response = await http.post(
      Uri.parse('http://192.168.164.101:5000/api/syncLikes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'likes': payload}),
    );

    if (response.statusCode == 200) {
      final updatedCounts = jsonDecode(response.body)['updatedCounts'];
      for (var gameId in updatedCounts.keys) {
        final old = likesBox.get(gameId);
        if (old != null) {
          likesBox.put(gameId, {
            'liked': old['liked'],
            'synced': true,
            'realCount': updatedCounts[gameId],
          });
        }
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Sync failed: $e');
    }
  }
}


class GamesScreen extends StatefulWidget {
  final LedBluetooth bluetooth;
  final bool isConnected;

  const GamesScreen(
      {super.key, required this.bluetooth, required this.isConnected});

  @override
  // ignore: library_private_types_in_public_api
  _GamesScreenState createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  int selectedIndex = 1;
  late PageController _pageController; // گوشی
  PageController? _tabletController;   // تبلت/دسکتاپ
  double _tabletViewportFraction = 1.0;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> allGames = [];
  List<Map<String, dynamic>> filteredGames = [];
  List<Map<String, dynamic>> displayGames = [];

  // تشخیص تبلت/دسکتاپ و سایز ثابت کارت
  static const double _cardW = 349.0;
  static const double _cardH = 759.0;
  static const double _gap = 16.0;
  bool get _isTabletUp => MediaQuery.of(context).size.width >= 600;

  Map<String, ValueNotifier<int>> gameNotifiers = {};

  // ---- New: Back-guard during drag & last-page trackers ----
  bool _isUserDragging = false;
  int _lastPagePhone = 1;
  int _lastPageTablet = 1;
  // double _previousPage = 0.0;


  @override
  void initState() {
    super.initState();
    syncLikesToServer();

    _pageController = PageController(
      viewportFraction: 0.8,
      initialPage: selectedIndex,
    );
   


    allGames = buildGameList(widget.bluetooth, widget.isConnected);
    filteredGames = List.from(allGames);
    displayGames = List.from(allGames);
    applyFilters();

    _lastPagePhone = selectedIndex;
    _lastPageTablet = selectedIndex;
    // _previousPage = selectedIndex.toDouble();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  void _ensureTabletController(BoxConstraints viewport) {
    final W = viewport.maxWidth;
    // صفحه‌ی هر آیتم = عرض کارت + فاصله‌ی بین کارت‌ها
    double vf = ((_cardW + _gap) / W).clamp(0.2, 1.0);
    if (_tabletController == null || _tabletViewportFraction != vf) {
      final initial = selectedIndex;
      _tabletViewportFraction = vf;
      _tabletController?.dispose();
      _tabletController = PageController(
        viewportFraction: _tabletViewportFraction,
        initialPage: initial,
      );
       _lastPageTablet = initial;
      //  _previousPage = initial.toDouble();
      // _attachHapticsToController(_tabletController!, tablet: true);
    }
  }
  // ---- New: skip logic based on swipe velocity ----


 // ---- بهبود یافته: skip logic based on swipe velocity ----
// ---- بهبود یافته: skip logic based on swipe velocity ----
int _pagesToSkipByVelocity(double pixelsPerSecondDx) {
  final v = pixelsPerSecondDx.abs();
  
  // تنظیم حساسیت‌های بهتر برای تشخیص سرعت
  if (v < 4500) return 0;           // آرام - بدون پرش
  if (v < 6000) return 1;          // متوسط - 1 پرش
  if (v < 7500) return 2;          // سریع - 2 پرش
  if (v < 9000) return 3;          // بسیار سریع - 3 پرش
  return 4;                         // فوق‌العاده سریع - 4 پرش (حداکثر)
}

bool _handlePhoneScrollEnd(ScrollEndNotification n) {
  if (mounted && _isUserDragging) setState(() => _isUserDragging = false);

  final vel = n.dragDetails?.velocity.pixelsPerSecond.dx ?? 0.0;
  final skips = _pagesToSkipByVelocity(vel);
  if (skips == 0) return false;

  final dir = vel < 0 ? 1 : -1; // چپ=بعدی، راست=قبلی
  final target = (_lastPagePhone + dir * skips).clamp(0, filteredGames.length - 1);
  
  if (target != _lastPagePhone && _pageController.hasClients) {
    _pageController.animateToPage(
      target,
      duration: Duration(milliseconds: 180 + 50 * skips), // سریع‌تر
      curve: Curves.fastOutSlowIn, // منحنی روان‌تر
    );
    _lastPagePhone = target;
    return true;
  }
  return false;
}

bool _handleTabletScrollEnd(ScrollEndNotification n) {
  if (mounted && _isUserDragging) {
    setState(() => _isUserDragging = false);
  }

  final vel = n.dragDetails?.velocity.pixelsPerSecond.dx ?? 0.0;
  final skips = _pagesToSkipByVelocity(vel);
  if (skips == 0) return false;

  final dir = vel < 0 ? 1 : -1;
  final target = (_lastPageTablet + dir * skips).clamp(0, filteredGames.length - 1);
  
  if (target != _lastPageTablet && (_tabletController?.hasClients ?? false)) {
    _tabletController!.animateToPage(
      target,
      duration: Duration(milliseconds: 180 + 50 * skips), // سریع‌تر
      curve: Curves.fastOutSlowIn, // منحنی روان‌تر
    );
    _lastPageTablet = target;
    return true;
  }
  return false;
}
  void _triggerHapticFeedback() {
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (kDebugMode) {
        print('Haptic feedback error: $e');
      }
    }
  }
  void searchGame(String query) {
    setState(() {
      filteredGames = allGames.where((game) {
        final gameTitle = game['page']?.gameTitle ?? '';
        return gameTitle.toLowerCase().contains(query.toLowerCase());
      }).toList();

      if (filteredGames.isNotEmpty) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
        );
        _tabletController?.animateToPage(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabletController?.dispose();
    searchController.dispose();
    super.dispose();
  }

  // Function to apply filters
void applyFilters() {
  final store = Provider.of<FilterStore>(context, listen: false);

  setState(() {
    // 1) فیلتر اصلی دقیقاً با منطق استور (Country هم‌ارزها، OR/AND، PlayTime overlap، Players 2_4 → 2-4، …)
    filteredGames = store.applyTo(allGames);

    // 2) اگر سرچ فعّاله، بعد از فیلتر روی عنوان بازی‌ها اعمال کن
    if (isSearching) {
      final q = (searchController.text).toLowerCase();
      if (q.isNotEmpty) {
        filteredGames = filteredGames.where((game) {
          final title = (game['page']?.gameTitle ?? game['name'] ?? '')
              .toString()
              .toLowerCase();
        return title.contains(q);
        }).toList();
      }
    }

    // 3) اسکرول به اولین نتیجه و sync با هر دو کنترلر (گوشی/تبلت)
    if (filteredGames.isNotEmpty) {
      selectedIndex = 0;
      _lastPagePhone = 0;
       _lastPageTablet = 0;
      //  _previousPage = 0.0;
      if (_pageController.hasClients) {
        Future.microtask(() => _pageController.jumpToPage(0));
      }
      if ((_tabletController?.hasClients ?? false)) {
        Future.microtask(() => _tabletController!.jumpToPage(0));
      }
    } else {
      selectedIndex = 0; // پیش‌فرض امن
     _lastPagePhone = 0;
    _lastPageTablet = 0;
    // _previousPage = 0.0;
    }
  });
}


  void updateDisplayedGames() {
    final searchText = searchController.text.toLowerCase();
    setState(() {
      if (isSearching && searchText.isNotEmpty) {
        displayGames = filteredGames.where((game) {
          return game['name'].toLowerCase().contains(searchText);
        }).toList();
      } else {
        displayGames = filteredGames;
      }
    });
  }

  void onSearchChanged(String value) {
    setState(() {
      isSearching = value.isNotEmpty;
      updateDisplayedGames();
    });
  }

  // ------------------ Tablet/Desktop: PageView افقی با چند کارت ثابت ------------------
  Widget _buildCardsAreaTablet(BoxConstraints viewport) {
    _ensureTabletController(viewport);
return NotificationListener<ScrollNotification>(
  onNotification: (n) {
    if (n is ScrollStartNotification) {
      if (mounted && !_isUserDragging) {
        setState(() => _isUserDragging = true);
      }
    } else if (n is ScrollUpdateNotification) {
      // تشخیص حرکت سریع در حین درگ
     if (n.scrollDelta != null && n.scrollDelta!.abs() > 20 && _isUserDragging) {
        // حرکت سریع تشخیص داده شد
      }
    } else if (n is ScrollEndNotification) {
      _handleTabletScrollEnd(n);
    }
    return false;
  },
      child:PageView.builder(
      controller: _tabletController!,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: filteredGames.length,
      onPageChanged: (index) {
        _triggerHapticFeedback();
        setState(() {
          if (isSearching) {
            final selectedGame = filteredGames[index];
            selectedIndex = allGames.indexOf(selectedGame);
          } else {
            selectedIndex = index;
          }
          _lastPageTablet = index;
          //  _previousPage = index.toDouble();
        });
      },
      itemBuilder: (context, index) {
        final game = filteredGames[index];
        return AnimatedBuilder(
          animation: _tabletController!,
          builder: (context, child) {
            double scale = 1.0;
            if (_tabletController!.hasClients &&
                _tabletController!.position.haveDimensions) {
              final page = _tabletController!.page ?? selectedIndex.toDouble();
              scale = (1 - ((page - index).abs() * 0.2)).clamp(0.9, 1.0);
            }
            return Transform.scale(
              scale: scale,
              child: Padding(
                padding: EdgeInsets.only(right: _gap),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildGameCard(
                    game,
                    fixedMode: true, // کارت با سایز ثابت + محاسبات داخلی ثابت
                    ),
                  ),
                ),
              );
            },
          );
        },
           ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double sideSpacing = 16.0;
    const double iconGap = 16.0;
    const double iconContainerSize = 71.0;
    const Duration animDur = Duration(milliseconds: 250);

    return PopScope(
      canPop: !_isUserDragging,
      onPopInvoked: (didPop) {
         if (_isUserDragging && didPop) {
           
         }
      },
      child: Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: (filteredGames.isEmpty)
                ? const SizedBox.shrink()
                : Builder(builder: (_) {
                    final int safeIndex =
                        selectedIndex.clamp(0, filteredGames.length - 1);
                    final String bgImage = filteredGames[safeIndex]['image'];
                    return Container(
                      key: ValueKey<String>(bgImage),
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(bgImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                      foregroundDecoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                    );
                  }),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),

          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: sideSpacing,
                  right: sideSpacing,
                  top: 40,
                  bottom: 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: animDur,
                        child: isSearching
                            ? Container(
                                height: 71,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(35),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: TextField(
                                  textAlignVertical: TextAlignVertical.center,
                                  controller: searchController,
                                  autofocus: true,
                                  cursorColor:
                                      const Color.fromARGB(255, 255, 255, 255),
                                  style: const TextStyle(color: Colors.white),
                                  onChanged: searchGame,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.zero,
                                    hintText: 'Search...',
                                    hintStyle: const TextStyle(color: Colors.white54),
                                    border: InputBorder.none,
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          searchController.clear();
                                          filteredGames = allGames;
                                          isSearching = false;
                                          _pageController
                                              .jumpToPage(selectedIndex);
                                          _tabletController?.jumpToPage(selectedIndex);
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              )
                            : const Text(
                                "Games",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 45,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isSearching)
                          Container(
                            width: iconContainerSize,
                            height: iconContainerSize,
                            padding: EdgeInsets.zero,
                            decoration: const BoxDecoration(
                              color: Color.fromRGBO(50, 50, 50, 1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: SvgPicture.asset(
                                'assets/search.svg',
                                width: 35,
                                height: 35,
                                colorFilter: const ColorFilter.mode(
                                    Colors.white, BlendMode.srcIn),
                              ),
                              onPressed: () {
                                setState(() {
                                  isSearching = true;
                                });
                              },
                            ),
                          ),
                        if (!isSearching) const SizedBox(width: iconGap),
// به‌جای Container ساده، از Stack استفاده کن:
Stack(
  clipBehavior: Clip.none,
  children: [
    Container(
      width: iconContainerSize,
      height: iconContainerSize,
      padding: EdgeInsets.zero,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(50, 50, 50, 1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: SvgPicture.asset(
          'assets/filter.svg',
          width: 35,
          height: 35,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FilterPage(allGames: allGames), // 👈 تغییر این خط
            ),
          );
          applyFilters();
        },
      ),
    ),

    // نقطه‌ی سبز (indicator)
    Positioned(
      right: 3, // اگر می‌خوای گوشه بیرونی‌تر بشه، -2 یا -3 بذار
      top: 3,
      child: Consumer<FilterStore>(
        builder: (_, store, __) {
          if (!store.hasActiveFilters) return const SizedBox.shrink();
          return Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF93FF83), // سبز برند
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(blurRadius: 4, spreadRadius: 0.5, color: Colors.black54),
              ],
            ),
          );
        },
      ),
    ),
  ],
),

                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ------------------ Phone vs Tablet/Desktop ------------------
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (_isTabletUp) {
                      // تبلت/دسکتاپ: PageView افقی با چند کارت و افکت اسکیل
                      return _buildCardsAreaTablet(constraints);
                    }
                                          // --- Phone ---
return NotificationListener<ScrollNotification>(
  onNotification: (n) {
    if (n is ScrollStartNotification) {
      if (mounted && !_isUserDragging) {
        setState(() => _isUserDragging = true);
      }
    } else if (n is ScrollUpdateNotification) {
      // تشخیص حرکت سریع در حین درگ
     if (n.scrollDelta != null && n.scrollDelta!.abs() > 20 && _isUserDragging) {
        // حرکت سریع تشخیص داده شد
      }
    } else if (n is ScrollEndNotification) {
      _handlePhoneScrollEnd(n);
    }
    return false;
  },
                      child: PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      itemCount: filteredGames.length,
                      onPageChanged: (index) {
                        _triggerHapticFeedback();
                        setState(() {
                          if (isSearching) {
                            final selectedGame = filteredGames[index];
                            selectedIndex = allGames.indexOf(selectedGame);
                          } else {
                            selectedIndex = index;
                          }
                          _lastPagePhone = index;
                          // _previousPage = index.toDouble();
                        });
                      },
                      itemBuilder: (context, index) {
                        final game = filteredGames[index];
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double scale = 1.0;
                            if (_pageController.hasClients &&
                                _pageController.position.haveDimensions) {
                              double pageOffset =
                                  _pageController.page ?? selectedIndex.toDouble();
                              scale = (1 - ((pageOffset - index).abs() * 0.2))
                                  .clamp(0.9, 1.0);
                            }
                            return Transform.scale(
                              scale: scale,
                              child: _buildGameCard(game),
                            );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          

          // menu
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 323,
                height: 82,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(41),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavItem('assets/planet-saturn 1.svg', 0),
                      _buildNavItem('assets/dices.svg', 1),
                      _buildNavItem('assets/Heart 1.svg', 2),
                      _buildNavItem('assets/Setting.svg', 3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  bool? isLiked = false;

  Widget _buildGameCard(
    Map<String, dynamic> game, {
    bool fixedMode = false, // برای تبلت/دسکتاپ true می‌شود
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final double cardW = _cardW; // همیشه 349
    final double cardH = _cardH; // همیشه 759

    // گوشی مثل قبل از screenWidth استفاده می‌کرد؛
    // تبلت/دسکتاپ روی سایز ثابت کارت محاسبه می‌کنیم تا اورفلو نداشته باشه.
    final double basisW = fixedMode ? cardW : screenWidth;
    final double basisH = fixedMode ? cardH : screenHeight;

    final double likeBarW = basisW * 0.45;
    final double countryBarW = basisW * 0.25;

    return GestureDetector(
      child: Container(
        width: cardW,
        height: cardH,
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(72),
            topRight: Radius.circular(72),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // دقیقاً مثل قبل
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ClipRRect(
                child: Image.asset(
                  game['image']!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: basisH * 0.015),
            IconButton(
              icon: SvgPicture.asset(
                'assets/Vector.svg',
                width: 71,
                height: 71,
              ),
              onPressed: () {
                if (mounted && game['page'] != null) {
                  _navigateToGameDetails(game);
                }
              },
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            SizedBox(height: basisH * 0.01),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: likeBarW,
                  height: 39,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(19.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ValueListenableBuilder(
                        valueListenable:
                            Hive.box('likesBox').listenable(keys: [game['id']]),
                        builder: (context, box, _) {
                          final liked = LikeService.isLiked(game['id']);
                          return GestureDetector(
                            onTap: () async {
                              await LikeService.toggleLike(
                                game['id'],
                                name: game['name'],
                                image: game['image'],
                              );
                            },
                            child: Icon(
                              liked ? Icons.favorite : Icons.favorite_border,
                              color: Colors.white,
                              size: 20,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 5),
                      const SizedBox(width: 40),
                      SvgPicture.asset(
                        'assets/Group.svg',
                        width: 18,
                        height: 16.75,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        game['players']!,
                        style: const TextStyle(color: Colors.white , fontSize: 14, fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: countryBarW,
                  height: 39,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(19.5),
                  ),
                  child: Text(
                    game['country']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToGameDetails(Map<String, dynamic> game) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => game['page'],
      ),
    );
  }

  Widget _buildNavItem(String asset, int index) {
    final bool isSelected = (index == 1);
    return GestureDetector(
      onTap: () {
        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SettingsGeneral(
                bluetooth: widget.bluetooth,
                isConnected: widget.bluetooth.isConnected,
              ),
            ),
          );
        }
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiscoverPage(
                bluetooth: widget.bluetooth,
                isConnected: widget.bluetooth.isConnected,
              ),
            ),
          );
        }
        if (index == 2) {
          final all = allGames.isNotEmpty
              ? allGames
              : buildGameList(widget.bluetooth, widget.isConnected);

          final allGamesCopy = List<Map<String, dynamic>>.from(all);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LikesPage(
                bluetooth: widget.bluetooth,
                isConnected: widget.bluetooth.isConnected,
                allGames: allGamesCopy,
              ),
            ),
          );
        }
      },
      child: Container(
        width: 71,
        height: 71,
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white : const Color.fromRGBO(50, 50, 50, 1),
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
