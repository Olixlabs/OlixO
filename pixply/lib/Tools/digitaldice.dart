import 'dart:async';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pixply/smoke/animated_circles.dart';
import 'package:pixply/smoke/animation_sequence.dart';
import 'package:pixply/smoke/circle_data.dart';

class Dice extends StatefulWidget {
  const Dice({super.key});

  @override
  State<Dice> createState() => _DiceState();
}

class _DiceState extends State<Dice> {
  Random random = Random();
  int currentImageIndex = 0;
  int counter = 1;
  List<String> images = [
    'assets/images/dice_1.png',
    'assets/images/dice_2.png',
    'assets/images/dice_3.png',
    'assets/images/dice_4.png',
    'assets/images/dice_5.png',
    'assets/images/dice_6.png',
  ];
  AudioPlayer player = AudioPlayer();
  static const double leftPadding = 16.0;
    @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
     player.dispose();
    super.dispose();
  }
   
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(147, 255, 131, 1),
      // SafeArea + custom header so we can put the circular back icon 71x71
      body:  Stack(
        children: [
         
          const Positioned.fill(
          
            child: _AnimatedCirclesWrapper(),
          ),
      SafeArea(
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
                      'Digital Dice',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 0, 0, 0),
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
                      Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
          const SizedBox(height: 40),
          Transform.rotate(
            angle: random.nextDouble() * 180,
            child: Image.asset(
              images[currentImageIndex],
              height: 100,
            ),
          ),
          const SizedBox(height: 60),
          ElevatedButton(
            onPressed: () async {
              // Rolling the dice

              // Sound
              await player.setAsset('assets/audios/rolling-dice.mp3');
              player.play();

              // Roll the dice
              Timer.periodic(const Duration(milliseconds: 80), (timer) {
                counter++;
                setState(() {
                  currentImageIndex = random.nextInt(6);
                });

                if (counter >= 13) {
                  timer.cancel();

                  setState(() {
                    counter = 1;
                  });
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(41),

              ),
             
                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 0),
                      fixedSize: const Size.fromHeight(82),
                     elevation: 6,
            ),

              child: const Text(
                'Roll',
                style: TextStyle(fontSize: 20 , fontWeight: FontWeight.w600, fontFamily: 'Poppins',color: Colors.white ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _AnimatedCirclesWrapper extends StatelessWidget {
  const _AnimatedCirclesWrapper();

  @override
  Widget build(BuildContext context) {
    final seq = AnimationSequence(
      sequences: generateGrayscaleCircleSets(8, 5),
      stepDuration: const Duration(seconds: 1),
    );

    return AnimatedCircles(sequence: seq);
  }
}
List<List<CircleData>> generateGrayscaleCircleSets(int N, int setCount) {
  final List<Color> grayscaleColors = [
    Color.fromARGB(255, 208, 0, 255),
    Color(0xFFE36BFF),
    Color.fromARGB(255, 15, 111, 255),
    Color(0xFF6FA9FF),
    Color.fromARGB(255, 126, 255, 244),
    Color.fromARGB(255, 0, 255, 234),
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