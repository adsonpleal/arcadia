import 'package:flutter/material.dart';

import '../geometry/geometry.dart';
import '../providers/viewport_notifier_provider.dart';

// TODO: Add tests.
// this file depends on both flutter and macro stuff, so we can't test
// it for now.

/// The paint of the viewport.
///
/// This widget renders the geometries.
class ViewportPaint extends StatelessWidget {
  /// The default [ViewportPaint] constructor.
  const ViewportPaint({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ViewportStateBuilder(
      // Only rebuild if zoom or panOffset or geometries change.
      select: (state) => (
        state.zoom,
        state.panOffset,
        state.geometries,
      ),
      builder: (context, value) {
        final (zoom, panOffset, geometries) = value;
        return CustomPaint(
          painter: _ViewportPainter(
            zoom: zoom,
            panOffset: panOffset,
            geometries: geometries,
          ),
        );
      },
    );
  }
}

class _ViewportPainter extends CustomPainter {
  _ViewportPainter({
    required this.panOffset,
    required this.zoom,
    required this.geometries,
  });

  final Offset panOffset;
  final double zoom;
  final List<Geometry> geometries;

  @override
  void paint(Canvas canvas, Size size) {
    final viewportMidpoint = Offset(size.width, size.height) / 2;
    final midPoint = viewportMidpoint + panOffset;

    for (final geometry in geometries) {
      geometry.render(canvas, midPoint, zoom);
    }
  }

  @override
  bool shouldRepaint(covariant _ViewportPainter oldDelegate) {
    return panOffset != oldDelegate.panOffset ||
        zoom != oldDelegate.zoom ||
        geometries != oldDelegate.geometries;
  }
}
