import 'package:arcadia/src/data/metric_unit.dart';
import 'package:arcadia/src/foundation/units/metric_value_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MetricUnit conversions', () {
    test('converts to millimeters', () {
      expect(MetricUnit.mm.toMillimeters(30), 30);
      expect(MetricUnit.cm.toMillimeters(30), 300);
      expect(MetricUnit.m.toMillimeters(1.5), 1500);
    });

    test('converts from millimeters', () {
      expect(MetricUnit.mm.fromMillimeters(42), 42);
      expect(MetricUnit.cm.fromMillimeters(300), 30);
      expect(MetricUnit.m.fromMillimeters(2500), 2.5);
    });

    test('converts from square millimeters', () {
      expect(MetricUnit.mm.fromSquareMillimeters(42), 42);
      expect(MetricUnit.cm.fromSquareMillimeters(900), 9);
      expect(MetricUnit.m.fromSquareMillimeters(2_000_000), 2);
    });
  });

  group('parseMetricValueInput', () {
    test('uses fallback unit for unitless value', () {
      final parsed = parseMetricValueInput('30', fallbackUnit: MetricUnit.cm);
      expect(parsed?.unit, MetricUnit.cm);
      expect(parsed?.rawValue, 30);
      expect(parsed?.millimeters, 300);
    });

    test('explicit suffix overrides fallback', () {
      final parsed = parseMetricValueInput('30 mm', fallbackUnit: MetricUnit.m);
      expect(parsed?.unit, MetricUnit.mm);
      expect(parsed?.millimeters, 30);
    });

    test('accepts mixed case and no-space suffix', () {
      final parsed = parseMetricValueInput(
        '1.5CM',
        fallbackUnit: MetricUnit.mm,
      );
      expect(parsed?.unit, MetricUnit.cm);
      expect(parsed?.millimeters, 15);
    });

    test('returns null for invalid suffix', () {
      expect(
        parseMetricValueInput('12 km', fallbackUnit: MetricUnit.mm),
        isNull,
      );
    });

    test('returns null for leading dot input', () {
      expect(
        parseMetricValueInput('.5', fallbackUnit: MetricUnit.mm),
        isNull,
      );
    });

    test('treats trailing dot input as numeric value', () {
      final parsed = parseMetricValueInput('22.', fallbackUnit: MetricUnit.mm);

      expect(parsed?.unit, MetricUnit.mm);
      expect(parsed?.rawValue, 22);
      expect(parsed?.millimeters, 22);
    });
  });
}
