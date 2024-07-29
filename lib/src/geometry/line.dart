import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart';

import '../constants/arcadia_colors.dart';
import 'geometry.dart';
import 'point.dart';

/// A one-dimensional geometry that is defined by two points.
class Line extends Geometry {
  /// The default constructor for [Line].
  const Line({
    required this.start,
    required this.end,
    required super.color,
    super.strokeWidth,
  });

  /// The start point.
  final Offset start;

  /// The end point.
  final Offset end;

  @override
  List<Point> get snappingPoints => [
        Point(
          position: start,
          color: ArcadiaColors.snappingPoint,
          shape: PointShape.square,
        ),
        Point(
          position: end,
          color: ArcadiaColors.snappingPoint,
          shape: PointShape.square,
        ),
        Point(
          position: (start + end) / 2,
          color: ArcadiaColors.snappingPoint,
          shape: PointShape.triangle,
        ),
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

    canvas.drawLine(startPosition, endPosition, paint);
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

    final distance = ((end.dy - start.dy) * offset.dx -
                (end.dx - start.dx) * offset.dy +
                end.dx * start.dy -
                end.dy * start.dx)
            .abs() /
        sqrt(pow(end.dy - start.dy, 2) + pow(end.dx - start.dx, 2));

    return distance <= tolerance;
  }

  @override
  Geometry copyWith({double? strokeWidth, Color? color}) {
    return Line(
      start: start,
      end: end,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}

extension on Offset {
  Offset rotate(double radians) {
    final cosTheta = cos(radians);
    final sinTheta = sin(radians);

    return Offset(
      dx * cosTheta - dy * sinTheta,
      dx * sinTheta + dy * cosTheta,
    );
  }
}
