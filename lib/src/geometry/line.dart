import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart';

import '../constants/arcadia_color.dart';
import '../foundation/geometry/selection_math.dart';
import 'geometry.dart';
import 'point.dart';

const _dashSize = 5.0;

/// A one-dimensional geometry that is defined by two points.
class Line extends Geometry {
  /// The default constructor for [Line].
  const Line({
    required this.start,
    required this.end,
    required super.color,
    this.dashed = false,
    super.strokeWidth,
  });

  /// The start point.
  final Offset start;

  /// The end point.
  final Offset end;

  /// Whether or not the line is dashed.
  final bool dashed;

  @override
  List<Point> get snappingPoints => [
    Point(position: start, color: .accent, shape: .square),
    Point(position: end, color: .accent, shape: .square),
    Point(position: (start + end) / 2, color: .accent, shape: .triangle),
  ];

  @override
  void render(Canvas canvas, Offset viewportOffset, double zoom) {
    Offset toViewportPosition(Offset position) {
      return (position * zoom) + viewportOffset;
    }

    final startPosition = toViewportPosition(start);
    final endPosition = toViewportPosition(end);

    final paint = Paint()
      ..color = color
      // Lines are always rendered with a width of 1 logical pixel.
      // Regardless of zoom.
      ..strokeWidth = strokeWidth;

    if (dashed) {
      final segment = endPosition - startPosition;
      final length = segment.distance;

      if (length == 0) {
        return;
      }

      final direction = segment / length;
      for (var distance = 0.0; distance < length; distance += _dashSize * 2) {
        final dashStart = startPosition + direction * distance;
        final dashEnd =
            startPosition + direction * min(distance + _dashSize, length);
        canvas.drawLine(dashStart, dashEnd, paint);
      }
    } else {
      canvas.drawLine(startPosition, endPosition, paint);
    }
  }

  @override
  bool contains(Offset offset, double tolerance) {
    final lineAngle = (end - start).direction;
    final rotatedStart = start.rotate(-lineAngle);
    final rotatedEnd = end.rotate(-lineAngle);
    final rotatedPoint = offset.rotate(-lineAngle);

    if (rotatedPoint.dx < rotatedStart.dx || rotatedPoint.dx > rotatedEnd.dx) {
      return false;
    }

    final distance =
        ((end.dy - start.dy) * offset.dx -
                (end.dx - start.dx) * offset.dy +
                end.dx * start.dy -
                end.dy * start.dx)
            .abs() /
        sqrt(pow(end.dy - start.dy, 2) + pow(end.dx - start.dx, 2));

    return distance <= tolerance;
  }

  @override
  bool containedIn(Rect rect) {
    return rect.contains(start) && rect.contains(end);
  }

  @override
  bool intersects(Rect rect) {
    if (rect.contains(start) || rect.contains(end)) {
      return true;
    }

    for (final (a, b) in rectEdges(rect)) {
      if (segmentsIntersect(start, end, a, b)) {
        return true;
      }
    }

    return false;
  }

  @override
  Geometry copyWith({double? strokeWidth, ArcadiaColor? color}) {
    return Line(
      start: start,
      end: end,
      color: color ?? this.color,
      dashed: dashed,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}

extension on Offset {
  Offset rotate(double radians) {
    final cosTheta = cos(radians);
    final sinTheta = sin(radians);

    return Offset(dx * cosTheta - dy * sinTheta, dx * sinTheta + dy * cosTheta);
  }
}
