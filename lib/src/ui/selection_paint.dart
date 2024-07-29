import 'package:flutter/material.dart';

import '../providers/viewport_notifier_provider.dart';
import 'viewport_painter.dart';

// TODO: Add tests.
// this file depends on both flutter and macro stuff, so we can't test
// it for now.

/// The paint of the selection geometries.
///
/// This widget renders the selectionGeometries.
class SelectionPaint extends StatelessWidget {
  /// The default [SelectionPaint] constructor.
  const SelectionPaint({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ViewportStateBuilder(
      // Only rebuild if zoom or panOffset or selectionGeometries change.
      select: (state) => (
        state.zoom,
        state.panOffset,
        state.selectionGeometries,
      ),
      builder: (context, value) {
        final (zoom, panOffset, selectionGeometries) = value;

        return CustomPaint(
          painter: ViewportPainter(
            zoom: zoom,
            panOffset: panOffset,
            geometries: selectionGeometries,
          ),
        );
      },
    );
  }
}
