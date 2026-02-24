import 'package:arcadia/src/constants/config.dart';
import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/logic/viewport_notifier.dart';
import 'package:arcadia/src/tools/line_tool.dart';
import 'package:arcadia/src/tools/tool.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LineTool', () {
    test('exposes metadata and action factory', () {
      const tool = LineTool();

      expect(tool.name, 'Line');
      expect(tool.shortcut, const SingleActivator(LogicalKeyboardKey.keyL));
      expect(tool.icon, isA<Widget>());
      expect(tool.toolActionFactory(), isA<ToolAction>());
    });

    test('creates preview and commits chained lines on clicks', () {
      final notifier = ViewportNotifier()..selectTool(const LineTool());

      _moveCursor(notifier, const Offset(10, 10));
      notifier.onCursorClick();
      _moveCursor(notifier, const Offset(20, 10));

      final preview = notifier.value.toolGeometries.single as Line;
      expect(preview.start, const Offset(10, 10));
      expect(preview.end, const Offset(20, 10));

      notifier.onCursorClick();

      final committed = notifier.value.geometries.single as Line;
      expect(committed.start, const Offset(10, 10));
      expect(committed.end, const Offset(20, 10));
      expect(notifier.value.userInput, isEmpty);

      _moveCursor(notifier, const Offset(30, 10));
      final chainedPreview = notifier.value.toolGeometries.single as Line;
      expect(chainedPreview.start, const Offset(20, 10));
      expect(chainedPreview.end, const Offset(30, 10));
    });

    test('uses typed value as fixed line length', () {
      final notifier = ViewportNotifier()..selectTool(const LineTool());

      _moveCursor(notifier, const Offset(10, 0));
      notifier.onCursorClick();
      _moveCursor(notifier, const Offset(20, 0));

      notifier.onUserInput('5');
      expect(notifier.value.userInput, '5');

      notifier.onCursorClick();

      final line = notifier.value.geometries.single as Line;
      expect(line.start, const Offset(10, 0));
      expect(line.end.dx, closeTo(15, 0.0001));
      expect(line.end.dy, closeTo(0, 0.0001));
      expect(notifier.value.userInput, isEmpty);

      _moveCursor(notifier, const Offset(30, 0));
      final nextPreview = notifier.value.toolGeometries.single as Line;
      expect(nextPreview.start.dx, closeTo(15, 0.0001));
      expect(nextPreview.end.dx, closeTo(30, 0.0001));
    });
  });
}

void _moveCursor(ViewportNotifier notifier, Offset cursorPosition) {
  notifier.onCursorMove(
    viewportPosition: cursorPosition * unitVirtualPixelRatio,
    viewportMidPoint: Offset.zero,
  );
}
