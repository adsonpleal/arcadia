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
class Circle implements Geometry {
  /// The default constructor for [Circle].
  const Circle({
    required this.center,
    required this.radius,
    required this.color,
  });

  /// The center of the circle.
  final Offset center;

  /// The radius of the circle.
  final double radius;

  /// The color that this geometry will be rendered.
  final Color color;

  @override
  List<Point> get snappingPoints {
    return [
      for (final corner in _cornerPoints)
        Point(
          position: corner * radius + center,
          color: ArcadiaColors.snappingPoint,
          shape: PointShape.square,
        ),
      Point(
        position: center,
        color: ArcadiaColors.snappingPoint,
        shape: PointShape.triangle,
      ),
    ];
  }

  @override
  void render(Canvas canvas, Offset viewportOffset, double zoom) {
    final viewportCenter = (center * zoom) + viewportOffset;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(viewportCenter, radius * zoom, paint);
  }
}
