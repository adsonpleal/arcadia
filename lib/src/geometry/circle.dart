import 'dart:math';
import 'dart:ui';

import '../constants/arcadia_color.dart';
import 'geometry.dart';
import 'point.dart';
import 'selection_math.dart';

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
          color: .accent,
          shape: .square,
        ),
      Point(position: center, color: .accent, shape: .triangle),
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
  bool matchesWindowSelection(Rect rect) {
    return _samplePerimeterPoints().every(rect.contains);
  }

  @override
  bool matchesCrossingSelection(Rect rect) {
    if (matchesWindowSelection(rect)) {
      return true;
    }

    final points = _samplePerimeterPoints();
    if (points.any(rect.contains)) {
      return true;
    }

    for (var index = 0; index < points.length - 1; index++) {
      if (segmentIntersectsRect(points[index], points[index + 1], rect)) {
        return true;
      }
    }

    return false;
  }

  List<Offset> _samplePerimeterPoints({int segments = 48}) {
    return [
      for (var i = 0; i <= segments; i++)
        center +
            Offset(
              radius * cos(2 * pi * i / segments),
              radius * sin(2 * pi * i / segments),
            ),
    ];
  }

  @override
  Geometry copyWith({double? strokeWidth, ArcadiaColor? color}) {
    return Circle(
      center: center,
      radius: radius,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}
