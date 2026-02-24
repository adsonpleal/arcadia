import 'package:arcadia/src/logic/viewport_notifier.dart';
import 'package:arcadia/src/providers/viewport_notifier_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ViewportNotifierProvider', () {
    testWidgets('ViewportInheritedNotifier exposes provided notifier', (
      tester,
    ) async {
      final notifier = ViewportNotifier();
      late ViewportNotifier notifierFromContext;

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: ViewportInheritedNotifier(
            notifier: notifier,
            child: Builder(
              builder: (context) {
                notifierFromContext = context.viewportNotifier;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(notifierFromContext, same(notifier));
    });

    testWidgets(
      'ViewportInheritedNotifier notifies dependents on notifier updates',
      (tester) async {
        final notifier = ViewportNotifier();
        var builds = 0;
        late double zoomFromWidget;

        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: ViewportInheritedNotifier(
              notifier: notifier,
              child: Builder(
                builder: (context) {
                  builds++;
                  zoomFromWidget = context
                      .dependOnInheritedWidgetOfExactType<
                        ViewportInheritedNotifier
                      >()!
                      .notifier!
                      .value
                      .zoom;
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        expect(builds, 1);

        notifier.onPan(const Offset(10, 20));
        await tester.pump();
        expect(builds, 2);
        expect(zoomFromWidget, 1);

        notifier.onZoom(2);
        await tester.pump();
        expect(builds, 3);
        expect(zoomFromWidget, 2);
      },
    );

    testWidgets('ViewportNotifierProvider puts a notifier in context', (
      tester,
    ) async {
      late ViewportNotifier notifierFromContext;

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: ViewportNotifierProvider(
            child: Builder(
              builder: (context) {
                notifierFromContext = context.viewportNotifier;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(notifierFromContext, isA<ViewportNotifier>());
    });
  });
}
