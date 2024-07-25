import 'package:flutter/widgets.dart';

import '../constants/arcadia_colors.dart';
import '../providers/viewport_notifier_provider.dart';
import 'viewport_paint.dart';

// TODO: Add tests.
// this file depends on both flutter and macro stuff, so we can't test
// it for now.

/// The painter for the cursor.
///
/// This is separated from [ViewportPaint] to avoid redrawing when there
/// is a cursor movement without changes to geometries.
class CursorPaint extends StatelessWidget {
  /// The default [CursorPaint] constructor.
  const CursorPaint({super.key});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.none,
      child: ViewportStateBuilder(
        select: (state) => (
          state.cursorPosition,
          state.zoom,
          state.panOffset,
        ),
        builder: (context, value) {
          final (cursorPosition, zoom, panOffset) = value;

          return CustomPaint(
            painter: _CursorPainter(
              cursorPosition: cursorPosition,
              panOffset: panOffset,
              zoom: zoom,
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
  _CursorPainter({
    required this.cursorPosition,
    required this.panOffset,
    required this.zoom,
  });

  final Offset cursorPosition;
  final Offset panOffset;
  final double zoom;

  @override
  void paint(Canvas canvas, Size size) {
    final viewportMidpoint = Offset(size.width, size.height) / 2;
    final viewportOffset = viewportMidpoint + panOffset;
    final viewportPosition = (cursorPosition * zoom) + viewportOffset;

    final paint = Paint()
      ..color = ArcadiaColors.cursor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final cursorPath = Path()
      ..moveTo(viewportPosition.dx, viewportPosition.dy)
      ..relativeMoveTo(0, -_cursorHalfSize)
      ..relativeLineTo(0, _cursorSize)
      ..relativeMoveTo(
        -_cursorHalfSize,
        -_cursorHalfSize,
      )
      ..relativeLineTo(_cursorSize, 0);

    canvas.drawPath(cursorPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CursorPainter oldDelegate) {
    return cursorPosition != oldDelegate.cursorPosition;
  }
}
