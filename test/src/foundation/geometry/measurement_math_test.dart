import 'package:arcadia/src/foundation/geometry/measurement_math.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('polylineLength', () {
    test('returns zero for fewer than two points', () {
      expect(polylineLength(const []), 0);
      expect(polylineLength(const [Offset(10, 10)]), 0);
    });

    test('sums the distance of each segment', () {
      expect(
        polylineLength(const [
          Offset(0, 0),
          Offset(3, 4),
          Offset(6, 8),
        ]),
        10,
      );
    });
  });

  group('closedPolylinePerimeter', () {
    test('includes the closing segment back to the first point', () {
      expect(
        closedPolylinePerimeter(const [
          Offset(0, 0),
          Offset(10, 0),
          Offset(10, 10),
          Offset(0, 10),
        ]),
        40,
      );
    });
  });

  group('polygonArea', () {
    test('computes polygon area using the shoelace formula', () {
      expect(
        polygonArea(const [
          Offset(0, 0),
          Offset(10, 0),
          Offset(10, 10),
          Offset(0, 10),
        ]),
        100,
      );
    });

    test('returns zero for degenerate polygons', () {
      expect(
        polygonArea(const [
          Offset(0, 0),
          Offset(10, 0),
          Offset(20, 0),
        ]),
        0,
      );
    });
  });
}
