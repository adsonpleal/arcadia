import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../constants/arcadia_colors.dart';
import '../constants/config.dart';
import '../providers/viewport_notifier_provider.dart';

/// The grid widget.
///
/// Paints a grid with infinite vertical and horizontal lines.
class GridPaint extends StatelessWidget {
  /// Default constructor for [GridPaint].
  const GridPaint({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewportStateBuilder(
      select: (state) => (
        state.panOffset,
        state.zoom,
      ),
      builder: (context, state) {
        final (panOffset, zoom) = state;

        return CustomPaint(
          painter: _GridPainter(
            zoom: zoom,
            panOffset: panOffset,
          ),
        );
      },
    );
  }
}

const _gridSquareSize = 10;
const _gridDistance = _gridSquareSize * unitVirtualPixelRatio;

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.zoom,
    required this.panOffset,
  });

  final double zoom;
  final Offset panOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final distance = _gridDistance /
        pow(
          _gridSquareSize,
          (log(zoom) / log(_gridSquareSize)).floor(),
        );
    final viewportMidpoint = Offset(size.width, size.height) / 2;
    final viewportOffset = viewportMidpoint + panOffset;
    final space = distance * zoom;
    final dxStart = -viewportOffset.dx ~/ space;
    final dxEnd = dxStart + size.width ~/ space + 2;
    final dyStart = -viewportOffset.dy ~/ space;
    final dyEnd = dyStart + size.height ~/ space + 2;

    final paint = Paint()
      ..color = ArcadiaColors.grid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = dxStart; i < dxEnd; i++) {
      final dx = (i * distance * zoom) + viewportOffset.dx;
      canvas.drawLine(
        Offset(dx, 0),
        Offset(dx, size.height),
        paint,
      );
    }

    for (var i = dyStart; i < dyEnd; i++) {
      final dy = (i * distance * zoom) + viewportOffset.dy;
      canvas.drawLine(
        Offset(0, dy),
        Offset(size.width, dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return zoom != oldDelegate.zoom || panOffset != oldDelegate.panOffset;
  }
}
