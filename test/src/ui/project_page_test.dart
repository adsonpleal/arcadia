import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/logic/viewport_notifier.dart';
import 'package:arcadia/src/providers/viewport_notifier_provider.dart';
import 'package:arcadia/src/tools/line_tool.dart';
import 'package:arcadia/src/ui/project_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _lineA = Line(start: .zero, end: Offset(1, 0), color: .geometry);
const _lineB = Line(start: Offset(2, 0), end: Offset(3, 0), color: .geometry);

void main() {
  group('ProjectPage', () {
    testWidgets('keyboard shortcuts select and cancel active tool', (
      tester,
    ) async {
      final notifier = await _pumpProjectPage(tester);

      await tester.sendKeyEvent(.keyL);
      await tester.pump();
      expect(notifier.value.selectedTool, const LineTool());

      await tester.sendKeyEvent(.escape);
      await tester.pump();
      expect(notifier.value.selectedTool, isNull);
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

    testWidgets('undo and redo shortcuts trigger notifier history actions', (
      tester,
    ) async {
      final notifier = await _pumpProjectPage(tester);

      notifier
        ..addGeometries(const [_lineA])
        ..addGeometries(const [_lineB]);
      await tester.pump();
      expect(notifier.value.geometries, const [_lineA, _lineB]);

      await _sendControlCombo(tester, .keyZ);
      await tester.pump();
      expect(notifier.value.geometries, const [_lineA]);

      await _sendControlCombo(tester, .keyZ, withShift: true);
      await tester.pump();
      expect(notifier.value.geometries, const [_lineA, _lineB]);
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
