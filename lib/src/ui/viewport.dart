import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../constants/arcadia_color.dart';
import '../providers/viewport_notifier_provider.dart';
import 'cursor_paint.dart';
import 'grid_paint.dart';
import 'selection_paint.dart';
import 'snapping_viewport_paint.dart';
import 'tool_viewport_paint.dart';
import 'viewport_overlay.dart';
import 'viewport_paint.dart';

/// The viewport with the viewport painter and listener.
class Viewport extends StatelessWidget {
  /// The default [Viewport] constructor.
  const Viewport({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.viewportNotifier;

    void onPointerMovement(PointerEvent event) {
      if (context.size case final size?) {
        notifier.onCursorMove(
          viewportPosition: event.localPosition,
          viewportMidPoint: Offset(size.width, size.height) / 2,
        );
      }
    }

    return Listener(
      onPointerSignal: (event) {
        switch (event) {
          case PointerScrollEvent(scrollDelta: final scrollDelta):
            notifier.onPan(-scrollDelta);
          case PointerScaleEvent(scale: final scale):
            notifier.onZoom(scale);
        }
      },
      onPointerMove: onPointerMovement,
      onPointerHover: onPointerMovement,
      onPointerDown: (_) {
        notifier.onCursorClickDown();
      },
      onPointerUp: (_) {
        notifier.onCursorClickUp();
      },
      onPointerCancel: (_) => notifier.onCursorCancel(),
      child: const ClipRRect(
        child: ColoredBox(
          color: ArcadiaColor.background,
          child: Stack(
            children: [
              Positioned.fill(child: GridPaint()),
              Positioned.fill(child: SelectionPaint()),
              Positioned.fill(child: ViewportPaint()),
              Positioned.fill(child: SnappingViewportPaint()),
              Positioned.fill(child: ToolViewportPaint()),
              Positioned.fill(child: CursorPaint()),
              Positioned.fill(child: ViewportOverlay()),
            ],
          ),
        ),
      ),
    );
  }
}
