import 'dart:math';

import 'package:flutter/widgets.dart';

import '../constants/arcadia_color.dart';
import '../geometry/circle.dart';
import '../geometry/line.dart';
import 'tool.dart';

/// A tool that creates a [Circle].
class CircleTool implements Tool {
  /// The default constructor for [CircleTool].
  const CircleTool();
  @override
  Widget get icon => const _CircleToolIcon();

  @override
  String get name => 'Circle';

  @override
  ShortcutActivator get shortcut => const SingleActivator(.keyC);

  @override
  ToolActionFactory get toolActionFactory => _CircleToolAction.new;
}

class _CircleToolAction extends ToolAction {
  Offset? _center;

  double? _fixedRadius;

  @override
  bool get acceptValueInput => true;

  @override
  void onClickUp() {
    if (_center case final center?) {
      addGeometries([_getCurrentCircle(center)]);
      _center = null;
      _fixedRadius = null;
      clearToolGeometries();
    } else {
      _center = state.cursorPosition;
    }
  }

  @override
  void onCursorPositionChange() {
    _updateToolGeometries();
  }

  @override
  void onValueTyped(double? value) {
    _fixedRadius = value;
    _updateToolGeometries();
  }

  void _updateToolGeometries() {
    if (_center case final center?) {
      final cursor = state.cursorPosition;
      final Offset endPoint;

      if (_fixedRadius case final fixedRadius?) {
        final angle = (cursor - center).direction;
        endPoint =
            center + Offset(fixedRadius * cos(angle), fixedRadius * sin(angle));
      } else {
        endPoint = cursor;
      }

      clearToolGeometries();
      addToolGeometries([
        _getCurrentCircle(center),
        Line(start: center, end: endPoint, color: .primary),
      ]);
    }
  }

  Circle _getCurrentCircle(Offset center) {
    return Circle(
      center: center,
      color: .primary,
      radius: _fixedRadius ?? (state.cursorPosition - center).distance,
    );
  }
}

class _CircleToolIcon extends StatelessWidget {
  const _CircleToolIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: const ShapeDecoration(
        shape: CircleBorder(side: BorderSide(color: ArcadiaColor.primary)),
      ),
    );
  }
}
