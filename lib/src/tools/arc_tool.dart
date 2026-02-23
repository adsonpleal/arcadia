import 'dart:math';

import 'package:flutter/widgets.dart';

import '../constants/arcadia_color.dart';
import '../geometry/arc.dart';
import '../geometry/line.dart';
import 'tool.dart';

// TODO: Add tests.
// this file depends on both flutter and macro stuff, so we can't test
// it for now.

/// A tool that creates lines between three points.
class ArcTool implements Tool {
  /// The default constructor for [ArcTool].
  const ArcTool();

  @override
  Widget get icon => const _ArcToolIcon();

  @override
  String get name => 'Arc';

  @override
  ShortcutActivator get shortcut => const SingleActivator(.keyA);

  @override
  ToolActionFactory get toolActionFactory => _ArcToolAction.new;
}

class _ArcToolAction extends ToolAction {
  Offset? firstPoint;
  Offset? secondPoint;

  @override
  void onClick() {
    if (firstPoint == null) {
      firstPoint = state.cursorPosition;
      return;
    }

    if (secondPoint == null) {
      secondPoint = state.cursorPosition;
      return;
    }

    addGeometries([
      Arc.fromPoints(
        first: firstPoint!,
        second: secondPoint!,
        third: state.cursorPosition,
        color: .geometry,
      ),
    ]);

    firstPoint = null;
    secondPoint = null;
  }

  @override
  void onCursorPositionChange() {
    clearToolGeometries();
    if (firstPoint != null) {
      if (secondPoint == null) {
        addToolGeometries([
          Line(start: firstPoint!, end: state.cursorPosition, color: .geometry),
        ]);
      } else {
        addToolGeometries([
          Arc.fromPoints(
            first: firstPoint!,
            second: secondPoint!,
            third: state.cursorPosition,
            color: .geometry,
          ),
        ]);
      }
    }
  }
}

class _ArcToolIcon extends StatelessWidget {
  const _ArcToolIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: CustomPaint(painter: _ArcToolIconPainter()));
  }
}

class _ArcToolIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 2.5);
    const radius = 7.0;
    final paint = Paint()
      ..strokeWidth = 1
      ..color = ArcadiaColor.geometry.color
      ..style = .stroke;
    const points = [Offset(-radius, 0), Offset(radius, 0), Offset(0, -radius)];

    canvas.drawArc(
      .fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      paint,
    );

    for (final point in points) {
      canvas.drawRect(
        .fromCenter(center: center + point, width: 3, height: 3),
        paint..style = .fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
