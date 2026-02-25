import 'dart:ui';

import '../../constants/arcadia_color.dart';
import '../../geometry/line.dart';

/// Generates lines for a rectangle.
List<Line> rectangleLinesFromRect({
  required Rect rect,
  required ArcadiaColor color,
  bool dashed = false,
}) {
  return [
    Line(
      start: rect.topLeft,
      end: rect.topRight,
      color: color,
      dashed: dashed,
    ),
    Line(
      start: rect.topRight,
      end: rect.bottomRight,
      color: color,
      dashed: dashed,
    ),
    Line(
      start: rect.bottomRight,
      end: rect.bottomLeft,
      color: color,
      dashed: dashed,
    ),
    Line(
      start: rect.bottomLeft,
      end: rect.topLeft,
      color: color,
      dashed: dashed,
    ),
  ];
}
