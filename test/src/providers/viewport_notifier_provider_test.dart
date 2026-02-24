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
      'ViewportInheritedNotifier does not rebuild on notifier value updates',
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
                      .notifier
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
        expect(builds, 1);
        expect(zoomFromWidget, 1);

        notifier.onZoom(2);
        await tester.pump();
        expect(builds, 1);
        expect(zoomFromWidget, 1);
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

    testWidgets(
      'selectViewportState rebuilds when selected value changes',
      (tester) async {
        var builds = 0;
        late ViewportNotifier notifier;
        late double zoomFromWidget;

        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: ViewportNotifierProvider(
              child: Builder(
                builder: (context) {
                  builds++;
                  notifier = context.viewportNotifier;
                  zoomFromWidget = context.selectViewportState(
                    (state) => state.zoom,
                  );
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        expect(builds, 1);
        expect(zoomFromWidget, 1);

        notifier.onZoom(2);
        await tester.pump();

        expect(builds, 2);
        expect(zoomFromWidget, 2);
      },
    );

    testWidgets(
      'selectViewportState does not rebuild when unselected values change',
      (tester) async {
        var builds = 0;
        late ViewportNotifier notifier;
        late double zoomFromWidget;

        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: ViewportNotifierProvider(
              child: Builder(
                builder: (context) {
                  builds++;
                  notifier = context.viewportNotifier;
                  zoomFromWidget = context.selectViewportState(
                    (state) => state.zoom,
                  );
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        expect(builds, 1);
        expect(zoomFromWidget, 1);

        notifier.value = notifier.value.copyWith(
          panOffset: const Offset(3, 4),
          cursorPosition: const Offset(8, 9),
          userInput: '12',
        );
        await tester.pump();

        expect(builds, 1);
        expect(zoomFromWidget, 1);
      },
    );

    testWidgets('selectViewportState supports record mapping', (tester) async {
      var builds = 0;
      late ViewportNotifier notifier;
      late (double zoom, Offset panOffset) valueFromWidget;

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: ViewportNotifierProvider(
            child: Builder(
              builder: (context) {
                builds++;
                notifier = context.viewportNotifier;
                valueFromWidget = context.selectViewportState(
                  (state) => (state.zoom, state.panOffset),
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(builds, 1);
      expect(valueFromWidget, (1.0, Offset.zero));

      notifier.value = notifier.value.copyWith(
        zoom: 1.5,
        panOffset: const Offset(10, 20),
      );
      await tester.pump();

      expect(builds, 2);
      expect(valueFromWidget, (1.5, const Offset(10, 20)));
    });
  });
}
