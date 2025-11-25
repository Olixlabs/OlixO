import 'package:flutter/material.dart';
import 'package:led_ble_lib/led_ble_lib.dart';
import 'package:pixply/explore/pixstudio.dart';
import 'package:flutter_svg/flutter_svg.dart';
class AllAppsPage extends StatelessWidget {
  final LedBluetooth bluetooth;
  final bool isConnected;
  // left padding for the circular back button: use a value between 10..20
  static const double leftPadding = 16.0;

  const AllAppsPage({
    super.key,
    required this.bluetooth,
    required this.isConnected,
  });

void _showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Coming soon'), duration: Duration(seconds: 2)),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(49, 49, 49, 1),
      // SafeArea + custom header so we can put the circular back icon 71x71
      body: SafeArea(
        child: Column(
          children: [
            // Header
            SizedBox(
              height: 92, // enough to fit the 71 circle and vertical spacing
              child: Stack(
                children: [
                  // Centered title "Apps"
                  Center(
                    child: Text(
                      'Apps',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),

                  // Left circular back button positioned with left padding
                  Positioned(
                    left: leftPadding,
                    top: 10, // so the 71 circle is vertically centered within the 92 height
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 71,
                        height: 71,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color.fromARGB(255, 0, 0, 0), // similar style as discover header
                        ),
                        child: IconButton(
                          icon: SvgPicture.asset('assets/arrow.svg',
                              width: 36, height: 36),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: Container(
              height: 1, 
              color: Colors.white.withValues(alpha: 0.20),
                ),
          ),
            // Spacer to separate header from body
            const SizedBox(height: 20),

            // Body: show the same app shortcuts (you can expand this to more items)
            // I'll show them in a vertical list with same style cards as in DiscoverPage.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Row with the three main apps (same look as original)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _AppShortcut(
                        label: 'PixStudio',
                        size: 71,
                        imageProvider: const AssetImage('assets/pixstudio.png'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Pixstudio(
                                bluetooth: bluetooth,
                                isConnected: isConnected,
                              ),
                            ),
                          );
                        },
                        isFadedLabel: false,
                      ),
                      _AppShortcut(
                        label: 'Digital Dice',
                        size: 71,
                        imageProvider: const AssetImage('assets/digital_dice.png'),
                        onTap: () => _showComingSoon(context),
                        isFadedLabel: true,
                      ),
                      _AppShortcut(
                        label: 'Score Board',
                        size: 71,
                        imageProvider: const AssetImage('assets/scoreboard.png'),
                        onTap: () => _showComingSoon(context),
                        isFadedLabel: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  // another process
                   ],
              ),
            ),
          ],
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
// class _PlaceholderPage extends StatelessWidget {
//   final String title;
//   const _PlaceholderPage({required this.title});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         title: Text(title),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//       ),
//       body: Center(
//         child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20)),
//       ),
//     );
//   }
// }