import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../constants/arcadia_color.dart';
import '../constants/config.dart';
import '../providers/viewport_notifier_provider.dart';
import 'viewport_paint.dart';

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final (cursorPosition, zoom, panOffset, userInput) = context
              .selectViewportState(
                (state) => (
                  state.cursorPosition * unitVirtualPixelRatio,
                  state.zoom,
                  state.panOffset,
                  state.userInput,
                ),
              );

          final viewportMidpoint = Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2,
          );
          final viewportOffset = viewportMidpoint + panOffset;
          final viewportPosition = (cursorPosition * zoom) + viewportOffset;

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _CursorPainter(viewportPosition: viewportPosition),
                ),
              ),
              if (userInput != '')
                Positioned(
                  top: viewportPosition.dy - _cursorHalfSize,
                  left: viewportPosition.dx + _cursorHalfSize + 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: _cursorSize),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(maxWidth: 100),
                        decoration: ShapeDecoration(
                          color: ArcadiaColor.viewportBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: const BorderSide(
                              color: ArcadiaColor.separator,
                            ),
                          ),
                        ),
                        child: Text(userInput),
                      ),
                    ),
                  ),
                ),
            ],
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
