import 'package:arcadia/src/geometry/geometry.dart';
import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/logic/viewport_notifier.dart';
import 'package:arcadia/src/providers/viewport_notifier_provider.dart';
import 'package:arcadia/src/tools/circle_tool.dart';
import 'package:arcadia/src/tools/line_tool.dart';
import 'package:arcadia/src/tools/measure_tool.dart';
import 'package:arcadia/src/tools/selection_tool.dart';
import 'package:arcadia/src/ui/layers_panel.dart';
import 'package:arcadia/src/ui/project_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _lineA = Line(start: .zero, end: Offset(1, 0), color: .primary);
const _lineB = Line(start: Offset(2, 0), end: Offset(3, 0), color: .primary);

void main() {
  group('ProjectPage', () {
    testWidgets('layers panel is present in layout', (tester) async {
      await _pumpProjectPage(tester);

      expect(find.byType(LayersPanel), findsOneWidget);
    });

    testWidgets('keyboard shortcuts select and cancel active tool', (
      tester,
    ) async {
      final notifier = await _pumpProjectPage(tester);

      expect(notifier.value.selectedTool, const SelectionTool());

      await tester.sendKeyEvent(.keyL);
      await tester.pump();
      expect(notifier.value.selectedTool, const LineTool());

      await tester.sendKeyEvent(.escape);
      await tester.pump();
      expect(notifier.value.selectedTool, const SelectionTool());
    });

    testWidgets('keyboard value input updates active tool input', (
      tester,
    ) async {
      final notifier = await _pumpProjectPage(tester);

      await tester.sendKeyEvent(.keyL);
      await tester.sendKeyEvent(.digit1);
      await tester.sendKeyEvent(.period);
      await tester.sendKeyEvent(.digit2);
      await tester.sendKeyEvent(.backspace);
      await tester.pump();

      expect(notifier.value.userInput, '1.');
    });

    testWidgets('C still selects Circle when value input is empty', (
      tester,
    ) async {
      final notifier = await _pumpProjectPage(tester);

      await tester.sendKeyEvent(.keyC);
      await tester.pump();

      expect(notifier.value.selectedTool, const CircleTool());
    });

    testWidgets('M selects Measure when value input is empty', (tester) async {
      final notifier = await _pumpProjectPage(tester);

      await tester.sendKeyEvent(.keyM);
      await tester.pump();

      expect(notifier.value.selectedTool, const MeasureTool());
    });

    testWidgets(
      'C/M append but trailing space is rejected after complete unit',
      (tester) async {
        final notifier = await _pumpProjectPage(tester);

        await tester.sendKeyEvent(.keyL);
        await tester.sendKeyEvent(.digit1);
        await tester.sendKeyEvent(.keyC);
        await tester.sendKeyEvent(.keyM);
        await tester.sendKeyEvent(.space);
        await tester.pump();

        expect(notifier.value.userInput, '1cm');
      },
    );

    testWidgets(
      'M appends to active value input instead of selecting Measure',
      (tester) async {
        final notifier = await _pumpProjectPage(tester);

        await tester.sendKeyEvent(.keyL);
        await tester.sendKeyEvent(.digit1);
        await tester.sendKeyEvent(.keyM);
        await tester.pump();

        expect(notifier.value.selectedTool, const LineTool());
        expect(notifier.value.userInput, '1m');
      },
    );

    testWidgets('undo and redo shortcuts trigger notifier history actions', (
      tester,
    ) async {
      final notifier = await _pumpProjectPage(tester);

      List<Geometry> allGeometries() => [
        for (final layer in notifier.value.layers) ...layer.geometries,
      ];

      notifier
        ..addGeometries(const [_lineA])
        ..addGeometries(const [_lineB]);
      await tester.pump();
      expect(allGeometries(), const [_lineA, _lineB]);

      await _sendControlCombo(tester, .keyZ);
      await tester.pump();
      expect(allGeometries(), const [_lineA]);

      await _sendControlCombo(tester, .keyZ, withShift: true);
      await tester.pump();
      expect(allGeometries(), const [_lineA, _lineB]);
    });

    testWidgets('escape clears tool preview and switches to selection tool', (
      tester,
    ) async {
      final notifier = await _pumpProjectPage(tester);
      notifier
        ..addGeometries(const [_lineA])
        ..value = notifier.value.copyWith(
          cursorPosition: const Offset(0.5, 0),
        )
        ..onCursorClickUp();
      await tester.pump();
      expect(notifier.value.toolGeometries, isNotEmpty);

      await tester.sendKeyEvent(.escape);
      await tester.pump();

      expect(notifier.value.selectedTool, const SelectionTool());
      expect(notifier.value.toolGeometries, isEmpty);
    });
  });
}

Future<ViewportNotifier> _pumpProjectPage(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: .windows),
      home: const Scaffold(
        body: ViewportNotifierProvider(child: ProjectPage()),
      ),
    ),
  );

  await tester.pumpAndSettle();
  return tester.element(find.byType(ProjectPage)).viewportNotifier;
}

Future<void> _sendControlCombo(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool withShift = false,
}) async {
  await tester.sendKeyDownEvent(.controlLeft);
  if (withShift) {
    await tester.sendKeyDownEvent(.shiftLeft);
  }

  await tester.sendKeyDownEvent(key);
  await tester.sendKeyUpEvent(key);

  if (withShift) {
    await tester.sendKeyUpEvent(.shiftLeft);
  }
  await tester.sendKeyUpEvent(.controlLeft);
}
