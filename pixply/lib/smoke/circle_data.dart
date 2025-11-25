import 'dart:ui';


class CircleData {
  final String id;
  final Offset normalizedPosition;
  final double radius;
  final Color color;

  CircleData({
    required this.id,
    required this.normalizedPosition,
    required this.radius,
    required this.color,
  }) : assert(
            normalizedPosition.dx >= 0 &&
                normalizedPosition.dx <= 1 &&
                normalizedPosition.dy >= 0 &&
                normalizedPosition.dy <= 1,
            "Normalized position must be between 0 and 1");

  CircleData lerp(CircleData other, double t) {
    return CircleData(
      id: id,
      normalizedPosition:
          Offset.lerp(normalizedPosition, other.normalizedPosition, t)!,
      radius: lerpDouble(radius, other.radius, t)!,
      color: Color.lerp(color, other.color, t)!,
    );
  }
}
