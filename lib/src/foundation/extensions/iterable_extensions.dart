/// Iterable extension methods used across Arcadia.
extension IterableFirstWhereOrNullExtension<T> on Iterable<T> {
  /// Returns the first element that satisfies [test], or `null` if none.
  T? firstWhereOrNull(bool Function(T value) test) {
    for (final value in this) {
      if (test(value)) {
        return value;
      }
    }
    return null;
  }
}
