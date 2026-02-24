import 'package:flutter/material.dart';

import '../providers/viewport_notifier_provider.dart';
import 'viewport_painter.dart';

/// The paint of the viewport.
///
/// This widget renders the geometries.
class ViewportPaint extends StatelessWidget {
  /// The default [ViewportPaint] constructor.
  const ViewportPaint({super.key});

  @override
  Widget build(BuildContext context) {
    // Only rebuild if zoom or panOffset or geometries change.
    final (zoom, panOffset, geometries) = context.selectViewportState(
      (state) => (state.zoom, state.panOffset, state.geometries),
    );

    return CustomPaint(
      painter: ViewportPainter(
        zoom: zoom,
        panOffset: panOffset,
        geometries: geometries,
      ),
    );
  }
}
