import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/geometry/point.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Point selection matching', () {
    const point = Point(position: Offset(5, 5), color: .primary, shape: .square);
    const rect = Rect.fromLTRB(0, 0, 10, 10);
    const lasso = [
      Offset(0, 0),
      Offset(10, 0),
      Offset(10, 10),
      Offset(0, 10),
    ];

    test('window returns true when point is inside rect', () {
      expect(point.matchesWindowSelection(rect), isTrue);
    });

    test('lasso crossing returns false when point is outside polygon', () {
      const outside = Point(
        position: Offset(20, 20),
        color: .primary,
        shape: .square,
      );

      expect(outside.matchesLassoCrossingSelection(lasso), isFalse);
    });
  });

  group('Line selection matching', () {
    const horizontal = Line(
      start: Offset(-5, 5),
      end: Offset(15, 5),
      color: .primary,
    );

    test('window requires both endpoints inside rect', () {
      const rect = Rect.fromLTRB(0, 0, 10, 10);

      expect(horizontal.matchesWindowSelection(rect), isFalse);
    });

    test('crossing matches when line intersects rect edge', () {
      const rect = Rect.fromLTRB(0, 0, 10, 10);

      expect(horizontal.matchesCrossingSelection(rect), isTrue);
    });

    test('lasso crossing matches when line intersects polygon edge', () {
      const lasso = [
        Offset(0, 0),
        Offset(10, 0),
        Offset(10, 10),
        Offset(0, 10),
      ];

      expect(horizontal.matchesLassoCrossingSelection(lasso), isTrue);
    });
  });
}
