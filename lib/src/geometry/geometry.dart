import 'dart:ui';

import 'point.dart';

/// A class that represents a generic geometry.
///
/// A geometry is a generic concept that encompasses all geometric shapes,
/// regardless of the number of dimensions. Such as:
/// - Points, zero-dimensional geometry.
/// - Lines, one-dimensional geometry.
/// - Arcs.
/// - And any other possible shape.
abstract class Geometry {
  /// The default constructor for [Geometry].
  const Geometry({
    required this.color,
    this.strokeWidth = 1,
  });

  /// The geometry's color.
  final Color color;

  /// The width of the drawn stroke.
  final double strokeWidth;

  /// The list of points that can be used for snapping.
  List<Point> get snappingPoints;

  /// A method to render the geometry to the viewport.
  ///
  /// It takes a [canvas], where the shape will be rendered, a [viewportOffset]
  /// that offsets the position relative to the viewport and a [zoom], that
  /// will change, mostly, the position of vertices to simulate a zoom effect.
  void render(Canvas canvas, Offset viewportOffset, double zoom);

  /// A method to check if a geometry contains the given point.
  ///
  /// Useful to do things like checking if the cursor is hovering a given line.
  bool contains(Offset offset, double tolerance);

  /// Creates a copy of this geometry, replacing its [color] or/and [strokeWidth].
  Geometry copyWith({double? strokeWidth, Color? color});
}
