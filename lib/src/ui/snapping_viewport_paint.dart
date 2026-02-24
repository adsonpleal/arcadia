import 'package:flutter/material.dart';

import '../providers/viewport_notifier_provider.dart';
import 'viewport_painter.dart';

/// The paint for the snapping geometries.
class SnappingViewportPaint extends StatelessWidget {
  /// The default constructor for [SnappingViewportPaint].
  const SnappingViewportPaint({super.key});

  @override
  Widget build(BuildContext context) {
    final (zoom, panOffset, snappingGeometries) = context.selectViewportState(
      (state) => (state.zoom, state.panOffset, state.snappingGeometries),
    );

    return CustomPaint(
      painter: ViewportPainter(
        zoom: zoom,
        panOffset: panOffset,
        geometries: snappingGeometries,
      ),
    );
  }
}
