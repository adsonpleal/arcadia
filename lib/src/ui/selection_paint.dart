import 'package:flutter/material.dart';

import '../providers/viewport_notifier_provider.dart';
import 'viewport_painter.dart';

/// The paint of the selection geometries.
///
/// This widget renders the selectionGeometries.
class SelectionPaint extends StatelessWidget {
  /// The default [SelectionPaint] constructor.
  const SelectionPaint({super.key});

  @override
  Widget build(BuildContext context) {
    // Only rebuild if zoom or panOffset or selectionGeometries change.
    final (zoom, panOffset, selectionGeometries) = context.selectViewportState(
      (state) => (state.zoom, state.panOffset, state.selectionGeometries),
    );

    return CustomPaint(
      painter: ViewportPainter(
        zoom: zoom,
        panOffset: panOffset,
        geometries: selectionGeometries,
      ),
    );
  }
}
