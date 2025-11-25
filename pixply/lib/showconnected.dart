import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:led_ble_lib/led_ble_lib.dart';
import 'package:pixply/games.dart';

class ConnectedScreen extends StatefulWidget {
  final LedBluetooth bluetooth;
  final bool isConnected;

  const ConnectedScreen({super.key, required this.bluetooth, required this.isConnected});

  @override
  State<ConnectedScreen> createState() => _ConnectedScreenState();
}

class _ConnectedScreenState extends State<ConnectedScreen>
    with TickerProviderStateMixin {
  late final AnimationController ringCtrl;     
  late final AnimationController checkCtrl;   
  late final AnimationController textCtrl;    

  late final Animation<double> ring;          
  late final Animation<double> check;         
  late final Animation<Offset> slide;         
  late final Animation<double> fade;          

  @override
  void initState() {
    super.initState();

    ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    checkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    ring = CurvedAnimation(parent: ringCtrl, curve: Curves.easeInOut);
    check = CurvedAnimation(parent: checkCtrl, curve: Curves.easeOut);

    slide = Tween<Offset>(begin: const Offset(0, .25), end: Offset.zero)
        .animate(CurvedAnimation(parent: textCtrl, curve: Curves.easeOut));
    fade = CurvedAnimation(parent: textCtrl, curve: Curves.easeIn);

    //  circle → check → text
    ringCtrl.forward().whenComplete(() {
      checkCtrl.forward().whenComplete(() {
        textCtrl.forward().whenComplete(() {
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => GamesScreen( bluetooth: widget.bluetooth, isConnected: widget.isConnected,)), 
            );
          });
        });
      });
    });
  }

  @override
  void dispose() {
    ringCtrl.dispose();
    checkCtrl.dispose();
    textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = 50;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: AnimatedBuilder(
                animation: Listenable.merge([ringCtrl, checkCtrl]),
                builder: (context, _) {
                  return CustomPaint(
                    painter: _CheckPainter(
                      ringProgress: ring.value,
                      checkProgress: check.value,
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            
            FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: const Text(
                  'Connected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins',
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

class _CheckPainter extends CustomPainter {
  final double ringProgress;   // 0..1
  final double checkProgress;  // 0..1
  final Color color;
  final double strokeWidth;

  _CheckPainter({
    required this.ringProgress,
    required this.checkProgress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;

    
    final startAngle = -math.pi / 2;
    final sweep = (2 * math.pi) * ringProgress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      paint,
    );

    final p1 = Offset(center.dx - radius * 0.45, center.dy + radius * 0.05);
    final p2 = Offset(center.dx - radius * 0.1,  center.dy + radius * 0.35);
    final p3 = Offset(center.dx + radius * 0.5,  center.dy - radius * 0.35);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy);

  
    final metrics = path.computeMetrics().toList();
    double drawLength = 0;
    for (final m in metrics) {
      drawLength += m.length;
    }
    final currentLen = drawLength * checkProgress;

    double consumed = 0;
    for (final m in metrics) {
      final remain = currentLen - consumed;
      final seg = remain.clamp(0, m.length).toDouble();
      if (seg > 0) {
        final extract = m.extractPath(0, seg);
        canvas.drawPath(extract, paint);
        consumed += seg;
      } else {
        break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) =>
      old.ringProgress != ringProgress ||
      old.checkProgress != checkProgress ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
