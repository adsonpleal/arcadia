import 'package:arcadia/src/macros/data.dart';
import 'package:test/test.dart';

@Data()
class SomeDataClass {
  SomeDataClass({
    required this.someInt,
    required this.someDouble,
    required this.someString,
    required this.someList,
  });

  final int someInt;
  final double someDouble;
  final String someString;
  final List<String> someList;
}

void main() {
  group('Data', () {
    test('should generate a valid copyWith method', () {
      final initialValue = SomeDataClass(
        someInt: 1,
        someDouble: 1,
        someString: 'test',
        someList: [
          'item1',
          'item2',
        ],
      );

      final copiedValue = initialValue.copyWith(
        someInt: 2,
      );

      expect(initialValue.someInt, isNot(equals(copiedValue.someInt)));
      expect(initialValue.someDouble, equals(copiedValue.someDouble));
      expect(initialValue.someString, equals(copiedValue.someString));
      expect(initialValue.someList, equals(copiedValue.someList));

      expect(copiedValue.someInt, equals(2));
    });

    test('should generate a valid equals method', () {
      const list = [
        'item1',
        'item2',
      ];
      final initialValue = SomeDataClass(
        someInt: 1,
        someDouble: 1,
        someString: 'test',
        someList: list,
      );

      final otherValue = SomeDataClass(
        someInt: 1,
        someDouble: 1,
        someString: 'test',
        someList: list,
      );

      expect(initialValue, equals(otherValue));
    });
  });
}
