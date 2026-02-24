import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../constants/arcadia_color.dart';
import '../constants/config.dart';
import '../providers/viewport_notifier_provider.dart';

/// The painter for the cursor.
///
/// This is separated from geometry painting to avoid redrawing when there
/// is cursor movement without geometry changes.
class CursorPaint extends StatelessWidget {
  /// The default [CursorPaint] constructor.
  const CursorPaint({super.key});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.none,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final (cursorPosition, zoom, panOffset) = context.selectViewportState(
            (state) => (
              state.cursorPosition * unitVirtualPixelRatio,
              state.zoom,
              state.panOffset,
            ),
          );

          final viewportMidpoint = Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2,
          );
          final viewportOffset = viewportMidpoint + panOffset;
          final viewportPosition = (cursorPosition * zoom) + viewportOffset;

          return RepaintBoundary(
            child: CustomPaint(
              painter: _CursorPainter(viewportPosition: viewportPosition),
            ),
          );
        },
      ),
    );
  }
}

const _cursorSize = 40.0;
const _cursorHalfSize = _cursorSize / 2;

class _CursorPainter extends CustomPainter {
  _CursorPainter({required this.viewportPosition});

  final Offset viewportPosition;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ArcadiaColor.cursor
      ..style = .stroke
      ..strokeWidth = 1;

    final cursorPath = Path()
      ..moveTo(viewportPosition.dx, viewportPosition.dy)
      ..relativeMoveTo(0, -_cursorHalfSize)
      ..relativeLineTo(0, _cursorSize)
      ..relativeMoveTo(-_cursorHalfSize, -_cursorHalfSize)
      ..relativeLineTo(_cursorSize, 0);

    canvas.drawPath(cursorPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CursorPainter oldDelegate) {
    return viewportPosition != oldDelegate.viewportPosition;
  }
}
