import 'package:arcadia/src/foundation/extensions/iterable_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IterableExtensions', () {
    test('returns the first matching element', () {
      final values = [1, 2, 3, 4];

      final result = values.firstWhereOrNull((value) => value.isEven);

      expect(result, 2);
    });

    test('returns null when no element matches', () {
      final values = [1, 3, 5];

      final result = values.firstWhereOrNull((value) => value.isEven);

      expect(result, isNull);
    });

    test('returns null for empty iterable without invoking predicate', () {
      final values = <int>[];
      var predicateCalls = 0;

      final result = values.firstWhereOrNull((value) {
        predicateCalls++;
        return value.isEven;
      });

      expect(result, isNull);
      expect(predicateCalls, 0);
    });

    test('stops evaluating after the first match', () {
      final values = [1, 2, 3, 4];
      var predicateCalls = 0;

      final result = values.firstWhereOrNull((value) {
        predicateCalls++;
        return value.isEven;
      });

      expect(result, 2);
      expect(predicateCalls, 2);
    });
  });
}
