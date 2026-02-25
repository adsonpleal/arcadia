import 'dart:ui';

import '../constants/arcadia_color.dart';
import 'geometry.dart';
import 'point.dart';

/// A closed smooth lasso preview geometry.
class LassoPreview extends Geometry {
  /// The default constructor for [LassoPreview].
  const LassoPreview({
    required this.points,
    required super.color,
    super.strokeWidth,
  });

  /// The lasso control points in world coordinates.
  final List<Offset> points;

  @override
  List<Point> get snappingPoints => const [];

  @override
  void render(Canvas canvas, Offset viewportOffset, double zoom) {
    if (points.length < 2) {
      return;
    }

    final pathPoints = points.first == points.last
        ? points.sublist(0, points.length - 1)
        : points;

    if (pathPoints.length < 2) {
      return;
    }

    Offset toViewport(Offset position) {
      return position * zoom + viewportOffset;
    }

    Offset midpoint(Offset a, Offset b) {
      return Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    }

    final viewportPoints = [
      for (final point in pathPoints) toViewport(point),
    ];
    final firstMidpoint = midpoint(viewportPoints.last, viewportPoints.first);
    final path = Path()..moveTo(firstMidpoint.dx, firstMidpoint.dy);

    for (var i = 0; i < viewportPoints.length; i++) {
      final current = viewportPoints[i];
      final next = viewportPoints[(i + 1) % viewportPoints.length];
      final end = midpoint(current, next);
      path.quadraticBezierTo(current.dx, current.dy, end.dx, end.dy);
    }

    path.close();

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = .stroke;
    canvas.drawPath(path, paint);
  }

  @override
  bool contains(Offset offset, double tolerance) {
    return false;
  }

  @override
  bool matchesWindowSelection(Rect rect) {
    return false;
  }

  @override
  bool matchesCrossingSelection(Rect rect) {
    return false;
  }

  @override
  bool matchesLassoCrossingSelection(List<Offset> closedLassoPath) {
    return false;
  }

  @override
  Geometry copyWith({double? strokeWidth, ArcadiaColor? color}) {
    return LassoPreview(
      points: points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}
