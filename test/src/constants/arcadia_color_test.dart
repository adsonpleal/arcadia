import 'dart:ui';

import 'package:arcadia/src/constants/arcadia_color.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArcadiaColor', () {
    test('exposes concrete color values through a single field', () {
      expect(ArcadiaColor.geometry.color, const Color(0xFFFFFFFF));
      expect(ArcadiaColor.grid.color, const Color(0x22FFFFFF));
      expect(ArcadiaColor.cursor.color, const Color(0xFF0F9224));
    });

    test('contains the expected palette entries', () {
      expect(
        ArcadiaColor.values,
        containsAll(<ArcadiaColor>[
          .viewportBackground,
          .componentBackground,
          .cursor,
          .geometry,
          .grid,
          .separator,
          .hover,
          .selected,
          .snappingPoint,
          .snappingLine,
          .hoveringGeometry,
          .selectedGeometry,
        ]),
      );
    });
  });
}
