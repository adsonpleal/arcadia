/// Supported project units for metric-only workflows.
enum MetricUnit {
  /// Millimeter base unit.
  mm('mm', 1),

  /// Centimeter unit.
  cm('cm', 10),

  /// Meter unit.
  m('m', 1000)
  ;

  const MetricUnit(this.symbol, this.millimetersFactor);

  /// Compact label used in UI and typed suffixes.
  final String symbol;

  /// Multiplicative factor from this unit into base millimeters.
  final double millimetersFactor;

  /// Multiplicative factor from this unit into base square millimeters.
  double get squareMillimetersFactor {
    return millimetersFactor * millimetersFactor;
  }

  /// Converts [value] from this unit into millimeters.
  double toMillimeters(double value) {
    return value * millimetersFactor;
  }

  /// Converts [value] from millimeters into this unit.
  double fromMillimeters(double value) {
    return value / millimetersFactor;
  }

  /// Converts [value] from square millimeters into this unit squared.
  double fromSquareMillimeters(double value) {
    return value / squareMillimetersFactor;
  }

  /// Resolves a typed unit suffix into a [MetricUnit].
  static MetricUnit? fromSuffix(String suffix) {
    final normalizedSuffix = suffix.trim().toLowerCase();
    for (final unit in MetricUnit.values) {
      if (unit.symbol == normalizedSuffix) {
        return unit;
      }
    }
    return null;
  }
}
