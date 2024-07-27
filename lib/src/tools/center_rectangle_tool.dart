import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../constants/arcadia_colors.dart';
import '../geometry/line.dart';
import 'tool.dart';

/// A tool that creates a rectangle from its center and a corner.
class CenterRectangleTool implements Tool {
  /// The default constructor for [CenterRectangleTool].
  const CenterRectangleTool();
  @override
  Widget get icon => const _CenterRectangleIcon();

  @override
  String get name => 'Center rectangle';

  @override
  ShortcutActivator get shortcut => const SingleActivator(
        LogicalKeyboardKey.keyR,
      );

  @override
  ToolActionFactory get toolActionFactory => _CenterRectangleToolAction.new;
}

class _CenterRectangleToolAction extends ToolAction {
  _CenterRectangleToolAction();

  Offset? _center;

  @override
  void onClick() {
    if (_center case final center?) {
      addGeometries(_getLines(center));
      clearToolGeometries();
      _center = null;
    } else {
      _center = state.cursorPosition;
    }
  }

  @override
  void onCursorPositionChange() {
    if (_center case final center?) {
      clearToolGeometries();
      addToolGeometries([
        ..._getLines(center),
        Line(
          start: center,
          end: state.cursorPosition,
          color: ArcadiaColors.geometry,
        ),
      ]);
    }
  }

  List<Line> _getLines(Offset center) {
    final corner1 = state.cursorPosition;
    final cornerDelta = corner1 - center;

    final corner2 = Offset(cornerDelta.dx * -1, cornerDelta.dy) + center;
    final corner3 = cornerDelta * -1 + center;
    final corner4 = Offset(cornerDelta.dx, cornerDelta.dy * -1) + center;

    return [
      Line(
        start: corner1,
        end: corner2,
        color: ArcadiaColors.geometry,
      ),
      Line(
        start: corner2,
        end: corner3,
        color: ArcadiaColors.geometry,
      ),
      Line(
        start: corner3,
        end: corner4,
        color: ArcadiaColors.geometry,
      ),
      Line(
        start: corner4,
        end: corner1,
        color: ArcadiaColors.geometry,
      ),
    ];
  }
}

class _CenterRectangleIcon extends StatelessWidget {
  const _CenterRectangleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border.all(
          color: ArcadiaColors.geometry,
        ),
      ),
      child: Center(
        child: Container(
          width: 2,
          height: 2,
          color: ArcadiaColors.geometry,
        ),
      ),
    );
  }
}
