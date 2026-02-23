import 'package:flutter/material.dart';

import '../providers/viewport_notifier_provider.dart';
import 'viewport_painter.dart';

// TODO: Add tests.
// this file depends on both flutter and macro stuff, so we can't test
// it for now.

/// The paint of the viewport.
///
/// This widget renders the geometries.
class ViewportPaint extends StatelessWidget {
  /// The default [ViewportPaint] constructor.
  const ViewportPaint({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewportStateBuilder(
      // Only rebuild if zoom or panOffset or geometries change.
      select: (state) => (state.zoom, state.panOffset, state.geometries),
      builder: (context, value) {
        final (zoom, panOffset, geometries) = value;

        return CustomPaint(
          painter: ViewportPainter(
            zoom: zoom,
            panOffset: panOffset,
            geometries: geometries,
          ),
        );
      },
    );
  }
}
