import 'package:arcadia/src/data/layer.dart';
import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/logic/viewport_notifier.dart';
import 'package:arcadia/src/providers/viewport_notifier_provider.dart';
import 'package:arcadia/src/ui/grid_paint.dart';
import 'package:arcadia/src/ui/snapping_viewport_paint.dart';
import 'package:arcadia/src/ui/tool_viewport_paint.dart';
import 'package:arcadia/src/ui/viewport_paint.dart';
import 'package:arcadia/src/ui/viewport_painter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _geometry = Line(
  start: Offset(1, 2),
  end: Offset(3, 4),
  color: .primary,
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
        layers: const [
          Layer(id: '0', name: 'Layer 0', geometries: [_geometry]),
        ],
      );
      await tester.pump();

      final painter =
          tester.widget<CustomPaint>(find.byType(CustomPaint)).painter!
              as ViewportPainter;

      expect(painter.zoom, 2);
      expect(painter.panOffset, const Offset(10, 20));
      expect(painter.geometries.single, _geometry);
    });

    testWidgets(
      'ViewportPaint does not rebuild when unrelated state slices change',
      (tester) async {
        var builds = 0;
        final notifier = await _pumpWithProvider(
          tester,
          child: _CountingViewportPaint(onBuild: () => builds++),
          finder: find.byType(_CountingViewportPaint),
        );

        expect(builds, 1);

        notifier.value = notifier.value.copyWith(
          toolGeometries: const [_geometry],
          snappingGeometries: const [_geometry],
          cursorPosition: const Offset(9, 9),
          userInput: '5',
        );
        await tester.pump();

        expect(builds, 1);
      },
    );

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

    testWidgets(
      'SnappingViewportPaint does not rebuild on unrelated state slices',
      (tester) async {
        var builds = 0;
        final notifier = await _pumpWithProvider(
          tester,
          child: _CountingSnappingViewportPaint(onBuild: () => builds++),
          finder: find.byType(_CountingSnappingViewportPaint),
        );

        expect(builds, 1);

        notifier.value = notifier.value.copyWith(
          layers: const [
            Layer(id: '0', name: 'Layer 0', geometries: [_geometry]),
          ],
          toolGeometries: const [_geometry],
          cursorPosition: const Offset(4, 5),
          userInput: '3',
        );
        await tester.pump();

        expect(builds, 1);
      },
    );

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

    testWidgets(
      'ToolViewportPaint does not rebuild when unrelated state slices change',
      (tester) async {
        var builds = 0;
        final notifier = await _pumpWithProvider(
          tester,
          child: _CountingToolViewportPaint(onBuild: () => builds++),
          finder: find.byType(_CountingToolViewportPaint),
        );

        expect(builds, 1);

        notifier.value = notifier.value.copyWith(
          layers: const [
            Layer(id: '0', name: 'Layer 0', geometries: [_geometry]),
          ],
          snappingGeometries: const [_geometry],
          cursorPosition: const Offset(1, 2),
          userInput: '9',
        );
        await tester.pump();

        expect(builds, 1);
      },
    );

    testWidgets(
      'GridPaint does not rebuild when unrelated state slices change',
      (tester) async {
        var builds = 0;
        final notifier = await _pumpWithProvider(
          tester,
          child: _CountingGridPaint(onBuild: () => builds++),
          finder: find.byType(_CountingGridPaint),
        );

        expect(builds, 1);

        notifier.value = notifier.value.copyWith(
          layers: const [
            Layer(id: '0', name: 'Layer 0', geometries: [_geometry]),
          ],
          toolGeometries: const [_geometry],
          snappingGeometries: const [_geometry],
          cursorPosition: const Offset(6, 6),
          userInput: '11',
        );
        await tester.pump();

        expect(builds, 1);
      },
    );
  });
}

Future<ViewportNotifier> _pumpWithProvider(
  WidgetTester tester, {
  required Widget child,
  required Finder finder,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: .ltr,
      child: SizedBox(
        width: 300,
        height: 200,
        child: ViewportNotifierProvider(child: child),
      ),
    ),
  );

  return tester.element(finder).viewportNotifier;
}

class _CountingViewportPaint extends ViewportPaint {
  const _CountingViewportPaint({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return super.build(context);
  }
}

class _CountingSnappingViewportPaint extends SnappingViewportPaint {
  const _CountingSnappingViewportPaint({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return super.build(context);
  }
}

class _CountingToolViewportPaint extends ToolViewportPaint {
  const _CountingToolViewportPaint({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return super.build(context);
  }
}

class _CountingGridPaint extends GridPaint {
  const _CountingGridPaint({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return super.build(context);
  }
}
