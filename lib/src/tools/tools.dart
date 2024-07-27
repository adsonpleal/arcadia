import 'arc_tool.dart';
import 'center_rectangle_tool.dart';
import 'circle_tool.dart';
import 'line_tool.dart';
import 'tool.dart';

// TODO: Add tests.
// this file depends on both flutter and macro stuff, so we can't test
// it for now.

/// The tools that will be displayed in the toolbar.
///
/// The order is important.
const tools = <Tool>[
  LineTool(),
  ArcTool(),
  CircleTool(),
  CenterRectangleTool(),
];
