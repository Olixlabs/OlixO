import 'dart:typed_data';
import 'package:crclib/catalog.dart';

import 'program_type.dart';
import 'special_effect.dart';

/// Program information class
class Program {
  /// Program ID (CRC32-C checksum)
  final int programId;

  /// Partition X coordinate
  final int partitionX;

  /// Partition Y coordinate
  final int partitionY;

  /// Partition width
  final int partitionWidth;

  /// Partition height
  final int partitionHeight;

  /// Program type
  final ProgramType programType;

  /// Total number of frames
  final int totalFrames;

  /// Special effect
  final SpecialEffect specialEffect;

  /// Speed (0-100)
  final int speed;

  /// Stay time
  final int stayTime;

  /// Whether it has circular border
  final int circularBorder;

  /// Brightness (0-100)
  final int brightness;

  final int rotationAngle;

  final int angle;
  

  /// Program data
  final Uint8List programData;

  

  

  /// Constructor
  Program({
    required this.partitionX,
    required this.partitionY,
    required this.partitionWidth,
    required this.partitionHeight,
    required this.programType,
    required this.totalFrames,
    required this.specialEffect,
    required this.speed,
    required this.stayTime,
    required this.circularBorder,
    required this.brightness,
    required this.programData,
    this.rotationAngle = 0,
    this.angle = 0,
  }) : programId = _calculateProgramId(programData);

  /// Calculate Program ID (CRC32-C checksum)
  static int _calculateProgramId(Uint8List data) {
    final crc = Crc32C();
    final value = crc.convert(data).toBigInt().toInt();
    return value;
  }

  /// Convert program to byte array
  Uint8List toBytes() {
    // Create program header
    final List<int> header = [
      (programId >> 24) & 0xFF,
      (programId >> 16) & 0xFF,
      (programId >> 8) & 0xFF,
      programId & 0xFF,
      0x01,
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
      // Partition X,Y coordinates
      (partitionX >> 8) & 0xFF, partitionX & 0xFF,
      (partitionY >> 8) & 0xFF, partitionY & 0xFF,

      // Partition dimensions
      (partitionWidth >> 8) & 0xFF, partitionWidth & 0xFF,
      (partitionHeight >> 8) & 0xFF, partitionHeight & 0xFF,

      // Reserved bytes
      0x00, 0x00, 0x00,

      // Program type
      programType.value,

      // Total frames
      (totalFrames >> 8) & 0xFF, totalFrames & 0xFF,

      // Special effect
      specialEffect.value,

      // Speed
      speed,

      // Stay time
      stayTime,

      // Circular border
      circularBorder,

      // Brightness
      brightness,

      // Reserved values
      0x00, 0x00, 0x00,
    ];

    // Merge header and program data
    final result = Uint8List(header.length + programData.length);
    result.setRange(0, header.length, header);
    result.setRange(header.length, header.length + programData.length, programData);

    return result;
  }

  /// Create text program
  factory Program.text({
    required int partitionX,
    required int partitionY,
    required int partitionWidth,
    required int partitionHeight,
    required Uint8List textData,
    required SpecialEffect specialEffect,
    required int speed,
    required int stayTime,
    required int circularBorder,
    required int brightness,
  }) {
    return Program(
      partitionX: partitionX,
      partitionY: partitionY,
      partitionWidth: partitionWidth,
      partitionHeight: partitionHeight,
      programType: ProgramType.text,
      totalFrames: 1, // For text, frame count may need to be calculated based on actual content and effect
      specialEffect: specialEffect,
      speed: speed,
      stayTime: stayTime,
      circularBorder: circularBorder,
      brightness: brightness,
      programData: textData,
    );
  }

  /// Create BMP program
  factory Program.bmp({
    required int partitionX,
    required int partitionY,
    required int partitionWidth,
    required int partitionHeight,
    required Uint8List bmpData,
    required SpecialEffect specialEffect,
    required int speed,
    required int stayTime,
    required int circularBorder,
    required int brightness,
  }) {
    return Program(
      partitionX: partitionX,
      partitionY: partitionY,
      partitionWidth: partitionWidth,
      partitionHeight: partitionHeight,
      programType: ProgramType.bmp,
      totalFrames: 1,
      specialEffect: specialEffect,
      speed: speed,
      stayTime: stayTime,
      circularBorder: circularBorder,
      brightness: brightness,
      programData: bmpData,
    );
  }

  /// Create GIF program
  factory Program.gif({
    required int partitionX,
    required int partitionY,
    required int partitionWidth,
    required int partitionHeight,
    required Uint8List gifData,
    required int totalFrames,
    required int speed,
    required int stayTime,
    required int circularBorder,
    required int brightness,
  }) {
    return Program(
      partitionX: partitionX,
      partitionY: partitionY,
      partitionWidth: partitionWidth,
      partitionHeight: partitionHeight,
      programType: ProgramType.gif,
      totalFrames: totalFrames,
      specialEffect: SpecialEffect.fixed, // GIF program special effect is fixed
      speed: speed,
      stayTime: stayTime,
      circularBorder: circularBorder,
      brightness: brightness,
      programData: gifData,
    );
  }

  /// Create time program
  factory Program.time({
    required int partitionX,
    required int partitionY,
    required int partitionWidth,
    required int partitionHeight,
    required int dateFormat,
    required int dateColor,
    required int timeFormat,
    required int timeColor,
    required int weekFormat,
    required int weekColor,
    required int fontSize,
    required int stayTime,
    required int circularBorder,
    required int brightness,
  }) {
    // Create time program data
    // This is a simplified implementation, actual application needs to implement according to documentation details
    final List<int> timeData = [
      dateFormat,
      dateColor,
      timeFormat,
      timeColor,
      weekFormat,
      weekColor,
      fontSize,
      0x00, // Reserved byte
      0x00, 0x00, 0x00, // Reserved bytes
      0x00, 0x00, // Chinese character display size
      0x00, 0x00, // ASCII character display size
    ];

    return Program(
      partitionX: partitionX,
      partitionY: partitionY,
      partitionWidth: partitionWidth,
      partitionHeight: partitionHeight,
      programType: ProgramType.time,
      totalFrames: 1,
      specialEffect: SpecialEffect.fixed, // Time program special effect is fixed
      speed: 0, // Time program speed is fixed at 0
      stayTime: stayTime,
      circularBorder: circularBorder,
      brightness: brightness,
      programData: Uint8List.fromList(timeData),
    );
  }
}