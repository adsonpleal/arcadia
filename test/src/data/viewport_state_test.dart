// test/src/data/viewport_state_test.dart
import 'package:arcadia/src/data/layer.dart';
import 'package:arcadia/src/data/metric_unit.dart';
import 'package:arcadia/src/data/viewport_state.dart';
import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/tools/line_tool.dart';
import 'package:arcadia/src/tools/selection_tool.dart';
import 'package:arcadia/src/tools/tool.dart';
import 'package:flutter_test/flutter_test.dart';

const _lineA = Line(start: Offset(1, 2), end: Offset(3, 4), color: .primary);
const _lineB = Line(start: Offset(5, 6), end: Offset(7, 8), color: .primary);
const _lineC = Line(start: Offset(8, 7), end: Offset(6, 5), color: .primary);
const Offset _zeroOffset = .zero;

const _defaultLayer = Layer(id: '0', name: 'Layer 0');
const _layerWithGeometry = Layer(
  id: '0',
  name: 'Layer 0',
  geometries: [_lineA],
);
const _secondLayer = Layer(id: '1', name: 'Layer 1');

void main() {
  group('ViewportState', () {
    test('has expected defaults', () {
      const state = ViewportState();

      expect(state.layers, const [_defaultLayer]);
      expect(state.activeLayerId, '0');
      expect(state.toolGeometries, isEmpty);
      expect(state.snappingGeometries, isEmpty);
      expect(state.zoom, 1.0);
      expect(state.panOffset, _zeroOffset);
      expect(state.cursorPosition, _zeroOffset);
      expect(state.selectedTool, const SelectionTool());
      expect(state.selectedUnit, MetricUnit.mm);
      expect(state.overlayLabel, isNull);
      expect(state.userInput, isEmpty);
    });

    test('copyWith updates each field', () {
      const initial = ViewportState(
        layers: [_layerWithGeometry],
        activeLayerId: '0',
        toolGeometries: [_lineB],
        snappingGeometries: [_lineC],
        zoom: 1.5,
        panOffset: Offset(10, 20),
        cursorPosition: Offset(30, 40),
        selectedTool: LineTool(),
        overlayLabel: 'Length: 10.0 mm',
        userInput: '100',
      );

      final updated = initial.copyWith(
        layers: const [_layerWithGeometry, _secondLayer],
        activeLayerId: '1',
        toolGeometries: const [_lineA],
        snappingGeometries: const [_lineA, _lineB],
        zoom: 2.5,
        panOffset: const Offset(20, 30),
        selectedTool: const SelectionTool(),
        selectedUnit: MetricUnit.cm,
        overlayLabel: 'Length: 1.0 cm',
        userInput: '200',
      );

      expect(updated.layers, const [_layerWithGeometry, _secondLayer]);
      expect(updated.activeLayerId, '1');
      expect(updated.toolGeometries, const [_lineA]);
      expect(updated.snappingGeometries, const [_lineA, _lineB]);
      expect(updated.zoom, 2.5);
      expect(updated.panOffset, const Offset(20, 30));
      expect(updated.cursorPosition, const Offset(30, 40));
      expect(updated.selectedTool, const SelectionTool());
      expect(updated.selectedUnit, MetricUnit.cm);
      expect(updated.overlayLabel, 'Length: 1.0 cm');
      expect(updated.userInput, '200');
    });

    test('copyWith preserves values when omitted', () {
      const initial = ViewportState(
        layers: [_layerWithGeometry],
        activeLayerId: '0',
        toolGeometries: [_lineB],
        snappingGeometries: [_lineC],
        zoom: 1.25,
        panOffset: Offset(1, 2),
        cursorPosition: Offset(3, 4),
        selectedTool: LineTool(),
        selectedUnit: MetricUnit.m,
        overlayLabel: 'X: 1.0 m',
        userInput: '42',
      );

      final copied = initial.copyWith();

      expect(copied, equals(initial));
    });

    test('copyWith keeps selectedTool when null is provided', () {
      const initial = ViewportState(selectedTool: LineTool());
      // ignore: prefer_const_declarations
      final Tool? selectedTool = null;

      final cleared = initial.copyWith(selectedTool: selectedTool);

      expect(cleared.selectedTool, const LineTool());
    });

    test('copyWith preserves selectedTool when omitted', () {
      const tool = LineTool();
      const initial = ViewportState(selectedTool: tool);

      final copied = initial.copyWith(userInput: '10');

      expect(copied.selectedTool, same(tool));
    });

    test('uses deep equality for list fields', () {
      final layers = [_layerWithGeometry];
      final toolGeometries = [_lineC];
      final snappingGeometries = [_lineB, _lineC];
      final first = ViewportState(
        layers: layers,
        toolGeometries: toolGeometries,
        snappingGeometries: snappingGeometries,
      );
      final second = ViewportState(
        layers: [...layers],
        toolGeometries: [...toolGeometries],
        snappingGeometries: [...snappingGeometries],
      );

      expect(first, equals(second));
      expect(first.hashCode, second.hashCode);
    });

    test('hashCode uses Object.hashAll for list hashes', () {
      final layers = [_layerWithGeometry];
      final toolGeometries = [_lineC];
      final snappingGeometries = [_lineB, _lineC];
      final state = ViewportState(
        layers: layers,
        activeLayerId: '0',
        toolGeometries: toolGeometries,
        snappingGeometries: snappingGeometries,
        zoom: 2,
        panOffset: const Offset(1, 2),
        cursorPosition: const Offset(3, 4),
        selectedTool: const LineTool(),
        selectedUnit: MetricUnit.cm,
        overlayLabel: 'Length: 1.0 cm',
        userInput: '10',
      );

      final expected = Object.hashAll([
        Object.hashAll(state.layers),
        state.activeLayerId,
        Object.hashAll(state.toolGeometries),
        Object.hashAll(state.snappingGeometries),
        state.zoom,
        state.panOffset,
        state.cursorPosition,
        state.selectedTool,
        state.selectedUnit,
        state.overlayLabel,
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
      expect(
        base,
        isNot(equals(base.copyWith(panOffset: const Offset(3, 3)))),
      );
      expect(
        base,
        isNot(equals(base.copyWith(cursorPosition: const Offset(4, 4)))),
      );
      expect(base, isNot(equals(base.copyWith(selectedUnit: MetricUnit.cm))));
      expect(
        base,
        isNot(equals(base.copyWith(overlayLabel: 'Length: 10.0 mm'))),
      );
      expect(base, isNot(equals(base.copyWith(userInput: '2'))));
      expect(base, isNot(equals(base.copyWith(activeLayerId: '1'))));
    });

    test('states are different when any list field changes', () {
      const base = ViewportState(
        layers: [_defaultLayer],
        toolGeometries: [_lineB],
        snappingGeometries: [_lineC],
      );

      expect(
        base,
        isNot(equals(base.copyWith(layers: const [_secondLayer]))),
      );
      expect(
        base,
        isNot(equals(base.copyWith(toolGeometries: const [_lineC]))),
      );
      expect(
        base,
        isNot(equals(base.copyWith(snappingGeometries: const [_lineA]))),
      );
    });
  });
}
