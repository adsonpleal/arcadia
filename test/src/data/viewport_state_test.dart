import 'package:arcadia/src/data/viewport_state.dart';
import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/tools/line_tool.dart';
import 'package:flutter_test/flutter_test.dart';

const _lineA = Line(start: Offset(1, 2), end: Offset(3, 4), color: .geometry);
const _lineB = Line(start: Offset(5, 6), end: Offset(7, 8), color: .geometry);
const _lineC = Line(start: Offset(8, 7), end: Offset(6, 5), color: .geometry);
const Offset _zeroOffset = .zero;

void main() {
  group('ViewportState', () {
    test('has expected defaults', () {
      const state = ViewportState();

      expect(state.geometries, isEmpty);
      expect(state.toolGeometries, isEmpty);
      expect(state.snappingGeometries, isEmpty);
      expect(state.selectionGeometries, isEmpty);
      expect(state.zoom, 1.0);
      expect(state.panOffset, _zeroOffset);
      expect(state.cursorPosition, _zeroOffset);
      expect(state.selectedTool, isNull);
      expect(state.userInput, isEmpty);
    });

    test('copyWith updates each field', () {
      const initial = ViewportState(
        geometries: [_lineA],
        toolGeometries: [_lineB],
        snappingGeometries: [_lineC],
        selectionGeometries: [_lineA],
        zoom: 1.5,
        panOffset: Offset(10, 20),
        cursorPosition: Offset(30, 40),
        selectedTool: LineTool(),
        userInput: '100',
      );

      final updated = initial.copyWith(
        geometries: const [_lineB, _lineC],
        toolGeometries: const [_lineA],
        snappingGeometries: const [_lineA, _lineB],
        selectionGeometries: const [_lineC],
        zoom: 2.5,
        panOffset: const Offset(20, 30),
        cursorPosition: const Offset(40, 50),
        selectedTool: null,
        userInput: '200',
      );

      expect(updated.geometries, const [_lineB, _lineC]);
      expect(updated.toolGeometries, const [_lineA]);
      expect(updated.snappingGeometries, const [_lineA, _lineB]);
      expect(updated.selectionGeometries, const [_lineC]);
      expect(updated.zoom, 2.5);
      expect(updated.panOffset, const Offset(20, 30));
      expect(updated.cursorPosition, const Offset(40, 50));
      expect(updated.selectedTool, isNull);
      expect(updated.userInput, '200');
    });

    test('copyWith preserves values when omitted', () {
      const initial = ViewportState(
        geometries: [_lineA],
        toolGeometries: [_lineB],
        snappingGeometries: [_lineC],
        selectionGeometries: [_lineA],
        zoom: 1.25,
        panOffset: Offset(1, 2),
        cursorPosition: Offset(3, 4),
        selectedTool: LineTool(),
        userInput: '42',
      );

      final copied = initial.copyWith();

      expect(copied, equals(initial));
    });

    test('copyWith can explicitly clear selectedTool', () {
      const initial = ViewportState(selectedTool: LineTool());

      final cleared = initial.copyWith(selectedTool: null);

      expect(cleared.selectedTool, isNull);
    });

    test('copyWith preserves selectedTool when omitted', () {
      const tool = LineTool();
      const initial = ViewportState(selectedTool: tool);

      final copied = initial.copyWith(userInput: '10');

      expect(copied.selectedTool, same(tool));
    });

    test('uses deep equality for list fields', () {
      final geometries = [_lineA, _lineB];
      final toolGeometries = [_lineC];
      final snappingGeometries = [_lineB, _lineC];
      final selectionGeometries = [_lineA];
      final first = ViewportState(
        geometries: geometries,
        toolGeometries: toolGeometries,
        snappingGeometries: snappingGeometries,
        selectionGeometries: selectionGeometries,
      );
      final second = ViewportState(
        geometries: [...geometries],
        toolGeometries: [...toolGeometries],
        snappingGeometries: [...snappingGeometries],
        selectionGeometries: [...selectionGeometries],
      );

      expect(first, equals(second));
      expect(first.hashCode, second.hashCode);
    });

    test('hashCode uses Object.hashAll for list hashes', () {
      final geometries = [_lineA, _lineB];
      final toolGeometries = [_lineC];
      final snappingGeometries = [_lineB, _lineC];
      final selectionGeometries = [_lineA];
      final state = ViewportState(
        geometries: geometries,
        toolGeometries: toolGeometries,
        snappingGeometries: snappingGeometries,
        selectionGeometries: selectionGeometries,
        zoom: 2,
        panOffset: const Offset(1, 2),
        cursorPosition: const Offset(3, 4),
        selectedTool: const LineTool(),
        userInput: '10',
      );

      final expected = Object.hashAll([
        Object.hashAll(state.geometries),
        Object.hashAll(state.toolGeometries),
        Object.hashAll(state.snappingGeometries),
        Object.hashAll(state.selectionGeometries),
        state.zoom,
        state.panOffset,
        state.cursorPosition,
        state.selectedTool,
        state.userInput,
      ]);

      expect(state.hashCode, expected);
    });

    test('states are different when any scalar field changes', () {
      const base = ViewportState(
        zoom: 2,
        panOffset: Offset(1, 1),
        cursorPosition: Offset(2, 2),
        userInput: '1',
      );

      expect(base, isNot(equals(base.copyWith(zoom: 3))));
      expect(base, isNot(equals(base.copyWith(panOffset: const Offset(3, 3)))));
      expect(
        base,
        isNot(equals(base.copyWith(cursorPosition: const Offset(4, 4)))),
      );
      expect(base, isNot(equals(base.copyWith(userInput: '2'))));
    });

    test('states are different when any list field changes', () {
      const base = ViewportState(
        geometries: [_lineA],
        toolGeometries: [_lineB],
        snappingGeometries: [_lineC],
        selectionGeometries: [_lineA],
      );

      expect(base, isNot(equals(base.copyWith(geometries: const [_lineB]))));
      expect(
        base,
        isNot(equals(base.copyWith(toolGeometries: const [_lineC]))),
      );
      expect(
        base,
        isNot(equals(base.copyWith(snappingGeometries: const [_lineA]))),
      );
      expect(
        base,
        isNot(equals(base.copyWith(selectionGeometries: const [_lineB]))),
      );
    });
  });
}
