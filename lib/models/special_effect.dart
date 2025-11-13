/// Special effect type
enum SpecialEffect {
  /// Fixed display
  fixed(0x00),

  /// Left shift
  leftShift(0x01),

  /// Right shift
  rightShift(0x02),

  /// Up shift
  upShift(0x03),

  /// Down shift
  downShift(0x04),

  /// Snowflake effect
  snowflake(0x05),

  /// Scroll
  scroll(0x06),

  /// Laser
  laser(0x07);

  /// Effect value
  final int value;

  /// Constructor
  const SpecialEffect(this.value);

  /// Create effect from value
  static SpecialEffect fromValue(int value) {
    return SpecialEffect.values.firstWhere(
          (effect) => effect.value == value,
      orElse: () => SpecialEffect.fixed,
    );
  }
}