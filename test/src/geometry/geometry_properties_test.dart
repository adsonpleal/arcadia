import 'dart:ui';

import 'package:arcadia/src/constants/arcadia_color.dart';
import 'package:arcadia/src/data/metric_unit.dart';
import 'package:arcadia/src/geometry/arc.dart';
import 'package:arcadia/src/geometry/circle.dart';
import 'package:arcadia/src/geometry/geometry.dart';
import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/geometry/point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Geometry.buildPropertiesText', () {
    test('returns null by default', () {
      expect(
        const _TestGeometry(
          color: .primary,
        ).buildPropertiesText(MetricUnit.mm),
        isNull,
      );
    });

    test('formats line length', () {
      expect(
        const Line(
          start: .zero,
          end: Offset(3, 4),
          color: .primary,
        ).buildPropertiesText(MetricUnit.mm),
        'Length: 5.0 mm',
      );
    });

    test('formats point coordinates using the selected unit', () {
      expect(
        const Point(
          position: Offset(10, 20),
          color: .primary,
          shape: PointShape.square,
        ).buildPropertiesText(MetricUnit.cm),
        'X: 1.0 cm\nY: 2.0 cm',
      );
    });

    test('formats circle measurements', () {
      expect(
        const Circle(
          center: .zero,
          radius: 10,
          color: .primary,
        ).buildPropertiesText(MetricUnit.mm),
        'Radius: 10.0 mm\n'
        'Diameter: 20.0 mm\n'
        'Circumference: 62.8 mm\n'
        'Area: 314.2 mm²',
      );
    });

    test('formats arc measurements', () {
      expect(
        Arc.fromPoints(
          first: const Offset(10, 0),
          second: const Offset(0, 10),
          third: const Offset(-10, 0),
          color: .primary,
        ).buildPropertiesText(MetricUnit.mm),
        'Radius: 10.0 mm\nArc length: 31.4 mm',
      );
    });
  });
}

class _TestGeometry extends Geometry {
  const _TestGeometry({required super.color});

  @override
  List<Point> get snappingPoints => [];

  @override
  bool containedIn(Rect rect) {
    return false;
  }

  @override
  Geometry copyWith({double? strokeWidth, ArcadiaColor? color}) {
    return _TestGeometry(color: color ?? this.color);
  }

  @override
  bool contains(Offset offset, double tolerance) {
    return false;
  }

  @override
  bool intersects(Rect rect) {
    return false;
  }

  @override
  void render(Canvas canvas, Offset viewportOffset, double zoom) {}
}
