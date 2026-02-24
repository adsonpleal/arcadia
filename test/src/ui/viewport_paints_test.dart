import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/logic/viewport_notifier.dart';
import 'package:arcadia/src/providers/viewport_notifier_provider.dart';
import 'package:arcadia/src/ui/selection_paint.dart';
import 'package:arcadia/src/ui/snapping_viewport_paint.dart';
import 'package:arcadia/src/ui/tool_viewport_paint.dart';
import 'package:arcadia/src/ui/viewport_paint.dart';
import 'package:arcadia/src/ui/viewport_painter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _geometry = Line(
  start: Offset(1, 2),
  end: Offset(3, 4),
  color: .geometry,
);

void main() {
  group('Viewport paint widgets', () {
    testWidgets('ViewportPaint reads geometries from state', (tester) async {
      final notifier = await _pumpWithProvider(
        tester,
        child: const ViewportPaint(),
        finder: find.byType(ViewportPaint),
      );

      notifier.value = notifier.value.copyWith(
        zoom: 2,
        panOffset: const Offset(10, 20),
        geometries: const [_geometry],
      );
      await tester.pump();

      final painter =
          tester.widget<CustomPaint>(find.byType(CustomPaint)).painter!
              as ViewportPainter;

      expect(painter.zoom, 2);
      expect(painter.panOffset, const Offset(10, 20));
      expect(painter.geometries.single, _geometry);
    });

    testWidgets('SelectionPaint reads selection geometries from state', (
      tester,
    ) async {
      final notifier = await _pumpWithProvider(
        tester,
        child: const SelectionPaint(),
        finder: find.byType(SelectionPaint),
      );

      notifier.value = notifier.value.copyWith(
        zoom: 1.5,
        panOffset: const Offset(2, 3),
        selectionGeometries: const [_geometry],
      );
      await tester.pump();

      final painter =
          tester.widget<CustomPaint>(find.byType(CustomPaint)).painter!
              as ViewportPainter;

      expect(painter.zoom, 1.5);
      expect(painter.panOffset, const Offset(2, 3));
      expect(painter.geometries.single, _geometry);
    });

    testWidgets('SnappingViewportPaint reads snapping geometries from state', (
      tester,
    ) async {
      final notifier = await _pumpWithProvider(
        tester,
        child: const SnappingViewportPaint(),
        finder: find.byType(SnappingViewportPaint),
      );

      notifier.value = notifier.value.copyWith(
        zoom: 0.75,
        panOffset: const Offset(-4, 6),
        snappingGeometries: const [_geometry],
      );
      await tester.pump();

      final painter =
          tester.widget<CustomPaint>(find.byType(CustomPaint)).painter!
              as ViewportPainter;

      expect(painter.zoom, 0.75);
      expect(painter.panOffset, const Offset(-4, 6));
      expect(painter.geometries.single, _geometry);
    });

    testWidgets('ToolViewportPaint reads tool geometries from state', (
      tester,
    ) async {
      final notifier = await _pumpWithProvider(
        tester,
        child: const ToolViewportPaint(),
        finder: find.byType(ToolViewportPaint),
      );

      notifier.value = notifier.value.copyWith(
        zoom: 3,
        panOffset: const Offset(1, 1),
        toolGeometries: const [_geometry],
      );
      await tester.pump();

      final painter =
          tester.widget<CustomPaint>(find.byType(CustomPaint)).painter!
              as ViewportPainter;

      expect(painter.zoom, 3);
      expect(painter.panOffset, const Offset(1, 1));
      expect(painter.geometries.single, _geometry);
    });
  });
}

Future<ViewportNotifier> _pumpWithProvider(
  WidgetTester tester, {
  required Widget child,
  required Finder finder,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 300,
        height: 200,
        child: ViewportNotifierProvider(child: child),
      ),
    ),
  );

  return tester.element(finder).viewportNotifier;
}
