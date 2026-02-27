import 'package:flutter/widgets.dart';

import '../constants/arcadia_color.dart';
import '../constants/config.dart';
import '../foundation/geometry/measurement_math.dart';
import '../foundation/units/metric_value_format.dart';
import '../geometry/line.dart';
import 'tool.dart';

/// A tool that measures temporary polylines without committing geometry.
class MeasureTool implements Tool {
  /// The default constructor for [MeasureTool].
  const MeasureTool();

  @override
  String get name => 'Measure';

  @override
  ShortcutActivator get shortcut => const SingleActivator(.keyM);

  @override
  Widget get icon => const _MeasureToolIcon();

  @override
  ToolActionFactory get toolActionFactory => _MeasureToolAction.new;
}

class _MeasureToolAction extends ToolAction {
  final List<Offset> _points = [];
  var _isClosed = false;

  @override
  void onClickUp() {
    if (_isClosed) {
      _reset();
      _points.add(state.cursorPosition);
      _updatePreview();
      _updateMeasureLabel();
      return;
    }

    if (_isClosingClick(state.cursorPosition)) {
      _isClosed = true;
      _updatePreview();
      _updateMeasureLabel();
      return;
    }

    _points.add(state.cursorPosition);
    _updatePreview();
    _updateMeasureLabel();
  }

  @override
  void onCursorPositionChange() {
    _updatePreview();
    _updateMeasureLabel();
  }

  @override
  void onCancel() {
    _reset();
  }

  @override
  void onSelectedUnitChange() {
    _updateMeasureLabel();
  }

  bool _isClosingClick(Offset point) {
    if (_points.length < 3) {
      return false;
    }

    final tolerance = selectionTolerance / state.zoom;
    return (_points.first - point).distance <= tolerance;
  }

  void _reset() {
    _points.clear();
    _isClosed = false;
    clearToolGeometries();
    clearMeasureLabel();
  }

  List<Offset> get _previewPoints {
    if (_points.isEmpty) {
      return const [];
    }

    if (_isClosed) {
      return [..._points, _points.first];
    }

    if (state.cursorPosition == _points.last) {
      return _points;
    }

    return [..._points, state.cursorPosition];
  }

  void _updatePreview() {
    clearToolGeometries();

    final previewPoints = _previewPoints;
    if (previewPoints.length < 2) {
      return;
    }

    addToolGeometries([
      for (var i = 1; i < previewPoints.length; i++)
        Line(
          start: previewPoints[i - 1],
          end: previewPoints[i],
          color: .primary,
        ),
    ]);
  }

  void _updateMeasureLabel() {
    if (_isClosed) {
      setMeasureLabel(
        'Perimeter: ${formatMetricLength(closedPolylinePerimeter(_points), state.selectedUnit)}\n'
        'Area: ${formatMetricArea(polygonArea(_points), state.selectedUnit)}',
      );
      return;
    }

    final previewPoints = _previewPoints;
    if (previewPoints.length < 2) {
      clearMeasureLabel();
      return;
    }

    setMeasureLabel(
      'Length: ${formatMetricLength(polylineLength(previewPoints), state.selectedUnit)}',
    );
  }
}

class _MeasureToolIcon extends StatelessWidget {
  const _MeasureToolIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 16,
      height: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: ArcadiaColor.primary),
          ),
        ),
        child: Align(
          alignment: .centerLeft,
          child: SizedBox(
            width: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: ArcadiaColor.primary),
                  right: BorderSide(color: ArcadiaColor.primary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
