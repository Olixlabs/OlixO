import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class TextData {
  static Future<ui.Image> getCharBitmap(String c, int width, int height, int typeFace, Color textColor) async {
    // Create a picture recorder to record the drawing operations
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);

    bool chinese = isChinese(c[0]);

    // Set up the paint
    final ui.Paint paint = ui.Paint()..color = Colors.transparent;
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), paint);

    final textStyle = TextStyle(
      // fontSize: chinese ? height.toDouble() : (width * 1.3),
      fontSize: chinese ? height.toDouble() : (width / 2.0),
      color: textColor,
      fontFamily: getTypefaceName(typeFace),
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w100
    );

    final textSpan = TextSpan(
      text: c,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    // Position the text - Flutter's drawing is different, so we need to calculate the position
    final double x = (width / 2.0) - (textPainter.width / 2.0);
    // final double y = (height * 5.2 / 6.0) - textPainter.height;
    final double y = (height / 2.0) - (textPainter.height / 2.0);

    textPainter.paint(canvas, ui.Offset(x + 1, y));

    // Convert the picture to an image
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(width, height);

    return image;
  }

  // This is a placeholder implementation - you'll need to implement actual Chinese character detection
  static bool isChinese(String char) {
    // Example implementation - check if character is within the Unicode range for Chinese characters
    int codePoint = char.codeUnitAt(0);
    return (codePoint >= 0x4E00 && codePoint <= 0x9FFF) ||
        (codePoint >= 0x3400 && codePoint <= 0x4DBF) ||
        (codePoint >= 0x20000 && codePoint <= 0x2A6DF) ||
        (codePoint >= 0x2A700 && codePoint <= 0x2B73F) ||
        (codePoint >= 0x2B740 && codePoint <= 0x2B81F) ||
        (codePoint >= 0x2B820 && codePoint <= 0x2CEAF) ||
        (codePoint >= 0xF900 && codePoint <= 0xFAFF) ||
        (codePoint >= 0x2F800 && codePoint <= 0x2FA1F);
  }

  // You'll need to implement this based on your FontUtils class
  static String getTypefaceName(int typeFace) {
    // This is a placeholder - replace with your actual implementation that maps
    // your typeFace integers to Flutter font families
    switch (typeFace) {
      case 0: return 'Roboto';
      case 1: return 'Roboto-Bold';
      case 2: return 'NotoSansSC'; // For Chinese
      // Add more cases as needed
      case 3: return 'SimSun';
      case 4: return 'SimHei';
      case 5: return 'KaiTi';
      case 6: return 'Microsoft YaHei';
      default: return 'Roboto';
    }
  }
}
