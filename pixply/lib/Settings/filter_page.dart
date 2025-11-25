import 'package:flutter/material.dart';
import 'package:pixply/Settings/filter_store.dart';
import 'package:provider/provider.dart';

const Color kBg = Color(0xFF0E0E0E);
const Color kChip = Color(0xFF2B2B2B);
const Color kChipText = Color(0xFFBFBFBF);
const Color kDisabled = Color.fromRGBO(90, 90, 90, 1);
const Color kApplyGreen = Color(0xFF7CFF7A); // tweak to match brand
const Color kCancelRed = Color.fromRGBO(255, 141, 131, 1);

class FilterPage extends StatelessWidget {
  const FilterPage({super.key, required this.allGames,});

  final List<Map<String, dynamic>> allGames;

  // -------- Canon helpers (بدون تغییر UI؛ فقط ارسال مقدار درست به Store) --------
  String _canonCategoryFromUi(String ui) {
    final s = ui.trim();
    if (s.toLowerCase() == 'asymmetrical') return 'Asymmetric';
    if (s.toLowerCase() == 'luck/chance' || s.toLowerCase() == 'luck & chance') return 'Luck/Chance';
    if (s.replaceAll(' ', '').toLowerCase() == 'deduction/mindgames' ||
        s.toLowerCase() == 'deduction & mind games') {
      return 'Deduction/MindGames';
    }
    if (s.toLowerCase() == 'capture') return 'Capturing';
    return s;
  }

  String _canonCountryFromUi(String ui) {
    final s = ui.trim();
    if (s.toLowerCase() == 'usa') return 'United States';
    if (s.toLowerCase() == 'uk') return 'United Kingdom';
    if (s.toLowerCase() == 'persia') return 'Iran';
    return s;
  }
Future<void> _applyAndClose(BuildContext context) async {
  final nav = Navigator.of(context);
  if (nav.canPop()) {
    nav.pop(true); 
  }
}



  @override
  Widget build(BuildContext context) {
    final filter = Provider.of<FilterStore>(context);
    final bool hasActive = filter.hasActiveFilters;
    final int matchCount = hasActive ? filter.applyTo(allGames).length : 0;
    final String applyLabel = hasActive ? "Apply ($matchCount)" : "Apply";

    final List<Map<String, String>> categoryDescriptions = [
      {'name': 'Strategy', 'description': 'Games requiring long-term planning and skill.'},
      {'name': 'Tactical', 'description': 'Games focused on short-term decisions and moves.'},
      {'name': 'Abstract', 'description': 'Purely mechanics-based, often with no story or theme.'},
      {'name': 'Race', 'description': 'First-to-finish movement-based games.'},
      {'name': 'Luck/Chance', 'description': 'Games where dice, cards, or randomness play a role.'},
      {'name': 'Asymmetrical', 'description': 'Games where players have different roles or powers.'},
      {'name': 'Area Control', 'description': 'Dominate or control parts of the board.'},
      {'name': 'Deduction/MindGames', 'description': '(Optional) Games with bluffing, hidden info, or logic puzzles.'},
      // اگر «Capturing» هم در دیتاست دارید و می‌خواهی در لیست باشد، این خط را آزاد کن:
      // {'name': 'Capturing', 'description': 'Games involving capturing or removing opponent pieces.'},
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filters",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        children: [
                          // ElevatedButton(
                          //   onPressed: hasActive
                          //       ? () {
                          //           // اگر در FilterStore متد clearFilters ندارید، clearAll را جایگزین کنید.
                          //           filter.clearAll();
                          //         }
                          //       : null,
                          //   style: ButtonStyle(
                          //     backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                          //       if (states.contains(WidgetState.disabled)) return kDisabled;
                          //       return kCancelRed;
                          //     }),
                          //     shape: WidgetStatePropertyAll(
                          //       RoundedRectangleBorder(borderRadius: BorderRadius.circular(35.5)),
                          //     ),
                          //     padding: const WidgetStatePropertyAll(
                          //       EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          //     ),
                          //     elevation: const WidgetStatePropertyAll(0),
                          //   ),
                          //   child: const Text(
                          //     "Cancel",
                          //     style: TextStyle(
                          //       color: Color.fromARGB(255, 255, 255, 255),
                          //       fontFamily: 'Poppins',
                          //       fontSize: 24,
                          //       fontWeight: FontWeight.w600,
                          //     ),
                          //   ),
                          // ),
                          // const SizedBox(width: 10),
                          Container(
                            width: 71,
                            height: 71,
                            decoration: const BoxDecoration(
                              color: Color(0xFF3A3A3A),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 35),
                              onPressed: () async {
                                if (!hasActive) {
                                  if (context.mounted) Navigator.of(context).pop();
                                  return;
                                }
                                final bool? confirm = await showDialog<bool>(
                                  context: context,
                                  barrierDismissible: false,
                                  useRootNavigator: false,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color.fromRGBO(90, 90, 90, 1),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                    title: const Text(
                                      "Keep filters ?",
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
                                                child: const Text(
                                                  "Yes,go",
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
                                            const SizedBox(width: 12),
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
                                                  "No,reset",
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

                                if (confirm == true) {
                                  _applyAndClose(context);
                                } else if (confirm == false) {
                                  filter.clearAll();
                                  if (context.mounted) Navigator.of(context).pop();

                                }
                              },
                            ),
                          ),
                        ],
                      )
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Difficulty
                  buildSectionTitle("Game Difficulty"),
                  Wrap(
                    spacing: 10,
                    children: ["Professional", "Hard", "Medium", "Easy"].map((level) {
                          final bool multiActive = filter.selectedDifficulties.isNotEmpty;
    final bool selected = multiActive
        ? filter.selectedDifficulties.contains(level)
        : (filter.selectedDifficulty == level);
                      return ChoiceChip(
                        label: Text(level),
                        selected: selected,
                        onSelected: (_) {
        if (multiActive) {
        
          filter.toggleDifficulty(level);
        } else {
          filter.toggleDifficulty(level);
        }
                        },
                        selectedColor: const Color(0xFF93FF83),
                        backgroundColor: Colors.grey[800],
                        labelStyle: TextStyle(color: selected ? Colors.black : Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(52.5),
                          side: const BorderSide(color: Colors.transparent, width: 0),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 30),

                  // Mind Effect (Strategy اینجا روی Category اعمال می‌شود تا با دیتاست سازگار باشد)
                  buildSectionTitle("Mind Effect"),
                  Wrap(
                    spacing: 10,
                    children: ["Creativity", "Math", "Memory", "Social", "Logic", "Strategy", "Risk", "Focus"].map((level) {
                      final isStrategy = level == "Strategy";
                      final selected = isStrategy
                          ? filter.selectedCategories.contains("Strategy")
                          : filter.selectedMindEffects.contains(level);
                      return ChoiceChip(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(52.5),
                          side: const BorderSide(color: Colors.transparent, width: 0),
                        ),
                        label: Text(level),
                        selected: selected,
                        onSelected: (_) {
                          if (isStrategy) {
                            // نگاشت Strategy در MindEffect → Category('Strategy')
                            final mapped = _canonCategoryFromUi("Strategy");
                            filter.toggleCategory(mapped);
                          } else {
                            filter.toggleMindEffect(level);
                          }
                        },
                        selectedColor: const Color(0xFF93FF83),
                        backgroundColor: Colors.grey[800],
                        labelStyle: TextStyle(color: selected ? Colors.black : Colors.white),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 30),

                  // Players
                  buildSectionTitle("Number of players"),
                  Wrap(
                    spacing: 10,
                    children: [1, 2, 3, 4].map((number) {
                      final selected = filter.selectedPlayerCount == number;
                      return ChoiceChip(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(52.5),
                          side: const BorderSide(color: Colors.transparent, width: 0),
                        ),
                        label: Text(number.toString()),
                        selected: selected,
                        onSelected: (_) {
                          if (selected) {
                            filter.setPlayerCount(null);
                          } else {
                            filter.setPlayerCount(number);
                          }
                        },
                        selectedColor: const Color(0xFF93FF83),
                        backgroundColor: Colors.grey[800],
                        labelStyle: TextStyle(color: selected ? Colors.black : Colors.white),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 30),

                  // Age range (همون UI خودت)
                  // buildSectionTitle("Player Age Range"),
                  // const SizedBox(height: 10),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     const Text("From", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400, fontFamily: "Poppins")),
                  //     const SizedBox(width: 10),
                  //     Expanded(
                  //       child: TextField(
                  //         keyboardType: TextInputType.number,
                  //         style: const TextStyle(color: Colors.white, fontFamily: "Poppins", fontSize: 14, fontWeight: FontWeight.w400),
                  //         decoration: InputDecoration(
                  //           hintText: 'Age...',
                  //           hintStyle: const TextStyle(color: Colors.white54),
                  //           filled: true,
                  //           fillColor: Colors.grey[850],
                  //           border: OutlineInputBorder(
                  //             borderRadius: BorderRadius.circular(52.5),
                  //             borderSide: BorderSide.none,
                  //           ),
                  //           contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  //         ),
                  //         onChanged: (val) {
                  //           final parsed = int.tryParse(val);
                  //           filter.setAgeRange(parsed, filter.maxAge);
                  //         },
                  //       ),
                  //     ),
                  //     const SizedBox(width: 10),
                  //     const Text("To", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400, fontFamily: "Poppins")),
                  //     const SizedBox(width: 10),
                  //     Expanded(
                  //       child: TextField(
                  //         keyboardType: TextInputType.number,
                  //         style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400, fontFamily: "Poppins"),
                  //         decoration: InputDecoration(
                  //           hintText: 'Age...',
                  //           hintStyle: const TextStyle(color: Colors.white54),
                  //           filled: true,
                  //           fillColor: Colors.grey[850],
                  //           border: OutlineInputBorder(
                  //             borderRadius: BorderRadius.circular(52.5),
                  //             borderSide: BorderSide.none,
                  //           ),
                  //           contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  //         ),
                  //         onChanged: (val) {
                  //           final parsed = int.tryParse(val);
                  //           filter.setAgeRange(filter.minAge, parsed);
                  //         },
                  //       ),
                  //     ),
                  //   ],
                  // ),

                  // const SizedBox(height: 30),

                  // Play time (Range همانطور که داشتی)
                  buildSectionTitle("Play time"),
                  Wrap(
                    spacing: 10,
                    children: [
                      {"label": "Under 15 min", "min": 0, "max": 15},
                      {"label": "15 –30 min", "min": 15, "max": 30}, // UI حفظ شده؛ Store با Range کار می‌کند
                      {"label": "30 –60 min", "min": 30, "max": 60},
                      {"label": "60+ min", "min": 61, "max": 999},
                    ].map((item) {
                      final selected = filter.minPlayTime == item["min"] && filter.maxPlayTime == item["max"];
                      return ChoiceChip(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(52.5),
                          side: const BorderSide(
                            color: Colors.transparent,
                            width: 0,
                          ),
                        ),
                        label: Text(item["label"] as String),
                        selected: selected,
                        onSelected: (_) {
                          if (selected) {
                            filter.setPlayTimeRange(null, null);
                          } else {
                            filter.setPlayTimeRange(item["min"] as int, item["max"] as int);
                          }
                        },
                        selectedColor: const Color(0xFF93FF83),
                        backgroundColor: Colors.grey[800],
                        labelStyle: TextStyle(color: selected ? Colors.black : Colors.white),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 30),

                  // Game Category با توضیحات؛ نام UI به مقدار Store نگاشت می‌شود
                  buildSectionTitle("Game Category"),
                  ...categoryDescriptions.map((category) {
                    final uiName = category['name']!;
                    final storeName = _canonCategoryFromUi(uiName);
                    final selected = filter.selectedCategories.contains(storeName);
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF93FF83) : Colors.grey[850],
                        borderRadius: BorderRadius.circular(52.5),
                      ),
                      child: ListTile(
                        title: Text.rich(
                          TextSpan(
                            text: uiName,
                            style: TextStyle(
                              color: selected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: " – ${category['description']}",
                                style: TextStyle(
                                  color: selected ? Colors.black.withValues(alpha: 0.6) : Colors.white60,
                                  fontWeight: FontWeight.normal,
                                ),
                              )
                            ],
                          ),
                        ),
                        onTap: () => filter.toggleCategory(storeName),
                      ),
                    );
                  }),

                  const SizedBox(height: 30),

                  // Region (Country) — نگاشت به کشور استاندارد جهت سازگاری با دیتاست
                  buildSectionTitle("Game Region"),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      "Brazil", "Persia", "India", "Nepal", "United States", "Africa", "Germany", "China",
                      "Japan", "France", "Mexico", "UK", "Turkey", "Greece", "Thailand", "Indonesia",
                      "Korea", "Egypt", "Spain", "Europe", "Ghana", "Mesopotamia", "Scandinavia",
                      "Madagascar", "Morocco", "New Zealand", "Guatemala", "Hawaii", "Mesoamerica",
                      "Rome", "South Africa", "Philippines", "Ireland", "England", "Malaysia" , "Finland",
                    ].map((region) {
                      final storeRegion = _canonCountryFromUi(region);
                      final selected = filter.selectedRegion == storeRegion;
                      return ChoiceChip(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(52.5),
                          side: const BorderSide(
                            color: Colors.transparent,
                            width: 0,
                          ),
                        ),
                        label: Text(region),
                        selected: selected,
                        onSelected: (_) {
                          if (selected) {
                            filter.setCountry(null);
                          } else {
                            filter.setCountry(storeRegion);
                          }
                        },
                        selectedColor: const Color(0xFF93FF83),
                        backgroundColor: Colors.grey[800],
                        labelStyle: TextStyle(color: selected ? Colors.black : Colors.white),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),

            // Bottom Apply
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 82,
                  child: ElevatedButton(
                    onPressed: hasActive ? () => _applyAndClose(context) : null,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.disabled)) return kDisabled;
                        return const Color(0xFF93FF83);
                      }),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(41)),
                      ),
                      elevation: const WidgetStatePropertyAll(0),
                    ),
                   child: Text(
                  applyLabel,
                style: const TextStyle(
             color: Colors.black,
             fontFamily: 'Poppins',
            fontSize: 24,
           fontWeight: FontWeight.w600,
  ),
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

  Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
    );
  }
}
