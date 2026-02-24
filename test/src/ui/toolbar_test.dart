import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/providers/viewport_notifier_provider.dart';
import 'package:arcadia/src/tools/line_tool.dart';
import 'package:arcadia/src/tools/tools.dart';
import 'package:arcadia/src/ui/toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _line = Line(start: Offset(1, 2), end: Offset(3, 4), color: .geometry);

void main() {
  group('Toolbar', () {
    testWidgets('renders all tools with tooltip labels', (tester) async {
      await _pumpToolbar(tester);

      expect(find.byType(Tooltip), findsNWidgets(tools.length));

      final firstTooltip = tester.widget<Tooltip>(find.byType(Tooltip).first);
      expect(firstTooltip.message, contains('Line'));
      expect(firstTooltip.message, contains('L'));
    });

    testWidgets('tapping a tool toggles selection in notifier', (tester) async {
      await _pumpToolbar(tester);
      final notifier = tester.element(find.byType(Toolbar)).viewportNotifier;
      final firstButton = find
          .descendant(
            of: find.byType(Toolbar),
            matching: find.byType(GestureDetector),
          )
          .first;

      await tester.tap(firstButton);
      await tester.pump();
      expect(notifier.value.selectedTool, const LineTool());

      await tester.tap(firstButton);
      await tester.pump();
      expect(notifier.value.selectedTool, isNull);
    });

    testWidgets(
      'tool buttons do not rebuild when unrelated state slices change',
      (tester) async {
        final previousCallback = debugOnRebuildDirtyWidget;
        final rebuiltWidgets = <String>[];
        debugOnRebuildDirtyWidget = (element, builtOnce) {
          final runtimeType = element.widget.runtimeType.toString();
          if (runtimeType.contains('_ToolButton')) {
            rebuiltWidgets.add(runtimeType);
          }
        };
        addTearDown(() {
          debugOnRebuildDirtyWidget = previousCallback;
        });

        await _pumpToolbar(tester);
        final notifier = tester.element(find.byType(Toolbar)).viewportNotifier;
        rebuiltWidgets.clear();

        notifier.value = notifier.value.copyWith(
          geometries: const [_line],
          toolGeometries: const [_line],
          snappingGeometries: const [_line],
          selectionGeometries: const [_line],
          cursorPosition: const Offset(6, 7),
          userInput: '2',
        );
        await tester.pump();

        expect(rebuiltWidgets, isEmpty);
      },
    );
  });
}

Future<void> _pumpToolbar(WidgetTester tester) {
  return tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: ViewportNotifierProvider(
          child: SizedBox(width: 600, height: 60, child: Toolbar()),
        ),
      ),
    ),
  );
}
