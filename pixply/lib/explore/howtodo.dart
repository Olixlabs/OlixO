// // file: brake_condition_page.dart
// import 'package:flutter/material.dart';
// // If your icons are SVG, keep this import:
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
// import 'package:url_launcher/url_launcher.dart';


// class HowToPage extends StatelessWidget {
//   const HowToPage({super.key});

//   // The exact list content provided by the user (11 sections).
// // final List<Map<String, String>> _items = const [
// //   {
// //     "title": "Getting Started",
// //     "subtitle": "Use Create Your Game to start a new project, My Creations to view or delete existing ones, and How To Do to see this guide."
// //   },
// //     {
// //     "title": "Info / Metadata",
// //     "subtitle": "Enter game name, overview, player range, age range, and region — validation ensures data is correct."
// //   },
// //   {
// //     "title": "Pixel Design",
// //     "subtitle": "Choose grid size, draw with brush or erase, zoom & pan, undo/redo, and test on the board if connected."
// //   },
// //   {
// //     "title": "Brush & Tools",
// //     "subtitle": "Adjust brush size, pick colors from palette or HEX, save custom colors, and switch between tools."
// //   },
// //   {
// //     "title": "Draw & Edit",
// //     "subtitle": "Tap or drag to color cells, use eraser to clear, and refine details using zoom for accuracy."
// //   },

// //   {
// //     "title": "Instructions & Media",
// //     "subtitle": "Provide gameplay description (max ~300 chars), optional video URL or file upload for instructions."
// //   },
// //   {
// //     "title": "Saving & Proceeding",
// //     "subtitle": "All design, metadata and instructions are saved locally (e.g. Hive) before navigating to Preview."
// //   },
// //   {
// //     "title": "Preview & Play",
// //     "subtitle": "Review game details, press Play Now to update board playlist, send design, apply color & rotation."
// //   },
// //   {
// //     "title": "My Creations (Archive)",
// //     "subtitle": "View your saved projects, open preview for each, or delete them after confirmation."
// //   },
// //   {
// //     "title": "Troubleshooting & Tips",
// //     "subtitle": "If errors occur — check Bluetooth, validate inputs, fix color/rotation settings, retry play."
// //   },
// // ];


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       // No AppBar as requested
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0), // 20 padding on all sides
//           child: Stack(
//             children: [
//               // Main scrollable content
//               ListView(
//                 // Page is scrollable
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 // ensure list content is not hidden behind the fixed button:
//                 padding: const EdgeInsets.only(bottom: 140),
//                 children: [
//                   // Header: back icon (inside 71x71 circle) + long title + subtitle
//                   Directionality(
//                     // Ensure left-to-right layout for title and subtitle
//                     textDirection: TextDirection.ltr,
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         // Back button inside a 71x71 circle
// // جای Container قبلی:
// Material(
//   color: const Color(0xFF333333),
//   shape: const CircleBorder(),
//   child: InkWell(
//     customBorder: const CircleBorder(),
//     onTap: () async {
//       await Navigator.maybePop(context); // ایمن‌تر از pop
//     },
//     child: SizedBox(
//       width: 71,
//       height: 71,
//       child: Center(
//         child: SvgPicture.asset(
//           "assets/back.svg",
//           width: 35,
//           height: 35,
//           colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
//         ),
//       ),
//     ),
//   ),
// ),

//                         const SizedBox(width: 20), // 20 spacing between icon and title

//                         // Title (long) and subtitle below. Expanded prevents overflow.
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text(
//                                 // Replace this with your actual long title
//                                 'How to Use PixStudio',
//                                 textAlign: TextAlign.left,
//                                 style: TextStyle(
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.w600,
//                                   fontFamily: 'Poppins',
//                                   color: Colors.white,
//                                 ),
//                                 softWrap: true,
//                                 maxLines: null,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   // const SizedBox(height: 20),

//                   // // The rest of the page: a list of items (title + description)
//                   // ListView.separated(
//                   //   shrinkWrap: true,
//                   //   physics: const NeverScrollableScrollPhysics(),
//                   //   itemCount: _items.length,
//                   //   separatorBuilder: (context, i) => const SizedBox(height: 12),
//                   //   itemBuilder: (context, index) {
//                   //     final item = _items[index];
//                   //     return _ListItem(
//                   //       title: item['title'] ?? '',
//                   //       subtitle: item['subtitle'] ?? '',
//                   //     );
//                   //   },
//                   // ),

//                   // Keep consistent bottom spacing (extra safe)
//                   const SizedBox(height: 20),
//                 ],
//               ),

//               // Fixed bottom button (positioned 20 from bottom)
//   //             Positioned(
//   //               left: 0,
//   //               right: 0,
//   //               bottom: 20,
//   //               child: Container(
//   //                 margin: const EdgeInsets.symmetric(horizontal: 20),
//   //                 height: 82,
//   //                 decoration: BoxDecoration(
//   //                   color: const Color.fromRGBO(49, 49, 49, 1),
//   //                   borderRadius: BorderRadius.circular(41),
//   //                 ),
//   //                 child: TextButton(
//   // onPressed: () async {
//   //   Navigator.of(context).pop(true);
//   //   // If you want to ensure the page is popped only if possible:
//   //   // await Navigator.maybePop(context);
//   // },

//   //                   child: const Center(
//   //                     child: Text(
//   //                       'I agree to the Pixstudio Terms & Conditions',
//   //                       style: TextStyle(
//   //                         color: Colors.white,
//   //                         fontSize: 14,
//   //                         fontWeight: FontWeight.w400,
//   //                         fontFamily: 'Poppins',
//   //                       ),
//   //                       textAlign: TextAlign.center,
//   //                     ),
//   //                   ),
//   //                 ),
//   //               ),
//   //             ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // class _ListItem extends StatelessWidget {
// //   final String title;
// //   final String subtitle;
// //   const _ListItem({
// //     Key? key,
// //     required this.title,
// //     required this.subtitle,
// //   }) : super(key: key);

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       padding: const EdgeInsets.all(14),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Text(
// //             title,
// //             textAlign: TextAlign.left,
// //             style: const TextStyle(
// //               fontSize: 20,
// //               fontWeight: FontWeight.w600,
// //               fontFamily: 'Poppins',
// //               color: Colors.white,
// //             ),
// //           ),
// //           const SizedBox(height: 6),
// //           Text(
// //             subtitle,
// //             textAlign: TextAlign.left,
// //             style: const TextStyle(
// //               fontSize: 14,
// //               color: Color.fromARGB(255, 255, 255, 255),
// //               fontFamily: 'Poppins',
// //               fontWeight: FontWeight.w400,
// //               height: 1.4,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// file: brake_condition_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class HowToPage extends StatefulWidget {
  const HowToPage({super.key});

  @override
  State<HowToPage> createState() => _HowToPageState();
}

class _HowToPageState extends State<HowToPage> {
  // Single source of truth for the How-To video URL
  final String _youtubeUrl = 'https://youtu.be/CupIM1JODNA?si=WAXMPxfqoTCeiZwp';
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(_youtubeUrl) ?? 'CupIM1JODNA';
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        controlsVisibleAtStart: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔙 Back Button + Title
              Row(
                children: [
                  Material(
                    color: const Color(0xFF333333),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.maybePop(context),
                      child: SizedBox(
                        width: 71,
                        height: 71,
                        child: Center(
                          child: SvgPicture.asset(
                            "assets/back.svg",
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
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Text(
                      'How to Use PixStudio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),

              // const SizedBox(height: 40),

              // 🎥 Video + Button Centered Vertically Together
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: YoutubePlayer(
                              controller: _controller,
                              showVideoProgressIndicator: true,
                              progressIndicatorColor: Colors.greenAccent,
                              progressColors: const ProgressBarColors(
                                playedColor: Colors.greenAccent,
                                handleColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🌐 Watch on YouTube button (20px below video)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await launchUrl(Uri.parse(_youtubeUrl));
                        },
                        icon: const Icon(Icons.open_in_new, color: Colors.white),
                        label: const Text(
                          'Watch on YouTube',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF333333),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(41),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
