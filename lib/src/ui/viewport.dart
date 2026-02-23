import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../constants/arcadia_colors.dart';
import '../providers/viewport_notifier_provider.dart';
import 'cursor_paint.dart';
import 'grid_paint.dart';
import 'selection_paint.dart';
import 'snapping_viewport_paint.dart';
import 'tool_viewport_paint.dart';
import 'viewport_paint.dart';

// TODO: Add tests.
// this file depends on both flutter and macro stuff, so we can't test
// it for now.

/// The viewport with the viewport painter and listener.
class Viewport extends StatelessWidget {
  /// The default [Viewport] constructor.
  const Viewport({super.key});

  @override
  Widget build(BuildContext context) {
    void onPointerMovement(PointerEvent event) {
      if (context.size case final size?) {
        context.viewportNotifier.onCursorMove(
          viewportPosition: event.localPosition,
          viewportMidPoint: Offset(size.width, size.height) / 2,
        );
      }
    }

    return Listener(
      onPointerSignal: (event) {
        switch (event) {
          case PointerScrollEvent(scrollDelta: final scrollDelta):
            context.viewportNotifier.onPan(-scrollDelta);
          case PointerScaleEvent(scale: final scale):
            context.viewportNotifier.onZoom(scale);
        }
      },
      onPointerMove: onPointerMovement,
      onPointerHover: onPointerMovement,
      onPointerUp: (event) => context.viewportNotifier.onCursorClick(),
      child: const ClipRRect(
        child: ColoredBox(
          color: ArcadiaColors.viewportBackground,
          child: Stack(
            children: [
              Positioned.fill(child: GridPaint()),
              Positioned.fill(child: SelectionPaint()),
              Positioned.fill(child: ViewportPaint()),
              Positioned.fill(child: SnappingViewportPaint()),
              Positioned.fill(child: ToolViewportPaint()),
              Positioned.fill(child: CursorPaint()),
            ],
          ),
        ),
      ),
    );
  }
}
