import '../../data/metric_unit.dart';

/// Parsed numeric value plus the unit context used for conversion.
class ParsedMetricValueInput {
  /// The default constructor for [ParsedMetricValueInput].
  const ParsedMetricValueInput({
    required this.rawValue,
    required this.unit,
    required this.millimeters,
  });

  /// Numeric value as typed by the user before conversion.
  final double rawValue;

  /// Unit used to interpret [rawValue].
  final MetricUnit unit;

  /// Converted value in base millimeters.
  final double millimeters;
}

final _metricInputExpression = RegExp(
  r'^([0-9]+(?:\.[0-9]*)?)\s*([a-zA-Z]{1,2})?$',
);

/// Parses a metric input expression and converts it to millimeters.
///
/// `input` supports values like `30`, `30cm`, `30 cm`, `1.5m`, and mixed-case
/// unit suffixes. If no suffix is provided, [fallbackUnit] is applied.
ParsedMetricValueInput? parseMetricValueInput(
  String input, {
  required MetricUnit fallbackUnit,
}) {
  final normalizedInput = input.trim();
  if (normalizedInput == '') {
    return null;
  }

  final match = _metricInputExpression.firstMatch(normalizedInput);
  if (match == null) {
    return null;
  }

  final rawValue = double.tryParse(match.group(1)!);
  if (rawValue == null) {
    return null;
  }

  final suffix = match.group(2);
  final unit = suffix == null ? fallbackUnit : MetricUnit.fromSuffix(suffix);
  if (unit == null) {
    return null;
  }

  return ParsedMetricValueInput(
    rawValue: rawValue,
    unit: unit,
    millimeters: unit.toMillimeters(rawValue),
  );
}
