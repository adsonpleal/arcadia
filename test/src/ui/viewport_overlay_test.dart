import 'package:arcadia/src/logic/viewport_notifier.dart';
import 'package:arcadia/src/providers/viewport_notifier_provider.dart';
import 'package:arcadia/src/ui/viewport_overlay.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ViewportOverlay', () {
    testWidgets('shows zoom label with stable adaptive format', (tester) async {
      final notifier = await _pumpOverlay(tester);

      expect(find.text('100%'), findsOneWidget);

      notifier.value = notifier.value.copyWith(zoom: 0.875);
      await tester.pump();

      expect(find.text('87.5%'), findsOneWidget);
      expect(find.text('100%'), findsNothing);
    });

    testWidgets('shows and hides typed user input label', (tester) async {
      final notifier = await _pumpOverlay(tester);

      notifier.value = notifier.value.copyWith(
        cursorPosition: const Offset(3, 4),
        userInput: '12.5',
      );
      await tester.pump();

      expect(find.text('12.5'), findsOneWidget);

      notifier.clearUserInput();
      await tester.pump();

      expect(find.text('12.5'), findsNothing);
    });

    testWidgets('clicking zoom label resets zoom to 100%', (tester) async {
      final notifier = await _pumpOverlay(tester);
      notifier.value = notifier.value.copyWith(
        zoom: 2,
        panOffset: const Offset(10, 20),
      );
      await tester.pump();

      expect(find.text('200%'), findsOneWidget);

      await tester.tap(find.text('200%'));
      await tester.pump();

      expect(notifier.value.zoom, 1);
      expect(notifier.value.panOffset.dx, closeTo(5, 0.0001));
      expect(notifier.value.panOffset.dy, closeTo(10, 0.0001));
    });
  });

  group('ViewportOverlay composition', () {
    testWidgets('does not rebuild wrapper when state changes', (tester) async {
      var builds = 0;
      final notifier = await _pumpOverlay(
        tester,
        child: _CountingViewportOverlay(onBuild: () => builds++),
      );

      expect(builds, 1);

      notifier.value = notifier.value.copyWith(
        zoom: 2,
        cursorPosition: const Offset(3, 4),
        panOffset: const Offset(5, 6),
        userInput: '20',
      );
      await tester.pump();

      expect(builds, 1);
      expect(find.text('200%'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
    });
  });
}

Future<ViewportNotifier> _pumpOverlay(
  WidgetTester tester, {
  Widget child = const ViewportOverlay(),
}) async {
  late ViewportNotifier notifierFromContext;

  await tester.pumpWidget(
    Directionality(
      textDirection: .ltr,
      child: SizedBox(
        width: 400,
        height: 300,
        child: ViewportNotifierProvider(
          child: Builder(
            builder: (context) {
              notifierFromContext = context.viewportNotifier;
              return child;
            },
          ),
        ),
      ),
    ),
  );

  return notifierFromContext;
}

class _CountingViewportOverlay extends ViewportOverlay {
  const _CountingViewportOverlay({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return super.build(context);
  }
}
