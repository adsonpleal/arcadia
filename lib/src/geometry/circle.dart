import 'dart:ui';

import '../constants/arcadia_colors.dart';
import 'geometry.dart';
import 'point.dart';

const _cornerPoints = [
  Offset(0, 1),
  Offset(0, -1),
  Offset(1, 0),
  Offset(-1, 0),
];

/// A circle geometry, with radius and center point.
class Circle extends Geometry {
  /// The default constructor for [Circle].
  const Circle({
    required this.center,
    required this.radius,
    required super.color,
    super.strokeWidth,
  });

  /// The center of the circle.
  final Offset center;

  /// The radius of the circle.
  final double radius;

  @override
  List<Point> get snappingPoints {
    return [
      for (final corner in _cornerPoints)
        Point(
          position: corner * radius + center,
          color: ArcadiaColors.snappingPoint,
          shape: .square,
        ),
      Point(
        position: center,
        color: ArcadiaColors.snappingPoint,
        shape: .triangle,
      ),
    ];
  }

  @override
  void render(Canvas canvas, Offset viewportOffset, double zoom) {
    final viewportCenter = (center * zoom) + viewportOffset;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = .stroke;

    canvas.drawCircle(viewportCenter, radius * zoom, paint);
  }

  @override
  bool contains(Offset offset, double tolerance) {
    final distance = ((offset - center).distance - radius).abs();

    return distance <= tolerance;
  }

  @override
  Geometry copyWith({double? strokeWidth, Color? color}) {
    return Circle(
      center: center,
      radius: radius,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}
