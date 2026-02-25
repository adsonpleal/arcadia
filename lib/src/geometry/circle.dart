import 'dart:math';
import 'dart:ui';

import '../constants/arcadia_color.dart';
import 'geometry.dart';
import 'point.dart';

const _circleSampleSegments = 1000;
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
  bool containedIn(Rect rect) {
    return _samplePerimeterPoints().every(rect.contains);
  }

  @override
  bool intersects(Rect rect) {
    return _samplePerimeterPoints().any(rect.contains);
  }

  List<Offset> _samplePerimeterPoints() {
    return [
      for (var i = 0; i <= _circleSampleSegments; i++)
        center +
            Offset(
              radius * cos(2 * pi * i / _circleSampleSegments),
              radius * sin(2 * pi * i / _circleSampleSegments),
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
