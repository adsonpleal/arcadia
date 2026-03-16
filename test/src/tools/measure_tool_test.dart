import 'package:arcadia/src/constants/config.dart';
import 'package:arcadia/src/data/metric_unit.dart';
import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/logic/viewport_notifier.dart';
import 'package:arcadia/src/tools/measure_tool.dart';
import 'package:arcadia/src/tools/selection_tool.dart';
import 'package:arcadia/src/tools/tool.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeasureTool', () {
    test('exposes metadata and action factory', () {
      const tool = MeasureTool();

      expect(tool.name, 'Measure');
      expect(tool.shortcut, const SingleActivator(.keyM));
      expect(tool.icon, isA<Widget>());
      expect(tool.toolActionFactory(), isA<ToolAction>());
    });

    test('shows running polyline length without committing geometry', () {
      final notifier = ViewportNotifier()..selectTool(const MeasureTool());

      _moveCursor(notifier, const Offset(10, 10));
      notifier.onCursorClickUp();
      _moveCursor(notifier, const Offset(20, 10));

      final firstPreview = notifier.value.toolGeometries.single as Line;
      expect(firstPreview.start, const Offset(10, 10));
      expect(firstPreview.end, const Offset(20, 10));
      expect(notifier.value.overlayLabel, 'Length: 10.0 mm');
      expect(
        [for (final layer in notifier.value.layers) ...layer.geometries],
        isEmpty,
      );

      notifier.onCursorClickUp();
      _moveCursor(notifier, const Offset(20, 20));

      final chainedPreview = notifier.value.toolGeometries
          .whereType<Line>()
          .toList();
      expect(chainedPreview, hasLength(2));
      expect(chainedPreview.first.start, const Offset(10, 10));
      expect(chainedPreview.first.end, const Offset(20, 10));
      expect(chainedPreview.last.start, const Offset(20, 10));
      expect(chainedPreview.last.end, const Offset(20, 20));
      expect(notifier.value.overlayLabel, 'Length: 20.0 mm');
      expect(
        [for (final layer in notifier.value.layers) ...layer.geometries],
        isEmpty,
      );
    });

    test('closes on first vertex and shows perimeter plus area', () {
      final notifier = ViewportNotifier()..selectTool(const MeasureTool());

      _closeTriangleMeasurement(notifier);

      final closedPreview = notifier.value.toolGeometries
          .whereType<Line>()
          .toList();
      expect(closedPreview, hasLength(3));
      expect(closedPreview.last.start, const Offset(10, 10));
      expect(closedPreview.last.end, Offset.zero);
      expect(
        notifier.value.overlayLabel,
        'Perimeter: 34.1 mm\nArea: 50.0 mm²',
      );
      expect(
        [for (final layer in notifier.value.layers) ...layer.geometries],
        isEmpty,
      );
    });

    test('cancel clears closed preview and restarts cleanly', () {
      final notifier = ViewportNotifier()..selectTool(const MeasureTool());

      _closeTriangleMeasurement(notifier);

      notifier.cancelToolAction();

      expect(notifier.value.selectedTool, const SelectionTool());
      expect(notifier.value.overlayLabel, isNull);
      expect(notifier.value.toolGeometries, isEmpty);

      notifier.selectTool(const MeasureTool());
      _moveCursor(notifier, const Offset(30, 30));
      notifier.onCursorClickUp();

      expect(notifier.value.overlayLabel, isNull);
      expect(notifier.value.toolGeometries, isEmpty);
    });

    test('setSelectedUnit recomputes measure label', () {
      final notifier = ViewportNotifier()..selectTool(const MeasureTool());

      _moveCursor(notifier, .zero);
      notifier.onCursorClickUp();
      _moveCursor(notifier, const Offset(10, 0));

      expect(notifier.value.overlayLabel, 'Length: 10.0 mm');

      notifier.setSelectedUnit(MetricUnit.cm);

      expect(notifier.value.overlayLabel, 'Length: 1.0 cm');
    });

    test('click after closed measurement starts a fresh session', () {
      final notifier = ViewportNotifier()..selectTool(const MeasureTool());

      _closeTriangleMeasurement(notifier);

      _moveCursor(notifier, const Offset(30, 30));
      notifier.onCursorClickUp();

      expect(notifier.value.overlayLabel, isNull);
      expect(notifier.value.toolGeometries, isEmpty);
      expect(notifier.value.selectedTool, const MeasureTool());
    });
  });
}

void _moveCursor(ViewportNotifier notifier, Offset cursorPosition) {
  notifier.onCursorMove(
    viewportPosition: cursorPosition * unitVirtualPixelRatio,
    viewportMidPoint: .zero,
  );
}

void _closeTriangleMeasurement(ViewportNotifier notifier) {
  _moveCursor(notifier, .zero);
  notifier.onCursorClickUp();
  _moveCursor(notifier, const Offset(10, 0));
  notifier.onCursorClickUp();
  _moveCursor(notifier, const Offset(10, 10));
  notifier.onCursorClickUp();
  _moveCursor(notifier, .zero);
  notifier.onCursorClickUp();
}
