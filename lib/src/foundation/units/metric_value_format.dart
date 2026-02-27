import '../../data/metric_unit.dart';

/// Formats a linear measurement stored in base millimeters.
String formatMetricLength(double millimeters, MetricUnit unit) {
  return '${unit.fromMillimeters(millimeters).toStringAsFixed(1)} '
      '${unit.symbol}';
}

/// Formats an area measurement stored in base square millimeters.
String formatMetricArea(double squareMillimeters, MetricUnit unit) {
  return '${unit.fromSquareMillimeters(squareMillimeters).toStringAsFixed(1)} '
      '${unit.symbol}²';
}

/// Formats a coordinate stored in base millimeters.
String formatMetricCoordinate(double millimeters, MetricUnit unit) {
  return '${unit.fromMillimeters(millimeters).toStringAsFixed(1)} '
      '${unit.symbol}';
}
