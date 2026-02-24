import 'package:arcadia/src/logic/viewport_notifier.dart';
import 'package:arcadia/src/providers/viewport_notifier_provider.dart';
import 'package:arcadia/src/ui/cursor_paint.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CursorPaint', () {
    testWidgets('uses hidden system cursor', (tester) async {
      await _pumpCursor(tester);

      final mouseRegion = tester.widget<MouseRegion>(find.byType(MouseRegion));
      expect(mouseRegion.cursor, SystemMouseCursors.none);
    });

    testWidgets('shows typed user input next to cursor', (tester) async {
      final notifier = await _pumpCursor(tester);

      notifier.value = notifier.value.copyWith(
        cursorPosition: const Offset(3, 4),
        userInput: '12.5',
      );
      await tester.pump();

      expect(find.text('12.5'), findsOneWidget);
    });

    testWidgets('hides typed user input when input is empty', (tester) async {
      final notifier = await _pumpCursor(tester);

      notifier.value = notifier.value.copyWith(userInput: '4');
      await tester.pump();
      expect(find.text('4'), findsOneWidget);

      notifier.clearUserInput();
      await tester.pump();
      expect(find.text('4'), findsNothing);
    });
  });
}

Future<ViewportNotifier> _pumpCursor(WidgetTester tester) async {
  await tester.pumpWidget(
    const Directionality(
      textDirection: .ltr,
      child: SizedBox(
        width: 400,
        height: 300,
        child: ViewportNotifierProvider(child: CursorPaint()),
      ),
    ),
  );

  return tester.element(find.byType(CursorPaint)).viewportNotifier;
}
