import 'package:flutter/widgets.dart';

import '../constants/arcadia_color.dart';
import '../geometry/line.dart';
import 'tool.dart';

/// A tool that creates a rectangle from two of its corners
class CornersRectangleTool implements Tool {
  /// The default constructor for [CornersRectangleTool].
  const CornersRectangleTool();
  @override
  Widget get icon => const _CornersRectangleIcon();

  @override
  String get name => 'Corners rectangle';

  @override
  ShortcutActivator get shortcut => const SingleActivator(.keyT);

  @override
  ToolActionFactory get toolActionFactory => _CornersRectangleToolAction.new;
}

class _CornersRectangleToolAction extends ToolAction {
  _CornersRectangleToolAction();

  Offset? _corner1;

  @override
  void onClickUp() {
    if (_corner1 case final corner1?) {
      addGeometries(_getLines(corner1));
      clearToolGeometries();
      _corner1 = null;
    } else {
      _corner1 = state.cursorPosition;
    }
  }

  @override
  void onCursorPositionChange() {
    if (_corner1 case final corner1?) {
      clearToolGeometries();
      addToolGeometries([
        ..._getLines(corner1),
        Line(start: corner1, end: state.cursorPosition, color: .primary),
      ]);
    }
  }

  List<Line> _getLines(Offset corner1) {
    final corner3 = state.cursorPosition;
    final corner2 = Offset(corner3.dx, corner1.dy);
    final corner4 = Offset(corner1.dx, corner3.dy);

    return [
      Line(start: corner1, end: corner2, color: .primary),
      Line(start: corner2, end: corner3, color: .primary),
      Line(start: corner3, end: corner4, color: .primary),
      Line(start: corner4, end: corner1, color: .primary),
    ];
  }
}

class _CornersRectangleIcon extends StatelessWidget {
  const _CornersRectangleIcon();

  @override
  Widget build(BuildContext context) {
    final point = Container(width: 2, height: 2, color: ArcadiaColor.primary);

    return Stack(
      children: [
        Positioned(top: 0, left: 0, child: point),
        Container(
          margin: const EdgeInsets.all(1),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            border: Border.all(color: ArcadiaColor.primary),
          ),
        ),
        Positioned(bottom: 0, right: 0, child: point),
      ],
    );
  }
}
