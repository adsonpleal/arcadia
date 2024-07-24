import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart' hide Viewport;

import '../constants/arcadia_colors.dart';
import '../providers/viewport_notifier_provider.dart';
import 'cursor_paint.dart';
import 'viewport_paint.dart';

// TODO: Add tests.
// this file depends on both flutter and macro stuff, so we can't test
// it for now.

/// The main project page.
///
/// It contains the tools, viewport and toggles/actions.
class ProjectPage extends StatelessWidget {
  /// The main [ProjectPage] constructor.
  const ProjectPage({
    super.key,
  });

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
      child: const ColoredBox(
        color: ArcadiaColors.viewportBackground,
        child: Stack(
          children: [
            Positioned.fill(
              child: ViewportPaint(),
            ),
            Positioned.fill(
              child: CursorPaint(),
            ),
          ],
        ),
      ),
    );
  }
}
