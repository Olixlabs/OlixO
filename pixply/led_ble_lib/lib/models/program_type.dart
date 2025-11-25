/// Program type
enum ProgramType {
  /// Text program
  text(0x00),

  /// BMP program
  bmp(0x01),

  /// GIF program
  gif(0x02),

  /// Time program
  time(0x03),

  /// Multimedia text program
  multimediaText(0x04),

  /// Built-in GIF program
  builtInGif(0x05),

  /// GIF file format program
  gifFile(0x06);

  

  /// Program type value
  final int value;

  /// Constructor
  const ProgramType(this.value);

  /// Create program type from value
  static ProgramType fromValue(int value) {
    return ProgramType.values.firstWhere(
          (type) => type.value == value,
      orElse: () => ProgramType.text,
    );
  }
}