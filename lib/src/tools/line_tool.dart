import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/arcadia_colors.dart';
import '../geometry/line.dart';
import 'tool.dart';

// TODO: Add tests.
// this file depends on both flutter and macro stuff, so we can't test
// it for now.

/// A tool that creates a line between two given points.
class LineTool implements Tool {
  /// The default constructor for [LineTool].
  const LineTool();

  @override
  String get name => 'Line';

  @override
  ShortcutActivator get shortcut => const SingleActivator(
        LogicalKeyboardKey.keyL,
      );

  @override
  Widget get icon => const _LineToolIcon();

  @override
  ToolActionFactory get toolActionFactory => _LineToolAction.new;
}

class _LineToolAction extends ToolAction {
  Offset? _firstPoint;

  @override
  void onCursorPositionChange() {
    if (_firstPoint case final point?) {
      final cursorPosition = state.cursorPosition;

      clearToolGeometries();
      addToolGeometries([
        Line(
          color: ArcadiaColors.geometry,
          start: point,
          end: cursorPosition,
        ),
      ]);
    }
  }

  @override
  void onClick() {
    final cursorPosition = state.cursorPosition;

    if (_firstPoint case final point?) {
      addGeometries([
        Line(
          color: ArcadiaColors.geometry,
          start: point,
          end: cursorPosition,
        ),
      ]);
    }
    _firstPoint = cursorPosition;
  }
}

class _LineToolIcon extends StatelessWidget {
  const _LineToolIcon();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -pi / 4,
      child: Container(
        width: 20,
        height: 1,
        color: ArcadiaColors.geometry,
      ),
    );
  }
}
