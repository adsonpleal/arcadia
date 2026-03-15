import 'package:arcadia/src/data/metric_unit.dart';
import 'package:arcadia/src/foundation/units/metric_value_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatMetricLength', () {
    test('formats converted length with one decimal place', () {
      expect(formatMetricLength(1500, MetricUnit.m), '1.5 m');
      expect(formatMetricLength(42, MetricUnit.mm), '42.0 mm');
    });
  });

  group('formatMetricArea', () {
    test('formats converted area with squared unit suffix', () {
      expect(formatMetricArea(20_000, MetricUnit.cm), '200.0 cm²');
      expect(formatMetricArea(42, MetricUnit.mm), '42.0 mm²');
    });
  });

  group('formatMetricCoordinate', () {
    test('formats converted coordinates with one decimal place', () {
      expect(formatMetricCoordinate(25, MetricUnit.cm), '2.5 cm');
      expect(formatMetricCoordinate(-1200, MetricUnit.m), '-1.2 m');
    });
  });
}
