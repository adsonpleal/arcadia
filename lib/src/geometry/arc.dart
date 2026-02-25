import 'dart:math';
import 'dart:ui';

import '../constants/arcadia_color.dart';
import 'geometry.dart';
import 'point.dart';
import 'selection_math.dart';

/// An Arc geometry, as a segment of a circle.
class Arc extends Geometry {
  const Arc._({
    required this.center,
    required this.radius,
    required this.startAngle,
    required this.sweepAngle,
    required super.color,
    required this.snappingPoints,
    super.strokeWidth,
  });

  /// Creates an arc given three points.
  ///
  /// The order does not matter, the arc will always draw the smallest possible
  /// arc given the three point.
  factory Arc.fromPoints({
    required Offset first,
    required Offset second,
    required Offset third,
    required ArcadiaColor color,
  }) {
    final mid1 = (first + second) / 2;
    final mid2 = (second + third) / 2;
    final delta1 = first - second;
    final delta2 = second - third;
    final slope1 = delta1.dy == 0 ? 0 : -(delta1.dx / delta1.dy);
    final slope2 = delta2.dy == 0 ? 0 : -(delta2.dx / delta2.dy);
    final c1 = mid1.dy - slope1 * mid1.dx;
    final c2 = mid2.dy - slope2 * mid2.dx;
    final centerDx = (c2 - c1) / (slope1 - slope2);
    final centerDy = slope1 * centerDx + c1;
    final center = Offset(centerDx, centerDy);
    final radius = (first - center).distance;

    double angle(Offset offset) {
      final angle = (offset - center).direction;

      if (angle < 0) {
        return 2 * pi + angle;
      }

      return angle;
    }

    /// sorted counterclockwise by their angles
    final sortedPoints = [first, second, third]
      ..sort((a, b) => angle(a).compareTo(angle(b)));
    final [angleA, angleB, angleC] = sortedPoints.map(angle).toList();
    final firstArcLength = angleC - angleA;
    final secondArcLength = 2 * pi - angleB + angleA;
    final thirdArcLength = 2 * pi - angleC + angleB;

    // find the smallest arc
    final arcLength = [
      firstArcLength,
      secondArcLength,
      thirdArcLength,
    ].reduce(min);

    final double startAngle;
    final Offset startSnapping;
    final Offset endSnapping;

    if (arcLength == firstArcLength) {
      startAngle = angleA;
      startSnapping = sortedPoints[0];
      endSnapping = sortedPoints[2];
    } else if (arcLength == secondArcLength) {
      startAngle = angleB;
      startSnapping = sortedPoints[1];
      endSnapping = sortedPoints[0];
    } else {
      startAngle = angleC;
      startSnapping = sortedPoints[2];
      endSnapping = sortedPoints[1];
    }

    return Arc._(
      center: center,
      radius: radius,
      startAngle: startAngle,
      sweepAngle: arcLength,
      color: color,
      snappingPoints: [
        Point(position: startSnapping, color: .accent, shape: .square),
        Point(position: endSnapping, color: .accent, shape: .square),
        Point(position: center, color: .accent, shape: .triangle),
      ],
    );
  }

  /// The center of the circle for this arc.
  final Offset center;

  /// The radius of the circle for this arc.
  final double radius;

  /// The start angle for this arc.
  final double startAngle;

  /// The sweep angle for this arc.
  final double sweepAngle;

  @override
  final List<Point> snappingPoints;

  @override
  void render(Canvas canvas, Offset viewportOffset, double zoom) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = .stroke;
    final rect = Rect.fromCircle(
      center: center * zoom + viewportOffset,
      radius: radius * zoom,
    );

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool contains(Offset offset, double tolerance) {
    final delta = offset - center;
    final distance = delta.distance;

    if (distance > radius + tolerance || distance < radius - tolerance) {
      return false;
    }

    final angle = delta.direction;
    final normalizedAngle = angle < 0 ? 2 * pi + angle : angle;

    return normalizedAngle <= sweepAngle + startAngle &&
        normalizedAngle >= startAngle;
  }

  @override
  bool matchesWindowSelection(Rect rect) {
    return _sampleArcPoints().every(rect.contains);
  }

  @override
  bool matchesCrossingSelection(Rect rect) {
    final points = _sampleArcPoints();
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

  List<Offset> _sampleArcPoints({int segments = 24}) {
    return [
      for (var i = 0; i <= segments; i++)
        center +
            Offset.fromDirection(
              startAngle + sweepAngle * (i / segments),
              radius,
            ),
    ];
  }

  @override
  Geometry copyWith({double? strokeWidth, ArcadiaColor? color}) {
    return Arc._(
      center: center,
      radius: radius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      color: color ?? this.color,
      snappingPoints: snappingPoints,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}
