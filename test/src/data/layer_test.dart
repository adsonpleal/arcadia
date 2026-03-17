import 'package:arcadia/src/data/layer.dart';
import 'package:arcadia/src/geometry/line.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _lineA = Line(start: Offset(1, 2), end: Offset(3, 4), color: .primary);
const _lineB = Line(start: Offset(5, 6), end: Offset(7, 8), color: .primary);

void main() {
  group('Layer', () {
    test('has expected defaults', () {
      const layer = Layer(id: '0', name: 'Layer 0');

      expect(layer.id, '0');
      expect(layer.name, 'Layer 0');
      expect(layer.visible, isTrue);
      expect(layer.geometries, isEmpty);
    });

    test('copyWith updates each field', () {
      const layer = Layer(
        id: '0',
        name: 'Layer 0',
        geometries: [_lineA],
      );

      final updated = layer.copyWith(
        name: 'Renamed',
        visible: false,
        geometries: [_lineB],
      );

      expect(updated.id, '0');
      expect(updated.name, 'Renamed');
      expect(updated.visible, isFalse);
      expect(updated.geometries, [_lineB]);
    });

    test('copyWith preserves values when omitted', () {
      const layer = Layer(
        id: '1',
        name: 'Test',
        visible: false,
        geometries: [_lineA],
      );

      final copied = layer.copyWith();

      expect(copied, equals(layer));
    });

    test('uses deep equality for geometries list', () {
      final first = Layer(
        id: '0',
        name: 'Layer 0',
        geometries: [_lineA, _lineB],
      );
      final second = Layer(
        id: '0',
        name: 'Layer 0',
        geometries: [_lineA, _lineB],
      );

      expect(first, equals(second));
      expect(first.hashCode, second.hashCode);
    });

    test('layers are different when any field changes', () {
      const base = Layer(
        id: '0',
        name: 'Layer 0',
        geometries: [_lineA],
      );

      expect(base, isNot(equals(base.copyWith(name: 'Other'))));
      expect(base, isNot(equals(base.copyWith(visible: false))));
      expect(base, isNot(equals(base.copyWith(geometries: [_lineB]))));
    });
  });
}
