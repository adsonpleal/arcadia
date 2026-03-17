import 'package:flutter/material.dart';

import '../constants/config.dart';
import '../data/layer.dart';
import '../data/metric_unit.dart';
import '../data/viewport_state.dart';
import '../foundation/extensions/iterable_extensions.dart';
import '../foundation/units/metric_value_input.dart';
import '../geometry/geometry.dart';
import '../geometry/line.dart';
import '../geometry/point.dart';
import '../tools/selection_tool.dart';
import '../tools/tool.dart';

const _origin = Point(position: .zero, color: .accent, shape: .triangle);
const _minZoom = 0.01;
const _maxZoom = 10.0;
final _valueAllowedCharacterInput = RegExp(
  r'^[0-9.cm ]$',
  caseSensitive: false,
);
final _valueInputPattern = [
  RegExp(r'^[0-9]+$'),
  RegExp(r'^[0-9]+\.$'),
  RegExp(r'^[0-9]+\.[0-9]+$'),
  RegExp(r'^[0-9]+(?:\.[0-9]+)? $'),
  RegExp(r'^[0-9]+(?:\.[0-9]+)? ?[cC]$'),
  RegExp(r'^[0-9]+(?:\.[0-9]+)? ?[mM]$'),
  RegExp(r'^[0-9]+(?:\.[0-9]+)? ?[cC][mM]$'),
  RegExp(r'^[0-9]+(?:\.[0-9]+)? ?[mM]{2}$'),
];

/// A [ValueNotifier] that holds the [ViewportState].
///
/// This notifier holds all the necessary logic to
/// display and control the viewport.
class ViewportNotifier extends ValueNotifier<ViewportState> {
  /// The default constructor for [ViewportNotifier]
  ViewportNotifier() : super(const ViewportState()) {
    _toolAction = value.selectedTool.toolActionFactory()..bind(this);
  }

  late ToolAction _toolAction;

  // We need to save this to a variable to avoid computing the
  // snapping points on every cursor position change.
  List<Point> _snappingPoints = [_origin];

  /// Saves the last three snaps for right angle snapping.
  final List<Offset> _lastSnaps = [];

  final List<List<Layer>> _undoStack = [];
  final List<List<Layer>> _redoStack = [];
  int _nextLayerId = 1;

  /// Select the given tool and start performing its action.
  void selectTool(Tool tool) {
    clearToolGeometries();
    _lastSnaps.clear();
    _toolAction = tool.toolActionFactory()..bind(this);
    value = value.copyWith(
      selectedTool: tool,
      overlayLabel: null,
      userInput: '',
    );
  }

  /// Whether the currently selected tool action accepts typed value input.
  bool get acceptsValueInput {
    return _toolAction.acceptValueInput;
  }

  /// Sets the selected project unit used for value input interpretation.
  void setSelectedUnit(MetricUnit unit) {
    value = value.copyWith(selectedUnit: unit);
    _toolAction.onSelectedUnitChange();
  }

  /// Sets the current overlay label.
  void setOverlayLabel(String? text) {
    value = value.copyWith(overlayLabel: text);
  }

  /// Cancel the selected tool action and deselect the current tool.
  void cancelToolAction() {
    selectTool(const SelectionTool());
  }

  /// Delete the given geometries from all layers.
  void deleteGeometries(List<Geometry> geometries) {
    _undoStack.add([...value.layers]);
    _redoStack.clear();
    value = value.copyWith(
      layers: [
        for (final layer in value.layers)
          layer.copyWith(
            geometries: [
              for (final geometry in layer.geometries)
                if (!geometries.contains(geometry)) geometry,
            ],
          ),
      ],
    );
    _recomputeSnappingPoints();
  }

  /// Applies the pan delta to the current [ViewportState.panOffset] state.
  void onPan(Offset delta) {
    final ViewportState(:zoom, :panOffset, :cursorPosition) = value;

    value = value.copyWith(
      panOffset: panOffset + delta,
      cursorPosition: cursorPosition - delta / zoom / unitVirtualPixelRatio,
    );
    _toolAction.onCursorPositionChange();
  }

  /// Applies the zoom scale to the current [ViewportState.zoom] state.
  void onZoom(double scale) {
    final ViewportState(:zoom, :panOffset, :cursorPosition) = value;
    final newZoom = (zoom * scale).clamp(_minZoom, _maxZoom);

    value = value.copyWith(
      zoom: newZoom,
      panOffset:
          panOffset - cursorPosition * unitVirtualPixelRatio * (newZoom - zoom),
    );
  }

  /// Resets zoom to default while keeping the viewport center anchored.
  void resetZoomToDefault() {
    final ViewportState(:zoom, :panOffset) = value;

    if (zoom == 1) {
      return;
    }

    value = value.copyWith(zoom: 1, panOffset: panOffset / zoom);
  }

  /// Handle click down action.
  void onCursorClickDown() {
    _toolAction.onClickDown();
  }

  /// Handle click up action.
  void onCursorClickUp() {
    _toolAction.onClickUp();
  }

  /// Cancel active pointer interactions.
  void onCursorCancel() {
    _toolAction.onCancel();
  }

  /// Handle cursor movement.
  void onCursorMove({
    required Offset viewportPosition,
    required Offset viewportMidPoint,
  }) {
    final ViewportState(:zoom, :panOffset) = value;
    final newCursorPosition =
        (viewportPosition - viewportMidPoint - panOffset) /
        zoom /
        unitVirtualPixelRatio;

    void applyDefaultCursorMovement() {
      value = value.copyWith(
        cursorPosition: newCursorPosition,
        snappingGeometries: [],
      );
    }

    // only perform snapping for non-selection tools.
    if (value.selectedTool is! SelectionTool) {
      final snappingPoint = _snappingPoints.firstWhereOrNull(
        (point) => point.contains(newCursorPosition, 5 / zoom),
      );

      if (snappingPoint != null) {
        _addLastSnap(snappingPoint.position);

        value = value.copyWith(
          cursorPosition: snappingPoint.position,
          snappingGeometries: [snappingPoint],
        );
      } else {
        var orthoCursorPosition = newCursorPosition;
        final snappedLines = <Offset>[];
        var snappedVertically = false;
        var snappedHorizontally = false;

        for (final snapOffset in _lastSnaps) {
          if (!snappedVertically) {
            final verticalSnappingRect = Rect.fromCenter(
              center: snapOffset,
              width: 10 / zoom,
              height: double.infinity,
            );

            if (verticalSnappingRect.contains(orthoCursorPosition)) {
              snappedLines.add(snapOffset);
              orthoCursorPosition = Offset(
                snapOffset.dx,
                orthoCursorPosition.dy,
              );
              snappedVertically = true;
              continue;
            }
          }

          if (!snappedHorizontally) {
            final horizontalSnappingRect = Rect.fromCenter(
              center: snapOffset,
              width: double.infinity,
              height: 10 / zoom,
            );

            if (horizontalSnappingRect.contains(orthoCursorPosition)) {
              snappedLines.add(snapOffset);
              orthoCursorPosition = Offset(
                orthoCursorPosition.dx,
                snapOffset.dy,
              );
              snappedHorizontally = true;
            }
          }
        }

        if (snappedLines.isNotEmpty) {
          value = value.copyWith(
            cursorPosition: orthoCursorPosition,
            snappingGeometries: [
              for (final offset in snappedLines)
                Line(
                  color: .accentActive,
                  start: offset,
                  end: orthoCursorPosition,
                ),
            ],
          );
        } else {
          applyDefaultCursorMovement();
        }
      }
    } else {
      applyDefaultCursorMovement();
    }

    _toolAction.onCursorPositionChange();
  }

  /// Add geometries to the active layer.
  void addGeometries(List<Geometry> geometries) {
    _undoStack.add([...value.layers]);
    _redoStack.clear();
    value = value.copyWith(
      layers: [
        for (final layer in value.layers)
          if (layer.id == value.activeLayerId)
            layer.copyWith(
              geometries: [...layer.geometries, ...geometries],
            )
          else
            layer,
      ],
    );
    _recomputeSnappingPoints();
  }

  /// Add tool geometries to state.
  void addToolGeometries(List<Geometry> geometries) {
    value = value.copyWith(
      toolGeometries: [...value.toolGeometries, ...geometries],
    );
  }

  /// Clear the tool geometries list.
  void clearToolGeometries() {
    value = value.copyWith(toolGeometries: []);
  }

  /// Called when a user types a value.
  void onUserInput(String input) {
    if (_toolAction.acceptValueInput) {
      var userInput = value.userInput;
      if (input == deleteCharacter) {
        if (userInput != '') {
          userInput = userInput.substring(0, userInput.length - 1);
        }
      } else if (_isAllowedValueInput(input, userInput)) {
        userInput = '$userInput$input';
      } else {
        return;
      }

      final parsedValue = parseMetricValueInput(
        userInput,
        fallbackUnit: value.selectedUnit,
      );
      _toolAction.onValueTyped(parsedValue?.millimeters);
      value = value.copyWith(userInput: userInput);
    } else {
      if (input == deleteCharacter) {
        _toolAction.onDelete();
      }
    }
  }

  /// Clear the current user input.
  void clearUserInput() {
    value = value.copyWith(userInput: '');
  }

  /// Add a snap point to the list.
  void addSnapPoint(Offset offset) {
    _addLastSnap(offset);
  }

  /// Undo the latest layers change.
  void undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add([...value.layers]);
      final restoredLayers = _undoStack.removeLast();
      final activeLayerId = _validActiveLayerId(restoredLayers);
      value = value.copyWith(
        layers: restoredLayers,
        activeLayerId: activeLayerId,
      );
      _recomputeSnappingPoints();
    }
  }

  /// Redo the latest undo.
  void redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add([...value.layers]);
      final restoredLayers = _redoStack.removeLast();
      final activeLayerId = _validActiveLayerId(restoredLayers);
      value = value.copyWith(
        layers: restoredLayers,
        activeLayerId: activeLayerId,
      );
      _recomputeSnappingPoints();
    }
  }

  /// Creates a new layer and sets it as active.
  void addLayer(String name) {
    final id = '${_nextLayerId++}';
    final layer = Layer(id: id, name: name);
    _undoStack.add([...value.layers]);
    _redoStack.clear();
    value = value.copyWith(
      layers: [...value.layers, layer],
      activeLayerId: id,
    );
    _recomputeSnappingPoints();
  }

  /// Renames the layer with the given [id].
  void renameLayer(String id, String name) {
    _undoStack.add([...value.layers]);
    _redoStack.clear();
    value = value.copyWith(
      layers: [
        for (final layer in value.layers)
          if (layer.id == id) layer.copyWith(name: name) else layer,
      ],
    );
  }

  /// Deletes the layer with the given [id].
  ///
  /// Cannot delete the last remaining layer.
  /// If the deleted layer was active, switches to the layer at index-1
  /// or index 0 of the remaining list.
  void deleteLayer(String id) {
    if (value.layers.length <= 1) return;

    final index = value.layers.indexWhere((l) => l.id == id);
    if (index == -1) return;

    _undoStack.add([...value.layers]);
    _redoStack.clear();

    final newLayers = [...value.layers]..removeAt(index);
    var activeLayerId = value.activeLayerId;

    if (activeLayerId == id) {
      final newIndex = index > 0 ? index - 1 : 0;
      activeLayerId = newLayers[newIndex].id;
    }

    value = value.copyWith(layers: newLayers, activeLayerId: activeLayerId);
    _recomputeSnappingPoints();
  }

  /// Sets the active layer.
  void setActiveLayer(String id) {
    value = value.copyWith(activeLayerId: id);
  }

  /// Toggles visibility of the layer with the given [id].
  void toggleLayerVisibility(String id) {
    value = value.copyWith(
      layers: [
        for (final layer in value.layers)
          if (layer.id == id)
            layer.copyWith(visible: !layer.visible)
          else
            layer,
      ],
    );
    _recomputeSnappingPoints();
  }

  void _recomputeSnappingPoints() {
    _snappingPoints = [
      _origin,
      for (final layer in value.layers)
        if (layer.visible)
          for (final geometry in layer.geometries) ...geometry.snappingPoints,
    ];
  }

  /// Returns the current activeLayerId if it exists in [layers],
  /// otherwise falls back to the first layer's ID.
  String _validActiveLayerId(List<Layer> layers) {
    final current = value.activeLayerId;
    if (layers.any((l) => l.id == current)) return current;
    return layers.first.id;
  }

  void _addLastSnap(Offset offset) {
    if (!_lastSnaps.contains(offset)) {
      if (_lastSnaps.length == 3) {
        _lastSnaps.removeAt(0);
      } else {
        _lastSnaps.add(offset);
      }
    }
  }

  bool _isAllowedValueInput(String input, String currentValue) {
    if (input.length != 1) {
      return false;
    }

    if (!_valueAllowedCharacterInput.hasMatch(input)) {
      return false;
    }

    final candidateValue = '$currentValue$input';

    for (final pattern in _valueInputPattern) {
      if (pattern.hasMatch(candidateValue)) {
        return true;
      }
    }

    return false;
  }
}
