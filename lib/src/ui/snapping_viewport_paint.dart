import 'package:flutter/material.dart';

import '../providers/viewport_notifier_provider.dart';
import 'viewport_painter.dart';

// TODO: Add tests.
// this file depends on both flutter and macro stuff, so we can't test
// it for now.

/// The paint for the snapping geometries.
class SnappingViewportPaint extends StatelessWidget {
  /// The default constructor for [SnappingViewportPaint].
  const SnappingViewportPaint({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewportStateBuilder(
      select: (state) =>
          (state.zoom, state.panOffset, state.snappingGeometries),
      builder: (context, value) {
        final (zoom, panOffset, snappingGeometries) = value;

        return CustomPaint(
          painter: ViewportPainter(
            zoom: zoom,
            panOffset: panOffset,
            geometries: snappingGeometries,
          ),
        );
      },
    );
  }
}
