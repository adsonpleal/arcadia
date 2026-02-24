import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/logic/viewport_notifier.dart';
import 'package:arcadia/src/providers/viewport_notifier_provider.dart';
import 'package:arcadia/src/ui/cursor_paint.dart';
import 'package:arcadia/src/ui/grid_paint.dart';
import 'package:arcadia/src/ui/selection_paint.dart';
import 'package:arcadia/src/ui/snapping_viewport_paint.dart';
import 'package:arcadia/src/ui/tool_viewport_paint.dart';
import 'package:arcadia/src/ui/viewport.dart';
import 'package:arcadia/src/ui/viewport_overlay.dart';
import 'package:arcadia/src/ui/viewport_paint.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart' hide Viewport;
import 'package:flutter_test/flutter_test.dart';

const _line = Line(start: .zero, end: Offset(10, 0), color: .geometry);

void main() {
  group('Viewport', () {
    testWidgets('renders paint layers in expected order', (tester) async {
      await _pumpViewport(tester);

      final stackFinder = find.byWidgetPredicate(
        (widget) => widget is Stack && widget.children.length == 7,
      );
      final stack = tester.widget<Stack>(stackFinder);
      final layerTypes = [
        for (final child in stack.children.whereType<Positioned>())
          child.child.runtimeType,
      ];

      expect(layerTypes, [
        GridPaint,
        SelectionPaint,
        ViewportPaint,
        SnappingViewportPaint,
        ToolViewportPaint,
        CursorPaint,
        ViewportOverlay,
      ]);
    });

    testWidgets('updates cursor position from pointer movement', (
      tester,
    ) async {
      final notifier = await _pumpViewport(tester);
      final center = tester.getCenter(find.byType(Viewport));
      final mouse = await tester.createGesture(kind: .mouse);

      await mouse.addPointer(location: center);
      await mouse.moveTo(center + const Offset(50, 25));
      await tester.pump();

      expect(notifier.value.cursorPosition.dx, closeTo(10, 0.0001));
      expect(notifier.value.cursorPosition.dy, closeTo(5, 0.0001));

      await mouse.removePointer();
    });

    testWidgets('applies pan when receiving pointer scroll signal', (
      tester,
    ) async {
      final notifier = await _pumpViewport(tester);
      final center = tester.getCenter(find.byType(Viewport));

      tester.binding.handlePointerEvent(
        PointerScrollEvent(position: center, scrollDelta: const Offset(0, 10)),
      );
      await tester.pump();

      expect(notifier.value.panOffset, const Offset(0, -10));
    });

    testWidgets('triggers click selection on pointer up', (tester) async {
      final notifier = await _pumpViewport(tester);
      final center = tester.getCenter(find.byType(Viewport));
      final clickPosition = center + const Offset(25, 0);
      notifier.addGeometries(const [_line]);
      await tester.pump();

      final mouse = await tester.createGesture(kind: .mouse);
      await mouse.addPointer(location: clickPosition);
      await mouse.moveTo(clickPosition);
      await mouse.down(clickPosition);
      await mouse.up();
      await tester.pump();

      expect(notifier.value.selectionGeometries, isNotEmpty);

      await mouse.removePointer();
    });
  });
}

Future<ViewportNotifier> _pumpViewport(WidgetTester tester) async {
  await tester.pumpWidget(
    const Directionality(
      textDirection: .ltr,
      child: SizedBox(
        width: 200,
        height: 100,
        child: ViewportNotifierProvider(child: Viewport()),
      ),
    ),
  );

  await tester.pump();
  return tester.element(find.byType(Viewport)).viewportNotifier;
}
