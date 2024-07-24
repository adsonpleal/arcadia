import 'dart:ui';

part 'point.dart';

/// A class that represents a geometry.
///
/// A geometry is a generic concept that encompasses all geometric shapes,
/// regardless of the number of dimensions. Such as:
/// - Points, zero-dimensional geometry.
/// - Lines, one-dimensional geometry.
/// - Arcs.
/// - And any other possible shape.
sealed class Geometry {
  const Geometry();

  /// A method to render the geometry to the viewport.
  ///
  /// It takes a [canvas], where the shape will be rendered, a [viewportOffset]
  /// that offsets the position relative to the viewport and a [zoom], that
  /// will change, mostly, the position of vertices to simulate a zoom effect.
  void render(Canvas canvas, Offset viewportOffset, double zoom);
}
