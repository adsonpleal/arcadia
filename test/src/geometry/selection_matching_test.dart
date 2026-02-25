import 'package:arcadia/src/geometry/arc.dart';
import 'package:arcadia/src/geometry/circle.dart';
import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/geometry/point.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Point selection matching', () {
    const point = Point(
      position: Offset(5, 5),
      color: .primary,
      shape: .square,
    );
    const rect = Rect.fromLTRB(0, 0, 10, 10);

    test('window returns true when point is inside rect', () {
      expect(point.containedIn(rect), isTrue);
    });

    test('crossing returns false when point is outside rect', () {
      const outside = Point(
        position: Offset(20, 20),
        color: .primary,
        shape: .square,
      );

      expect(outside.intersects(rect), isFalse);
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

      expect(horizontal.containedIn(rect), isFalse);
    });

    test('crossing matches when line intersects rect edge', () {
      const rect = Rect.fromLTRB(0, 0, 10, 10);

      expect(horizontal.intersects(rect), isTrue);
    });
  });

  group('Circle selection matching', () {
    const circle = Circle(center: Offset(10, 10), radius: 5, color: .primary);

    test('window requires full circle containment', () {
      const tightRect = Rect.fromLTRB(8, 8, 12, 12);

      expect(circle.containedIn(tightRect), isFalse);
    });

    test('crossing matches when circle intersects rect boundary', () {
      const rect = Rect.fromLTRB(0, 0, 12, 12);

      expect(circle.intersects(rect), isTrue);
    });
  });

  group('Arc selection matching', () {
    final arc = Arc.fromPoints(
      first: const Offset(0, 10),
      second: const Offset(10, 0),
      third: const Offset(20, 10),
      color: .primary,
    );

    test('window only matches when sampled arc points are contained', () {
      const rect = Rect.fromLTRB(4, 4, 16, 16);

      expect(arc.containedIn(rect), isFalse);
    });

    test('crossing matches when sampled arc intersects rectangle', () {
      const rect = Rect.fromLTRB(9, 0, 11, 20);

      expect(arc.intersects(rect), isTrue);
    });

    test('window matches when rectangle fully contains arc', () {
      const rect = Rect.fromLTRB(-1, -1, 21, 11);

      expect(arc.containedIn(rect), isTrue);
    });
  });
}
