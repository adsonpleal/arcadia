// ignore_for_file: cascade_invocations

import 'package:arcadia/src/constants/arcadia_color.dart';
import 'package:arcadia/src/constants/config.dart';
import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/geometry/point.dart';
import 'package:arcadia/src/logic/viewport_notifier.dart';
import 'package:arcadia/src/tools/line_tool.dart';
import 'package:arcadia/src/tools/tool.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _lineA = Line(start: .zero, end: Offset(10, 0), color: .primary);
const _lineB = Line(start: Offset(20, 0), end: Offset(30, 0), color: .primary);
const _lineC = Line(start: Offset(40, 0), end: Offset(50, 0), color: .primary);

void main() {
  group('ViewportNotifier', () {
    test('selectTool clears selection and tool geometries', () {
      final notifier = ViewportNotifier();

      notifier.addGeometries(const [_lineA]);
      _moveCursor(notifier, const Offset(5, 0));
      notifier.onCursorClickUp();
      _moveCursor(notifier, const Offset(100, 100));
      notifier.addToolGeometries(const [_lineB]);

      notifier.selectTool(const LineTool());

      expect(notifier.value.selectedTool, const LineTool());
      expect(notifier.value.selectionGeometries, isEmpty);
      expect(notifier.value.toolGeometries, isEmpty);
    });

    test('cancelToolAction resets selected tool, previews, and input', () {
      final notifier = ViewportNotifier()..selectTool(const LineTool());

      _moveCursor(notifier, .zero);
      notifier.onCursorClickUp();
      _moveCursor(notifier, const Offset(10, 0));
      notifier.onUserInput('5');

      expect(notifier.value.toolGeometries, isNotEmpty);
      expect(notifier.value.userInput, '5');

      notifier.cancelToolAction();

      expect(notifier.value.selectedTool, isNull);
      expect(notifier.value.toolGeometries, isEmpty);
      expect(notifier.value.selectionGeometries, isEmpty);
      expect(notifier.value.userInput, isEmpty);
    });

    test(
      'onPan updates pan, cursor position, and notifies active tool action',
      () {
        final action = _SpyToolAction();
        final notifier = ViewportNotifier();

        notifier.selectTool(_SpyTool(action));
        notifier.value = notifier.value.copyWith(
          cursorPosition: const Offset(2, 2),
        );

        notifier.onPan(const Offset(10, -5));

        expect(notifier.value.panOffset, const Offset(10, -5));
        expect(notifier.value.cursorPosition.dx, closeTo(0, 0.0001));
        expect(notifier.value.cursorPosition.dy, closeTo(3, 0.0001));
        expect(action.cursorPositionChangeCalls, 1);
      },
    );

    test('onZoom updates zoom and keeps cursor anchored in viewport', () {
      final notifier = ViewportNotifier();
      notifier.value = notifier.value.copyWith(
        zoom: 1,
        panOffset: const Offset(10, 20),
        cursorPosition: const Offset(2, 3),
      );

      notifier.onZoom(2);

      expect(notifier.value.zoom, 2);
      expect(notifier.value.panOffset.dx, closeTo(0, 0.0001));
      expect(notifier.value.panOffset.dy, closeTo(5, 0.0001));
    });

    test('onZoom clamps minimum zoom to 1%', () {
      final notifier = ViewportNotifier();

      notifier.onZoom(0.001);

      expect(notifier.value.zoom, 0.01);
    });

    test('onZoom clamps maximum zoom to 1000%', () {
      final notifier = ViewportNotifier();

      notifier.onZoom(20);

      expect(notifier.value.zoom, 10);
    });

    test('resetZoomToDefault keeps viewport center anchored', () {
      final notifier = ViewportNotifier();
      notifier.value = notifier.value.copyWith(
        zoom: 2,
        panOffset: const Offset(10, 20),
        cursorPosition: const Offset(5, 6),
      );

      final before = notifier.value;
      final beforeCenterPoint = -before.panOffset / before.zoom;

      notifier.resetZoomToDefault();

      expect(notifier.value.zoom, 1);
      expect(notifier.value.panOffset.dx, closeTo(5, 0.0001));
      expect(notifier.value.panOffset.dy, closeTo(10, 0.0001));
      expect(notifier.value.cursorPosition, const Offset(5, 6));

      final after = notifier.value;
      final afterCenterPoint = -after.panOffset / after.zoom;
      expect(afterCenterPoint.dx, closeTo(beforeCenterPoint.dx, 0.0001));
      expect(afterCenterPoint.dy, closeTo(beforeCenterPoint.dy, 0.0001));
    });

    test(
      'onCursorMove snaps to geometry snapping points when tool is active',
      () {
        final notifier = ViewportNotifier()
          ..addGeometries(const [_lineA])
          ..selectTool(const LineTool());

        _moveCursor(notifier, const Offset(11, 0));

        expect(notifier.value.cursorPosition, const Offset(10, 0));
        expect(notifier.value.snappingGeometries.single, isA<Point>());

        final snapPoint = notifier.value.snappingGeometries.single as Point;
        expect(snapPoint.position, const Offset(10, 0));
      },
    );

    test('onCursorMove applies orthogonal snapping from last snaps', () {
      final notifier = ViewportNotifier()
        ..selectTool(const LineTool())
        ..addSnapPoint(const Offset(2, 3));

      _moveCursor(notifier, const Offset(2.5, 10));

      expect(notifier.value.cursorPosition.dx, closeTo(2, 0.0001));
      expect(notifier.value.cursorPosition.dy, closeTo(10, 0.0001));
      expect(notifier.value.snappingGeometries.single, isA<Line>());

      final snapLine = notifier.value.snappingGeometries.single as Line;
      expect(snapLine.start, const Offset(2, 3));
      expect(snapLine.end.dx, closeTo(2, 0.0001));
      expect(snapLine.end.dy, closeTo(10, 0.0001));
      expect(snapLine.color, ArcadiaColor.accentActive);
    });

    test(
      'onCursorClickUp toggles selected geometries when no tool is active',
      () {
        final notifier = ViewportNotifier()..addGeometries(const [_lineA]);

        _moveCursor(notifier, const Offset(5, 0));
        notifier.onCursorClickUp();
        _moveCursor(notifier, const Offset(100, 100));

        expect(notifier.value.selectionGeometries, hasLength(1));
        final selected = notifier.value.selectionGeometries.single as Line;
        expect(selected.color, ArcadiaColor.primaryActive);
        expect(selected.strokeWidth, 5);

        _moveCursor(notifier, const Offset(5, 0));
        notifier.onCursorClickUp();
        _moveCursor(notifier, const Offset(100, 100));

        expect(notifier.value.selectionGeometries, isEmpty);
      },
    );

    test('left-to-right drag uses window selection semantics', () {
      const insideLine = Line(
        start: Offset(1, 1),
        end: Offset(3, 3),
        color: .primary,
      );
      const crossingLine = Line(
        start: Offset(1, 1),
        end: Offset(20, 1),
        color: .primary,
      );
      final notifier = ViewportNotifier()
        ..addGeometries(const [insideLine, crossingLine]);

      _pointerDown(notifier, .zero);
      _moveCursor(notifier, const Offset(10, 10));
      notifier.onCursorClickUp();

      expect(notifier.value.selectionGeometries, hasLength(1));
      final selected = notifier.value.selectionGeometries.single as Line;
      expect(selected.start, insideLine.start);
      expect(selected.end, insideLine.end);
      expect(selected.color, ArcadiaColor.primaryActive);
    });

    test('right-to-left drag uses crossing selection semantics', () {
      const insideLine = Line(
        start: Offset(1, 1),
        end: Offset(3, 3),
        color: .primary,
      );
      const crossingLine = Line(
        start: Offset(1, 1),
        end: Offset(20, 1),
        color: .primary,
      );
      final notifier = ViewportNotifier()
        ..addGeometries(const [insideLine, crossingLine]);

      _pointerDown(notifier, const Offset(10, 10));
      _moveCursor(notifier, .zero);
      notifier.onCursorClickUp();

      expect(notifier.value.selectionGeometries, hasLength(2));
    });

    test('shift drag adds matches to existing selection', () {
      const first = Line(
        start: Offset(1, 1),
        end: Offset(3, 1),
        color: .primary,
      );
      const second = Line(
        start: Offset(20, 1),
        end: Offset(22, 1),
        color: .primary,
      );
      final notifier = ViewportNotifier()..addGeometries(const [first, second]);

      _moveCursor(notifier, const Offset(2, 1));
      notifier.onCursorClickUp();

      _pointerDown(notifier, const Offset(18, 0), shiftPressed: true);
      _moveCursor(notifier, const Offset(24, 4));
      notifier.onCursorClickUp();

      expect(notifier.value.selectionGeometries, hasLength(2));
    });

    test('active tool keeps priority and does not start drag selection', () {
      final action = _SpyToolAction();
      final notifier = ViewportNotifier()
        ..addGeometries(const [_lineA])
        ..selectTool(_SpyTool(action));

      _pointerDown(notifier, .zero);
      _moveCursor(notifier, const Offset(10, 10));
      notifier.onCursorClickUp();

      expect(action.clickCalls, 1);
      expect(notifier.value.selectionGeometries, isEmpty);
    });

    test(
      'onUserInput handles numbers, dot dedupe, and backspace for tools',
      () {
        final notifier = ViewportNotifier()..selectTool(const LineTool());

        notifier.onUserInput('1');
        notifier.onUserInput('.');
        notifier.onUserInput('.');
        notifier.onUserInput('2');
        notifier.onUserInput('back');

        expect(notifier.value.userInput, '1.');
      },
    );

    test('onUserInput backspace deletes selected geometries when no tool', () {
      final notifier = ViewportNotifier()
        ..addGeometries(const [_lineA, _lineB]);

      _moveCursor(notifier, const Offset(5, 0));
      notifier.onCursorClickUp();
      _moveCursor(notifier, const Offset(100, 100));

      notifier.onUserInput('back');

      expect(notifier.value.geometries, const [_lineB]);
      expect(notifier.value.selectionGeometries, isEmpty);
    });

    test(
      'undo and redo apply geometry history and clear redo after new change',
      () {
        final notifier = ViewportNotifier();

        notifier.addGeometries(const [_lineA]);
        notifier.addGeometries(const [_lineB]);
        expect(notifier.value.geometries, const [_lineA, _lineB]);

        notifier.undo();
        expect(notifier.value.geometries, const [_lineA]);

        notifier.undo();
        expect(notifier.value.geometries, isEmpty);

        notifier.redo();
        expect(notifier.value.geometries, const [_lineA]);

        notifier.redo();
        expect(notifier.value.geometries, const [_lineA, _lineB]);

        notifier.undo();
        notifier.addGeometries(const [_lineC]);
        notifier.redo();

        expect(notifier.value.geometries, const [_lineA, _lineC]);
      },
    );

    test('onCursorClickUp delegates to active tool action', () {
      final action = _SpyToolAction();
      final notifier = ViewportNotifier()..selectTool(_SpyTool(action));

      notifier.onCursorClickUp();

      expect(action.clickCalls, 1);
    });
  });
}

void _moveCursor(ViewportNotifier notifier, Offset cursorPosition) {
  final state = notifier.value;
  notifier.onCursorMove(
    viewportPosition:
        (cursorPosition * unitVirtualPixelRatio * state.zoom) + state.panOffset,
    viewportMidPoint: .zero,
  );
}

void _pointerDown(
  ViewportNotifier notifier,
  Offset cursorPosition, {
  bool shiftPressed = false,
}) {
  _moveCursor(notifier, cursorPosition);
  notifier.onCursorClickDown(shiftPressed: shiftPressed);
}

class _SpyTool implements Tool {
  const _SpyTool(this.action);

  final _SpyToolAction action;

  @override
  Widget get icon => const SizedBox.shrink();

  @override
  String get name => 'Spy';

  @override
  ShortcutActivator get shortcut => const SingleActivator(.keyS);

  @override
  ToolActionFactory get toolActionFactory =>
      () => action;
}

class _SpyToolAction extends ToolAction {
  int clickCalls = 0;
  int cursorPositionChangeCalls = 0;

  @override
  bool get acceptValueInput => true;

  @override
  void onClick() {
    clickCalls++;
  }

  @override
  void onCursorPositionChange() {
    cursorPositionChangeCalls++;
  }
}
