import 'package:flutter/material.dart';

import '../providers/viewport_notifier_provider.dart';
import 'viewport_painter.dart';

// TODO: Add tests.
// this file depends on both flutter and macro stuff, so we can't test
// it for now.

/// The paint for the tool geometries.
class ToolViewportPaint extends StatelessWidget {
  /// The default constructor for [ToolViewportPaint].
  const ToolViewportPaint({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ViewportStateBuilder(
      select: (state) => (
        state.zoom,
        state.panOffset,
        state.toolGeometries,
      ),
      builder: (context, value) {
        final (zoom, panOffset, toolGeometries) = value;

        return CustomPaint(
          painter: ViewportPainter(
            zoom: zoom,
            panOffset: panOffset,
            geometries: toolGeometries,
          ),
        );
      },
    );
  }
}
