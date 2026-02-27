import '../../data/metric_unit.dart';

String formatMetricLength(double millimeters, MetricUnit unit) {
  return '${unit.fromMillimeters(millimeters).toStringAsFixed(1)} ${unit.symbol}';
}

String formatMetricArea(double squareMillimeters, MetricUnit unit) {
  return '${unit.fromSquareMillimeters(squareMillimeters).toStringAsFixed(1)} ${unit.symbol}²';
}

String formatMetricCoordinate(double millimeters, MetricUnit unit) {
  return '${unit.fromMillimeters(millimeters).toStringAsFixed(1)} ${unit.symbol}';
}
