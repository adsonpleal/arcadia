import 'package:arcadia/src/tools/measure_tool.dart';
import 'package:arcadia/src/tools/tool.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeasureTool', () {
    test('exposes metadata and action factory', () {
      const tool = MeasureTool();

      expect(tool.name, 'Measure');
      expect(tool.shortcut, const SingleActivator(.keyM));
      expect(tool.icon, isA<Widget>());
      expect(tool.toolActionFactory(), isA<ToolAction>());
    });
  });
}
