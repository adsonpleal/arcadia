import 'dart:ui';

import 'geometry.dart';

/// The shape of a point.
///
/// This determines how the point is going to be rendered
/// in the viewport.
enum PointShape {
  /// A triangular shape
  triangle,

  /// A square shape
  square,
}

const _pointSize = 10.0;
const _pointOffset = Offset(_pointSize / 2, _pointSize / 2);

/// A zero-dimensional geometry.
///
/// The point is rendered in the viewport as a 2D shape,
/// defined by [shape].
/// The point needs a [position] and a [color].
class Point extends Geometry {
  /// The default constructor
  const Point({
    required this.position,
    required super.color,
    required this.shape,
    super.strokeWidth,
  });

  @override
  List<Point> get snappingPoints => [];

  /// The position in which the point's center will be placed.
  final Offset position;

  /// The shape of the 2D representation
  final PointShape shape;

  @override
  void render(Canvas canvas, Offset viewportOffset, double zoom) {
    // The zoom only affects the position. Points are zero-dimensional
    // shapes. The shape itself is just a 2D representation, so it will
    // not scale with the zoom.
    final viewportPosition = (position * zoom) + viewportOffset;
    final paint = Paint()..color = color;

    switch (shape) {
      case .triangle:
        final trianglePath = Path()
          ..moveTo(
            viewportPosition.dx - _pointSize / 2,
            viewportPosition.dy + _pointSize / 2,
          )
          ..relativeLineTo(_pointSize, 0)
          ..relativeLineTo(-_pointSize / 2, -_pointSize)
          ..close();
        canvas.drawPath(trianglePath, paint);
      case .square:
        canvas.drawRect(
          viewportPosition - _pointOffset & const .square(_pointSize),
          paint,
        );
    }
  }

  @override
  bool contains(Offset offset, double tolerance) {
    return (position - offset).distance <= tolerance;
  }

  @override
  Geometry copyWith({double? strokeWidth, Color? color}) {
    return Point(
      position: position,
      color: color ?? this.color,
      shape: shape,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}
