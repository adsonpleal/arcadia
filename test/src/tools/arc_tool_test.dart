import 'package:arcadia/src/constants/config.dart';
import 'package:arcadia/src/geometry/arc.dart';
import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/logic/viewport_notifier.dart';
import 'package:arcadia/src/tools/arc_tool.dart';
import 'package:arcadia/src/tools/tool.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArcTool', () {
    test('exposes metadata and action factory', () {
      const tool = ArcTool();

      expect(tool.name, 'Arc');
      expect(tool.shortcut, const SingleActivator(.keyA));
      expect(tool.icon, isA<Widget>());
      expect(tool.toolActionFactory(), isA<ToolAction>());
    });

    test(
      'builds guide line and guide arc before committing arc on third click',
      () {
        final notifier = ViewportNotifier()..selectTool(const ArcTool());

        _moveCursor(notifier, .zero);
        notifier.onCursorClickUp();
        _moveCursor(notifier, const Offset(10, 0));

        expect(notifier.value.toolGeometries.single, isA<Line>());

        notifier.onCursorClickUp();
        _moveCursor(notifier, const Offset(0, 10));

        expect(notifier.value.toolGeometries.single, isA<Arc>());

        notifier.onCursorClickUp();

        expect(
          [for (final layer in notifier.value.layers) ...layer.geometries]
              .single,
          isA<Arc>(),
        );

        _moveCursor(notifier, const Offset(5, 5));
        expect(notifier.value.toolGeometries, isEmpty);
      },
    );
  });
}

void _moveCursor(ViewportNotifier notifier, Offset cursorPosition) {
  notifier.onCursorMove(
    viewportPosition: cursorPosition * unitVirtualPixelRatio,
    viewportMidPoint: .zero,
  );
}
