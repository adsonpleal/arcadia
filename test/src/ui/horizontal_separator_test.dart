import 'package:arcadia/src/ui/horizontal_separator.dart';
import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HorizontalSeparator', () {
    testWidgets('should render a separator that fills the width', (
      tester,
    ) async {
      await tester.pumpWidget(const Center(child: HorizontalSeparator()));

      await expectLater(
        find.byType(HorizontalSeparator),
        matchesGoldenFile('goldens/horizontal_separator/separator.png'),
      );
    });
  });
}
