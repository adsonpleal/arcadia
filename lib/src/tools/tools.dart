import 'arc_tool.dart';
import 'center_rectangle_tool.dart';
import 'circle_tool.dart';
import 'corners_rectangle_tool.dart';
import 'line_tool.dart';
import 'measure_tool.dart';
import 'selection_tool.dart';
import 'tool.dart';

/// The tools that will be displayed in the toolbar.
///
/// The order is important.
const tools = <Tool>[
  SelectionTool(),
  LineTool(),
  MeasureTool(),
  ArcTool(),
  CircleTool(),
  CenterRectangleTool(),
  CornersRectangleTool(),
];
