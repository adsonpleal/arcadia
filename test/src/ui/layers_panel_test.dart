import 'package:arcadia/src/logic/viewport_notifier.dart';
import 'package:arcadia/src/providers/viewport_notifier_provider.dart';
import 'package:arcadia/src/ui/layers_panel.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LayersPanel', () {
    testWidgets('renders default layer', (tester) async {
      await _pumpLayersPanel(tester);

      expect(find.text('Layer 0'), findsOneWidget);
    });

    testWidgets('add button creates a new layer', (tester) async {
      final notifier = await _pumpLayersPanel(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(notifier.value.layers, hasLength(2));
      expect(find.text('Layer 1'), findsOneWidget);
    });

    testWidgets('tapping a layer sets it as active', (tester) async {
      final notifier = await _pumpLayersPanel(tester);
      notifier.addLayer('Second');
      await tester.pump();

      notifier.setActiveLayer('0');
      await tester.pump();

      await tester.tap(find.text('Second'));
      // The GestureDetector has both onTap and onDoubleTap,
      // so onTap fires only after the double-tap timeout expires.
      // pumpAndSettle() pumps in 100ms increments and stops early when no frame
      // is pending — before the timer fires. Pump explicitly past the timeout to
      // advance the fake clock beyond it in a single call.
      await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 1));

      expect(
        notifier.value.activeLayerId,
        notifier.value.layers.last.id,
      );
    });

    testWidgets('visibility toggle hides layer', (tester) async {
      final notifier = await _pumpLayersPanel(tester);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      expect(notifier.value.layers.first.visible, isFalse);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('delete button removes layer', (tester) async {
      final notifier = await _pumpLayersPanel(tester);
      notifier.addLayer('Second');
      await tester.pump();

      expect(notifier.value.layers, hasLength(2));

      final deleteButtons = find.byIcon(Icons.close);
      await tester.tap(deleteButtons.first);
      await tester.pump();

      expect(notifier.value.layers, hasLength(1));
    });

    testWidgets('delete button hidden when only one layer remains', (
      tester,
    ) async {
      await _pumpLayersPanel(tester);

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('double-tap layer name enters rename mode', (
      tester,
    ) async {
      final notifier = await _pumpLayersPanel(tester);

      // Two sequential tester.tap() won't trigger onDoubleTap.
      // Use the Offset-based approach within the double-tap timeout.
      final center = tester.getCenter(find.text('Layer 0'));
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Renamed');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(notifier.value.layers.first.name, 'Renamed');
    });
  });
}

Future<ViewportNotifier> _pumpLayersPanel(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: const Scaffold(
        body: ViewportNotifierProvider(child: LayersPanel()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester
      .element(find.byType(LayersPanel))
      .viewportNotifier;
}
