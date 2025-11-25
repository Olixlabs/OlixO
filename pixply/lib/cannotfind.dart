import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';


class _DottedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  _DottedLinePainter({
    this.color = const Color(0xFF8B8B8B), 
    this.strokeWidth = 1.0, 
    this.dashWidth = 4.0,
    this.dashGap = 3.0,
  });
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;
    double startX = 0;
    final y = size.height / 2;
    
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class Cannotfind extends StatelessWidget {
  const Cannotfind({super.key});

  static const double _edge = 20; // fixed margins from top/left as requested
  static const String supportEmail = 'support@pixply.io';

  Future<void> _openEmail() async {
    final uri = Uri(scheme: 'mailto', path: supportEmail);
    // Official, cross-platform way to open mailto links.
    // On web it opens the default handler; on desktop/mobile it opens the email app.
    // Ref: url_launcher docs.
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && kIsWeb) {
      // very defensive fallback for rare web handlers
      // ignore: avoid_print
      print('Could not launch email client.');
    }
  }

  @override
  Widget build(BuildContext context) {

    // Middle list (matches screenshot copy)
    const steps = <String>[
      '1- Check power source',
      '2- Ensure board is powered on',
      '3- Grant required permissions (e.g.,Bluetooth)',
      '4- Turn on/off bluetooth',
      '5- Keep device near the board',
      '6- Ensure device is on the same network',
      '7- Disable VPN or custom DNS',
      '8- Restart the board',
      '6- Update the app to the latest version',      
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Scrollable middle + bottom contact area
            Positioned.fill(
              child: Column(
                children: [
                  // Reserve space equal to top margin + back button height
                  const SizedBox(height: _edge + 71),

                  // Middle list
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _edge),
                         child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // build items + separators (same spacing as before)
                                    for (var i = 0; i < steps.length; i++) ...[
                                      Text(
                                        steps[i],
                                        style: const TextStyle(
                                          color: Color.fromRGBO(139, 139, 139, 1),
                                          fontSize: 14,
                                          height: 1.71,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      if (i != steps.length - 1) const SizedBox(height: 8),
                                 ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Dotted divider + contact block at bottom
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _edge),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                  SizedBox(
                          height: 2,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _DottedLinePainter(
                              dashWidth: 4.0,
                              dashGap: 3.0,
                              strokeWidth: 1.0,
                              color: const Color.fromRGBO(139, 139, 139, 1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Or Contact us',
                          style: TextStyle(color: Color.fromRGBO(139, 139, 139, 1), fontSize: 20, fontWeight: FontWeight.w400 , fontFamily: 'Poppins'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        GestureDetector(
                          onTap: _openEmail,
                          child: const Text(
                            supportEmail,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color.fromRGBO(139, 139, 139, 1),
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Back button — circular 71x71, 20px from left/top
            Positioned(
              left: _edge,
              top: _edge,
              child: SizedBox(
                width: 71,
                height: 71,
                child: Material(
                  color: const Color.fromRGBO(51, 51, 51, 1),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Center(
                      child: SvgPicture.asset('assets/back.svg', width: 35, height: 35, colorFilter: const ColorFilter.mode( Colors.white, BlendMode.srcIn), fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Centered title "How to fix" aligned vertically with back button; top offset fixed 20px
            Positioned(
              top: _edge,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: SizedBox(
                  height: 71, // align with back button height
                  child: Center(
                    child: Text(
                      'How to fix',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
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
}

