// lib/utils/solid_bmp.dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';

class SrgbGamma {
  final bool exact; // true: فرمول دقیق sRGB، false: تقریب γ≈2.2
  const SrgbGamma({this.exact = true});

  double toLinear(double c) {
    if (!exact) return math.pow(c, 2.2) as double;
    // IEC 61966-2-1 (piecewise)
    return c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4) as double;
  }

  double toSrgb(double l) {
    if (!exact) return math.pow(l, 1.0 / 2.2) as double;
    return l <= 0.0031308 ? 12.92 * l : 1.055 * math.pow(l, 1.0 / 2.4) - 0.055;
  }

  int to8bit(double x) => (x.clamp(0.0, 1.0) * 255.0).round();
}

class SolidBmp {
  SolidBmp({
    required this.width,
    required this.height,
    this.masterBrightness = 1.0, // 0..1 (تنها همین‌جا اسکیل می‌کنیم؛ دوباره اسکیل نکن)
    this.gamma = const SrgbGamma(exact: true),
  });

  final int width;
  final int height;
  final double masterBrightness;
  final SrgbGamma gamma;

  /// Color (sRGB 8-bit) → sRGB 8-bit با اعمال گاما به‌درستی (Linear space scaling)
  List<int> _encodeRgbSrgb8(Color color) {
    int r8 = (color.value >> 16) & 0xFF;
    int g8 = (color.value >> 8) & 0xFF;
    int b8 = (color.value) & 0xFF;

    final rl = gamma.toLinear(r8 / 255.0) * masterBrightness;
    final gl = gamma.toLinear(g8 / 255.0) * masterBrightness;
    final bl = gamma.toLinear(b8 / 255.0) * masterBrightness;

    final R = gamma.to8bit(gamma.toSrgb(rl));
    final G = gamma.to8bit(gamma.toSrgb(gl));
    final B = gamma.to8bit(gamma.toSrgb(bl));

    return [R, G, B]; // ترتیب منطقی RGB (نه ترتیب فایل)
  }

  /// می‌سازد: BMP 24-bit (BGR)، bottom-up، با padding تا مضرب ۴ بایت در هر ردیف.
  Uint8List buildBmp(Color color) {
    final rgb = _encodeRgbSrgb8(color); // [R,G,B] پس از گاما + روشنایی
    final R = rgb[0], G = rgb[1], B = rgb[2];

    final rowBytesNoPad = width * 3;                     // 24-bit → 3 بایت در هر پیکسل
    final pad = (4 - (rowBytesNoPad % 4)) % 4;           // پدینگ تا مضرب ۴
    final rowBytes = rowBytesNoPad + pad;
    final pixelArraySize = rowBytes * height;

    const fileHeaderSize = 14;
    const dibHeaderSize = 40; // BITMAPINFOHEADER
    final pixelDataOffset = fileHeaderSize + dibHeaderSize;
    final fileSize = pixelDataOffset + pixelArraySize;

    final bytes = BytesBuilder();

    // BITMAPFILEHEADER (14)
    bytes.add([0x42, 0x4D]);                 // 'BM'
    bytes.add(_le32(fileSize));              // bfSize
    bytes.add(_le16(0)); bytes.add(_le16(0));
    bytes.add(_le32(pixelDataOffset));       // bfOffBits

    // BITMAPINFOHEADER (40)
    bytes.add(_le32(dibHeaderSize));         // biSize
    bytes.add(_le32(width));                 // biWidth
    bytes.add(_le32(height));                // biHeight (مثبت → bottom-up)
    bytes.add(_le16(1));                     // biPlanes
    bytes.add(_le16(24));                    // biBitCount
    bytes.add(_le32(0));                     // biCompression = BI_RGB
    bytes.add(_le32(pixelArraySize));        // biSizeImage
    bytes.add(_le32(2835));                  // biXPelsPerMeter (~72 DPI)
    bytes.add(_le32(2835));                  // biYPelsPerMeter
    bytes.add(_le32(0));                     // biClrUsed
    bytes.add(_le32(0));                     // biClrImportant

    // بدنه پیکسل‌ها: bottom-up (از پایین‌ترین ردیف تا بالا)
    final row = Uint8List(rowBytes);
    for (int x = 0; x < width; x++) {
      final o = x * 3;
      // BMP باید B, G, R بنویسیم
      row[o + 0] = B;
      row[o + 1] = G;
      row[o + 2] = R;
    }
    // پدینگ انتهای ردیف‌ها صفر می‌ماند

    for (int y = 0; y < height; y++) {
      bytes.add(row);
    }

    return bytes.toBytes();
  }

  List<int> _le16(int v) => [v & 0xFF, (v >> 8) & 0xFF];
  List<int> _le32(int v) => [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF];
}
