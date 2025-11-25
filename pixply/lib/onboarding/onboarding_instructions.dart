// ===============================
// lib/onboarding/onboarding_instructions.dart (with Lottie animations)
// ===============================
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pixply/connected.dart';
import 'package:led_ble_lib/led_ble_lib.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;

/// Call `Navigator.pushReplacement(context, ...)` to this screen
/// *after* Terms & Conditions are accepted, but only if `onboardingSeen` is false.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  // Preference key and version to control when onboarding shows again
  static const String kPrefsKey = 'onboardingVersion';
  static const int kVersion = 1;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  bool _assetsCached = false;
  static const _kNotifKey = 'pixply_notif_permission_requested';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestNotificationsOnce());
  }

  Future<void> _requestNotificationsOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kNotifKey) == true) return;
      try {
        if (Platform.isIOS) {
          await FirebaseMessaging.instance.requestPermission();
        } else {
          final plugin = FlutterLocalNotificationsPlugin();
          final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          await android?.requestNotificationsPermission();
        }
      } catch (_) {}
      await prefs.setBool(_kNotifKey, true);
    } catch (_) {}
  }

  final _pages = const [
    _OnbPage(
      title: '1. Enrolling Your PixMat',
      body:
          'Connect the Pixply data cable and open the app. Go to the “Enroll” section to detect and register your PixMat board.',
      asset: 'assets/enrollinstruction.png',
      imageFit: BoxFit.contain,
    ),
    _OnbPage(
      title: '2. Connecting Power Bank and Turning On',
      body:
          'Plug your power bank into the PixMat. Wait a few seconds until the LEDs light up — your board is ready.',
      asset: 'assets/powerbankinstruction.svg',
    ),
    _OnbPage(
      title: '3. Enabling Bluetooth and Opening the App',
      body:
          'Turn on Bluetooth on your phone, open the Pixply app, and connect to your board from the Connection page.',
      asset: 'assets/bluetoothinstruction.svg',
      imageFit: BoxFit.contain,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_assetsCached) return;
    _assetsCached = true;
    // Precache assets to make first slide load instantly
    try { precacheImage(const AssetImage('assets/enrollinstruction.png'), context); } catch (_) {}
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingSeen', true); // legacy flag (kept for compatibility)
    await prefs.setInt(OnboardingScreen.kPrefsKey, OnboardingScreen.kVersion);
    if (!mounted) return;
    // Replace with your root page (e.g., Home(), GamesPage(), Welcome(...))
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ConnectedPage(
          bluetooth: LedBluetooth(),
          isConnected: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _pages.length - 1;

    return Scaffold(
      // Subtle dark gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 156, 156, 156)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip', style: TextStyle(color: Color.fromARGB(179, 0, 0, 0) , fontFamily: 'Poppins') ),
                ),
              ),

              // Pager with slight page transition feel
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _pages[i],
                ),
              ),

              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 16),
                    height: 6,
                    width: _index == i ? 26 : 8,
                    decoration: BoxDecoration(
                      color: _index == i ? Colors.white : Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Controls: only show Get Started on the last slide
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: last
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _finish,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Get Started', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w500) ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnbPage extends StatelessWidget {
  final String title;
  final String body;
  final String asset;
  final String? lottieAsset;
  final bool rightHalfOffscreen;
  final double rightShiftFraction;
  final BoxFit imageFit;
  const _OnbPage({
    required this.title,
    required this.body,
    required this.asset,
    this.lottieAsset,
    this.rightHalfOffscreen = false,
    this.rightShiftFraction = 0.5,
    this.imageFit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final EdgeInsets outerPadding = rightHalfOffscreen
        ? const EdgeInsets.fromLTRB(24, 0, 0, 0)
        : const EdgeInsets.fromLTRB(24, 0, 24, 0);
    return Padding(
      padding: outerPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: rightHalfOffscreen
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          // Static image shifted so half is off-screen to the right.
                          IgnorePointer(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FractionalTranslation(
                                translation: Offset(rightShiftFraction, 0),
                                child: SizedBox.expand(
                                  child: _buildAssetWidget(fit: imageFit),
                                ),
                              ),
                            ),
                          ),
                          if (lottieAsset != null)
                            IgnorePointer(
                              child: Lottie.asset(
                                lottieAsset!,
                                repeat: true,
                                frameRate: FrameRate.max,
                                fit: BoxFit.cover,
                              ),
                            ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildAssetWidget(fit: imageFit),
                            if (lottieAsset != null)
                              IgnorePointer(
                                child: Lottie.asset(
                                  lottieAsset!,
                                  repeat: true,
                                  frameRate: FrameRate.max,
                                  fit: BoxFit.cover,
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          // Removed title and description; only images remain.
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  Widget _buildAssetWidget({required BoxFit fit}) {
    if (asset.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(asset, fit: fit);
    }
    return Image.asset(asset, fit: fit);
  }
}

/// Remove this placeholder and route to your real app root (e.g., GamesPage).
class _AppRootPlaceholder extends StatelessWidget {
  const _AppRootPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('App Root', style: TextStyle(color: Colors.white)),
      ),
      backgroundColor: Colors.black,
    );
  }
}

