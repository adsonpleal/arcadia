import 'package:flutter/material.dart';

import '../constants/config.dart';
import '../data/viewport_state.dart';
import '../foundation/extensions/iterable_extensions.dart';
import '../geometry/geometry.dart';
import '../geometry/line.dart';
import '../geometry/point.dart';
import '../tools/selection_tool.dart';
import '../tools/tool.dart';

const _origin = Point(position: .zero, color: .accent, shape: .triangle);
const _minZoom = 0.01;
const _maxZoom = 10.0;

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

  final List<List<Geometry>> _undoStack = [];
  final List<List<Geometry>> _redoStack = [];

  /// Select the given tool and start performing its action.
  void selectTool(Tool tool) {
    clearToolGeometries();
    _lastSnaps.clear();
    _toolAction = tool.toolActionFactory()..bind(this);
    value = value.copyWith(selectedTool: tool, userInput: '');
  }

  /// Cancel the selected tool action and deselect the current tool.
  void cancelToolAction() {
    selectTool(const SelectionTool());
  }

  /// Delete the given geometries
  void deleteGeometries(List<Geometry> geometries) {
    _undoStack.add(value.geometries);
    value = value.copyWith(
      geometries: [
        for (final geometry in value.geometries)
          if (!geometries.contains(geometry)) geometry,
      ],
    );
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

  /// Add geometries to state.
  void addGeometries(List<Geometry> geometries) {
    _undoStack.add([...value.geometries]);
    _redoStack.clear();
    value = value.copyWith(geometries: [...value.geometries, ...geometries]);
    _snappingPoints = [
      _origin,
      for (final geometry in value.geometries) ...geometry.snappingPoints,
    ];
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
      } else if (input == '.') {
        if (!userInput.contains('.')) {
          userInput = '$userInput.';
        }
      } else {
        userInput = '$userInput$input';
      }

      _toolAction.onValueTyped(double.tryParse(userInput));
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

  /// Undo the latest geometries changes.
  void undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add([...value.geometries]);
      value = value.copyWith(geometries: _undoStack.removeLast());
    }
  }

  /// Redo the latest undo.
  void redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(value.geometries);
      value = value.copyWith(geometries: _redoStack.removeLast());
    }
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
}
