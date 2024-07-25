import 'package:flutter/widgets.dart';

import '../geometry/geometry.dart';

/// A custom painter for geometries.
class ViewportPainter extends CustomPainter {
  /// The default constructor for [ViewportPainter].
  ViewportPainter({
    required this.panOffset,
    required this.zoom,
    required this.geometries,
  });

  /// The current viewport pan offset.
  final Offset panOffset;

  /// The current viewport zoom.
  final double zoom;

  /// The geometries to be rendered.
  final List<Geometry> geometries;

  @override
  void paint(Canvas canvas, Size size) {
    final viewportMidpoint = Offset(size.width, size.height) / 2;
    final viewportOffset = viewportMidpoint + panOffset;

    for (final geometry in geometries) {
      geometry.render(canvas, viewportOffset, zoom);
    }
  }

  @override
  bool shouldRepaint(covariant ViewportPainter oldDelegate) {
    return panOffset != oldDelegate.panOffset ||
        zoom != oldDelegate.zoom ||
        geometries != oldDelegate.geometries;
  }
}
