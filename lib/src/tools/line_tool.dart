import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/arcadia_color.dart';
import '../geometry/line.dart';
import 'tool.dart';

/// A tool that creates a line between two given points.
class LineTool implements Tool {
  /// The default constructor for [LineTool].
  const LineTool();

  @override
  String get name => 'Line';

  @override
  ShortcutActivator get shortcut => const SingleActivator(.keyL);

  @override
  Widget get icon => const _LineToolIcon();

  @override
  ToolActionFactory get toolActionFactory => _LineToolAction.new;
}

class _LineToolAction extends ToolAction {
  Offset? _firstPoint;

  double? _fixedLength;

  @override
  bool get acceptValueInput => true;

  @override
  void onCursorPositionChange() {
    _updateToolGeometry();
  }

  @override
  void onClickUp() {
    if (_firstPoint case final point?) {
      final endPoint = _getEndPoint();
      addGeometries([Line(color: .primary, start: point, end: endPoint)]);
      _firstPoint = endPoint;
    } else {
      _firstPoint = state.cursorPosition;
    }
    if (_firstPoint case final point?) {
      addSnapPoint(point);
    }
    _fixedLength = null;
    clearUserInput();
  }

  @override
  void onValueTyped(double? value) {
    _fixedLength = value;
    _updateToolGeometry();
  }

  Offset _getEndPoint() {
    if (_firstPoint case final point?) {
      final cursor = state.cursorPosition;
      if (_fixedLength case final fixedLength?) {
        final angle = (cursor - point).direction;

        return point +
            Offset(fixedLength * cos(angle), fixedLength * sin(angle));
      } else {
        return cursor;
      }
    } else {
      return .zero;
    }
  }

  void _updateToolGeometry() {
    if (_firstPoint case final point?) {
      clearToolGeometries();
      addToolGeometries([
        Line(color: .primary, start: point, end: _getEndPoint()),
      ]);
    }
  }
}

class _LineToolIcon extends StatelessWidget {
  const _LineToolIcon();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -pi / 4,
      child: Container(width: 20, height: 1, color: ArcadiaColor.primary),
    );
  }
}
