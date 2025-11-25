import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:led_ble_lib/led_ble_lib.dart';
import 'package:pixply/smoke/animated_circles.dart';
import 'package:pixply/smoke/animation_sequence.dart';
import 'package:pixply/smoke/circle_data.dart';
import 'package:pixply/explore/yourgame.dart';

class Pixstudio extends StatefulWidget {
  final LedBluetooth bluetooth;
  final bool isConnected;

  const Pixstudio({
    super.key,
    required this.bluetooth,
    required this.isConnected,
  });

  @override
  State<Pixstudio> createState() => _PixstudioState();
}

class _PixstudioState extends State<Pixstudio> with TickerProviderStateMixin {
  double _logoOpacity = 1.0;
  double _pageOpacity = 1.0;
  late AnimationSequence _animationSequence;

  @override
  void initState() {
    super.initState();

    // Generate grayscale animation sequence
    _animationSequence = AnimationSequence(
      sequences: generateGrayscaleCircleSets(8, 5),
      stepDuration: const Duration(seconds: 1),
      onSequenceChange: (index) {
        if (index == 4) {
          // Start fading out the whole page smoothly
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                _pageOpacity = 0.0;
              });

              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(seconds: 1),
                      pageBuilder: (_, __, ___) => Yourgame(
                        bluetooth: widget.bluetooth,
                        isConnected: widget.isConnected,
                      ),
                      transitionsBuilder: (_, animation, __, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                    ),
                  );
                }
              });
            }
          });
        }
      },
    );

    // Fade out the logo while animation plays
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _logoOpacity = 0.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(seconds: 1),
      opacity: _pageOpacity,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Background animation
            AnimatedCircles(sequence: _animationSequence),
            Center(
              child: AnimatedOpacity(
                duration: const Duration(seconds: 1),
                opacity: _logoOpacity,
                // لوگو SVG
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/pix.svg', 
                      width: 73,
                      height: 73,
                    ),
                    const SizedBox(height: 24),

                    // متن PixStudio
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color.fromRGBO(247, 188, 52, 1), Color.fromRGBO(185, 34, 7, 1), Color.fromRGBO(68, 155, 170, 1)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                      child: const Text(
                        'PixStudio',
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, 
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                   
                    const Text(
                      'Make your dream game',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<List<CircleData>> generateGrayscaleCircleSets(int N, int setCount) {
  final List<Color> grayscaleColors = [
    Color.fromARGB(247, 188, 52, 1),
    Color.fromRGBO(247, 188, 52, 1),
    Color.fromARGB(191, 30, 1, 1),
    Color.fromRGBO(68, 155, 170, 1),
    Colors.white
  ];
  final random = Random();
  List<List<CircleData>> sequences = [];

  for (int set = 0; set < setCount; set++) {
    List<CircleData> circleSet = [];
    for (int i = 0; i < N; i++) {
      circleSet.add(CircleData(
        id: '$set-$i',
        normalizedPosition: Offset(random.nextDouble(), random.nextDouble()),
        radius: random.nextDouble() * 40 + 20,
        color: grayscaleColors[random.nextInt(grayscaleColors.length)],
      ));
    }
    sequences.add(circleSet);
  }

  return sequences;
}
