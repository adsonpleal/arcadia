import 'package:flutter/painting.dart';

import '../constants/arcadia_colors.dart';
import 'geometry.dart';
import 'point.dart';

/// A one-dimensional geometry that is defined by two points.
class Line implements Geometry {
  /// The default constructor for [Line].
  const Line({
    required this.start,
    required this.end,
    required this.color,
  });

  /// The start point.
  final Offset start;

  /// The end point.
  final Offset end;

  /// The color of the 2d representation.
  final Color color;

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
      ..strokeWidth = 1;

    canvas.drawLine(startPosition, endPosition, paint);
  }
}
