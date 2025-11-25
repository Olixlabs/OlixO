import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:led_ble_lib/led_ble_lib.dart';
import 'package:pixply/Settings/settinggeneral.dart';
import 'package:pixply/Likes/like.dart';
import 'package:pixply/games.dart';
import 'package:pixply/explore/pixstudio.dart';
import 'package:provider/provider.dart';
import 'package:pixply/Settings/filter_store.dart';
import 'package:pixply/Settings/filter_page.dart';
import 'package:pixply/data/games_catalog.dart';
// import 'package:pixply/explore/tools.dart';

class DiscoverPage extends StatefulWidget {
  final LedBluetooth bluetooth;
  final bool isConnected;

  const DiscoverPage({
    super.key,
    required this.bluetooth,
    required this.isConnected,
  });

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();

  static const Duration animDur = Duration(milliseconds: 250);
  static const double iconGap = 12;

  // void _showComingSoon(BuildContext context) {
  //   ScaffoldMessenger.of(context).hideCurrentSnackBar();
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Coming soon'), duration: Duration(seconds: 2)),
  //   );
  // }

  int _parseMin(String category) {
    if (category == 'Under 15 min') return 0;
    if (category == '15–30 min' || category == '15 –30 min') return 15;
    if (category == '30–60 min' || category == '30 –60 min') return 30;
    if (category == '60+ min') return 61;
    return 0;
  }

  int _parseMax(String category) {
    if (category == 'Under 15 min') return 14;
    if (category == '15–30 min' || category == '15 –30 min') return 30;
    if (category == '30–60 min' || category == '30 –60 min') return 60;
    if (category == '60+ min') return 999;
    return 999;
  }

  List<Map<String, dynamic>> filterList(BuildContext context, List<Map<String, dynamic>> items) {
    final filterStore = Provider.of<FilterStore>(context, listen: false);
    if (items.isEmpty) return items;

    return items.where((game) {
      try {
        final matchDifficulty = filterStore.selectedDifficulty == null ||
            game['difficulty'] == filterStore.selectedDifficulty;

        final matchPlayers = filterStore.selectedPlayerCount == null ||
            (() {
              final playersStr = (game['players'] ?? '') as String;
              if (playersStr.contains('-')) {
                final parts = playersStr.split('-').map((e) => int.tryParse(e)).toList();
                if (parts.length == 2 && parts[0] != null && parts[1] != null) {
                  return filterStore.selectedPlayerCount! >= parts[0]! &&
                      filterStore.selectedPlayerCount! <= parts[1]!;
                }
              }
              final single = int.tryParse(playersStr);
              return single == filterStore.selectedPlayerCount;
            })();

        final matchAge = (filterStore.minAge == null ||
                (game['ageRange'] != null && (game['ageRange']['max'] ?? 999) >= filterStore.minAge!)) &&
            (filterStore.maxAge == null ||
                (game['ageRange'] != null && (game['ageRange']['min'] ?? 0) <= filterStore.maxAge!));

        final matchTime = (filterStore.minPlayTime == null ||
                _parseMin(game['playTimeCategory'] ?? '') >= filterStore.minPlayTime!) &&
            (filterStore.maxPlayTime == null ||
                _parseMax(game['playTimeCategory'] ?? '') <= filterStore.maxPlayTime!);

        final matchCategory = filterStore.selectedCategories.isEmpty ||
            filterStore.selectedCategories.any((selectedCat) {
              final normalizedSelected =
                  selectedCat.toLowerCase().replaceAll('&', '/').replaceAll(' ', '');
              return (game['category'] as List<dynamic>).any((gameCat) {
                final normalizedGameCat =
                    (gameCat ?? '').toString().toLowerCase().replaceAll('&', '/').replaceAll(' ', '');
                return normalizedGameCat == normalizedSelected;
              });
            });

        final matchRegion = filterStore.selectedRegion == null ||
            game['country'] == filterStore.selectedRegion;

        return matchDifficulty &&
            matchPlayers &&
            matchAge &&
            matchTime &&
            matchCategory &&
            matchRegion;
      } catch (e) {
        return true;
      }
    }).toList();
  }

  void _searchAndOpen(String query) {
    if (query.trim().isEmpty) return;

    final q = query.toLowerCase();

    final allItems = <Map<String, dynamic>>[];
    allItems.addAll(GamesCatalog.newest(context, widget.bluetooth, widget.isConnected, limit: 50));
    allItems.addAll(GamesCatalog.mostPlayed(context, widget.bluetooth, widget.isConnected, limit: 50));

    for (final game in allItems) {
      final name = (game['name'] ?? '').toString().toLowerCase();
      String pageTitle = '';
      try {
        final page = game['page'];
        if (page != null) {
          final dynamic p = page;
          pageTitle = (p.gameTitle ?? '').toString().toLowerCase();
        }
      } catch (_) {
        pageTitle = '';
      }

      if (name.contains(q) || (pageTitle.isNotEmpty && pageTitle.contains(q))) {
        final Widget? page = game['page'] as Widget?;
        if (page != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        }
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No game found for "$query"')),
    );
  }

  void searchGame(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      isSearching = q.isNotEmpty;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Prepare Your Games list with fallback to random
    final allGames = GamesCatalog.all(context, widget.bluetooth, widget.isConnected);
    final recentGames = GamesCatalog.newest(context, widget.bluetooth, widget.isConnected, limit: 10);
    List<Map<String, dynamic>> yourGames = recentGames.isNotEmpty
        ? recentGames
        : (allGames.toList()..shuffle()).take(10).toList();

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Image.asset(
              'assets/bgexplore.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: Stack(
            children: [
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Header: Title + Search & Filter
                    Row(
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
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: TextField(
                                      textAlignVertical: TextAlignVertical.center,
                                      controller: searchController,
                                      autofocus: true,
                                      cursorColor: const Color.fromARGB(255, 255, 255, 255),
                                      style: const TextStyle(color: Colors.white),
                                      onChanged: searchGame,
                                      onSubmitted: _searchAndOpen,
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.zero,
                                        hintText: 'Search games...',
                                        hintStyle: const TextStyle(color: Colors.white54),
                                        border: InputBorder.none,
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white),
                                          onPressed: () {
                                            setState(() {
                                              isSearching = false;
                                              searchController.clear();
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Explore',
                                    style: TextStyle(
                                      fontSize: 45,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
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
                                width: 71,
                                height: 71,
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
                                    colorFilter:
                                        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isSearching = true;
                                    });
                                  },
                                ),
                              ),
                            if (!isSearching) const SizedBox(width: iconGap),
                            Stack(
                          clipBehavior: Clip.none,
                            children: [
                            Container(
                              width: 71,
                              height: 71,
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
                                  colorFilter:
                                      const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                ),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => FilterPage(allGames: allGames)),
                                  );
                                  setState(() {});
                                },
                              ),
                            ),
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
                    const SizedBox(height: 40),

                    // === Apps Section ===
                    _buildAppsSection(context),
                    // const SizedBox(height: 20),
                    const SizedBox(height: 40),

                    // Your Games section
                    _ExploreGamesSection(
                      title: 'Your Games',
                      items: filterList(context, yourGames),
                    ),
                    const SizedBox(height: 40),

                    // Featured Games
                    _ExploreGamesSection(
                      title: 'Featured Games',
                      items: filterList(
                        context,
                        GamesCatalog.mostPlayed(context, widget.bluetooth, widget.isConnected, limit: 10),
                      ),
                    ),
                  ],
                ),
              ),
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
      ],
    );
  }

  Widget _buildNavItem(String asset, int index) {
    final bool isSelected = (index == 0);
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
        } else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GamesScreen(
                bluetooth: widget.bluetooth,
                isConnected: widget.bluetooth.isConnected,
              ),
            ),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LikesPage(
                bluetooth: widget.bluetooth,
                isConnected: widget.bluetooth.isConnected,
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

  Widget _buildAppsSection(BuildContext context) {
    // Previous layout (Apps header, See More, Digital Dice, Score Board)
    // is kept here as a comment so it can be restored if needed.
    //
    // return Container(
    //   height: 178,
    //   decoration: BoxDecoration(
    //     color: Colors.white.withValues(alpha: 0.4),
    //     borderRadius: BorderRadius.circular(24),
    //   ),
    //   child: Padding(
    //     padding: const EdgeInsets.all(10),
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Row(
    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //           children: [
    //             const Text(
    //               'Apps',
    //               style: TextStyle(
    //                 fontSize: 20,
    //                 fontWeight: FontWeight.w600,
    //                 color: Colors.white,
    //                 fontFamily: 'Poppins',
    //               ),
    //             ),
    //             TextButton(
    //               onPressed: () {
    //                 Navigator.push(
    //                   context,
    //                   MaterialPageRoute(
    //                     builder: (_) => AllAppsPage(
    //                       bluetooth: widget.bluetooth,
    //                       isConnected: widget.isConnected,
    //                     ),
    //                   ),
    //                 );
    //               },
    //               child: const Text(
    //                 'See More',
    //                 style: TextStyle(
    //                   color: Colors.white,
    //                   fontSize: 14,
    //                   fontWeight: FontWeight.w600,
    //                   fontFamily: 'Poppins',
    //                 ),
    //               ),
    //             ),
    //           ],
    //         ),
    //         const SizedBox(height: 8),
    //         Expanded(
    //           child: Row(
    //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //             children: [
    //               _AppShortcut(
    //                 label: 'PixStudio',
    //                 size: 71,
    //                 imageProvider: const AssetImage('assets/pixstudio.png'),
    //                 onTap: () {
    //                   Navigator.push(
    //                     context,
    //                     MaterialPageRoute(
    //                       builder: (context) => Pixstudio(
    //                         bluetooth: widget.bluetooth,
    //                         isConnected: widget.isConnected,
    //                       ),
    //                     ),
    //                   );
    //                 },
    //                 isFadedLabel: false,
    //               ),
    //               _AppShortcut(
    //                 label: 'Digital Dice',
    //                 size: 71,
    //                 imageProvider: const AssetImage('assets/digital_dice.png'),
    //                 onTap: () => _showComingSoon(context),
    //                 isFadedLabel: true,
    //               ),
    //               _AppShortcut(
    //                 label: 'Score Board',
    //                 size: 71,
    //                 imageProvider: const AssetImage('assets/scoreboard.png'),
    //                 onTap: () => _showComingSoon(context),
    //                 isFadedLabel: true,
    //               ),
    //             ],
    //           ),
    //         ),
    //       ],
    //     ),
    //   ),
    // );

    // New PIXSTUDIO card with background image.
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Pixstudio(
              bluetooth: widget.bluetooth,
              isConnected: widget.isConnected,
            ),
          ),
        );
      },
      child: Container(
        height: 178,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: const DecorationImage(
            image: AssetImage('assets/Pixstudiobg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Align(
            alignment: Alignment.topRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text(
                  'PIXSTUDIO',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Make your dream game',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppShortcut extends StatelessWidget {
  final String label;
  final double size;
  final ImageProvider imageProvider;
  final VoidCallback onTap;
  final bool isFadedLabel;

  const _AppShortcut({
    required this.label,
    required this.size,
    required this.imageProvider,
    required this.onTap,
    this.isFadedLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image(image: imageProvider, fit: BoxFit.cover, filterQuality: FilterQuality.high),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isFadedLabel ? Colors.white.withValues(alpha: 0.3) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _ExploreGamesSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;

  const _ExploreGamesSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 193,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            primary: false,
            itemCount: items.length,
            itemBuilder: (context, i) => _GameMiniCard(game: items[i]),
          ),
        ),
      ],
    );
  }
}

class _GameMiniCard extends StatelessWidget {
  final Map<String, dynamic> game;
  const _GameMiniCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final String image = game['image'] ?? '';
    final Widget? page = game['page'] as Widget?;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          if (page != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => page));
          }
        },
        child: Container(
          width: 154,
          height: 193,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: image.isNotEmpty
              ? Image.asset(
                  image,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
