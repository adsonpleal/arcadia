import 'package:arcadia/src/tools/arc_tool.dart';
import 'package:arcadia/src/tools/center_rectangle_tool.dart';
import 'package:arcadia/src/tools/circle_tool.dart';
import 'package:arcadia/src/tools/corners_rectangle_tool.dart';
import 'package:arcadia/src/tools/line_tool.dart';
import 'package:arcadia/src/tools/tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tools', () {
    test('contains all available tools in expected order', () {
      expect(tools.map((tool) => tool.runtimeType).toList(), [
        LineTool,
        ArcTool,
        CircleTool,
        CenterRectangleTool,
        CornersRectangleTool,
      ]);
    });

    test('has unique tool names and shortcuts', () {
      final names = tools.map((tool) => tool.name).toSet();
      final shortcuts = tools.map((tool) => tool.shortcut).toSet();

      expect(names.length, tools.length);
      expect(shortcuts.length, tools.length);
    });
  });
}
