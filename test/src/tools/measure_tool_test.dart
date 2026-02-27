import 'package:arcadia/src/constants/config.dart';
import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/logic/viewport_notifier.dart';
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

    test('shows running polyline length without committing geometry', () {
      final notifier = ViewportNotifier()..selectTool(const MeasureTool());

      _moveCursor(notifier, const Offset(10, 10));
      notifier.onCursorClickUp();
      _moveCursor(notifier, const Offset(20, 10));

      final firstPreview = notifier.value.toolGeometries.single as Line;
      expect(firstPreview.start, const Offset(10, 10));
      expect(firstPreview.end, const Offset(20, 10));
      expect(notifier.value.measureLabel, 'Length: 10.0 mm');
      expect(notifier.value.geometries, isEmpty);

      notifier.onCursorClickUp();
      _moveCursor(notifier, const Offset(20, 20));

      final chainedPreview = notifier.value.toolGeometries.whereType<Line>().toList();
      expect(chainedPreview, hasLength(2));
      expect(chainedPreview.first.start, const Offset(10, 10));
      expect(chainedPreview.first.end, const Offset(20, 10));
      expect(chainedPreview.last.start, const Offset(20, 10));
      expect(chainedPreview.last.end, const Offset(20, 20));
      expect(notifier.value.measureLabel, 'Length: 20.0 mm');
      expect(notifier.value.geometries, isEmpty);
    });
  });
}

void _moveCursor(ViewportNotifier notifier, Offset cursorPosition) {
  notifier.onCursorMove(
    viewportPosition: cursorPosition * unitVirtualPixelRatio,
    viewportMidPoint: .zero,
  );
}
