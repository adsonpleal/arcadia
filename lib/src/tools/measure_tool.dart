import 'package:flutter/widgets.dart';

import '../constants/arcadia_color.dart';
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

  @override
  void onClickUp() {
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
    _points.clear();
    clearToolGeometries();
    clearMeasureLabel();
  }

  List<Offset> get _previewPoints {
    if (_points.isEmpty) {
      return const [];
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
