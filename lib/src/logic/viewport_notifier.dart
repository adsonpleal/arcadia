import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../constants/arcadia_colors.dart';
import '../constants/config.dart';
import '../data/viewport_state.dart';
import '../geometry/geometry.dart';
import '../geometry/line.dart';
import '../geometry/point.dart';
import '../tools/tool.dart';

// TODO: Add tests.
// this file depends on both flutter and macro stuff, so we can't test
// it for now.

const _origin = Point(
  position: Offset.zero,
  color: ArcadiaColors.snappingPoint,
  shape: PointShape.triangle,
);

/// A [ValueNotifier] that holds the [ViewportState].
///
/// This notifier holds all the necessary logic to
/// display and control the viewport.
class ViewportNotifier extends ValueNotifier<ViewportState> {
  /// The default constructor for [ViewportNotifier]
  ViewportNotifier() : super(const ViewportState());

  ToolAction? _toolAction;

  // We need to save this to a variable to avoid computing the
  // snapping points on every cursor position change.
  List<Point> _snappingPoints = [_origin];

  /// Saves the last three snaps for right angle snapping.
  final List<Offset> _lastSnaps = [];

  final List<Geometry> _selectedGeometries = [];

  Geometry? _hoveringGeometry;

  /// Select the given tool and start performing its action.
  void selectTool(Tool tool) {
    _clearSelectedGeometries();
    clearToolGeometries();
    _toolAction = tool.toolActionFactory()..bind(this);
    value = value.copyWith(selectedTool: tool);
  }

  /// Cancel the selected tool action and deselect the current tool.
  void cancelToolAction() {
    clearToolGeometries();
    _toolAction = null;
    value = value.copyWith(
      selectedTool: null,
      userInput: '',
    );
    _lastSnaps.clear();
    _clearSelectedGeometries();
  }

  /// Delete the selected geometries
  void deleteSelectedGeometries() {
    if (_selectedGeometries.isNotEmpty) {
      value = value.copyWith(
        geometries: [
          for (final geometry in value.geometries)
            if (!_selectedGeometries.contains(geometry)) geometry,
        ],
      );
      _clearSelectedGeometries();
    }
  }

  /// Applies the pan delta to the current [ViewportState.panOffset] state.
  void onPan(Offset delta) {
    final ViewportState(:zoom, :panOffset, :cursorPosition) = value;

    value = value.copyWith(
      panOffset: panOffset + delta,
      cursorPosition: cursorPosition - delta / zoom / unitVirtualPixelRatio,
    );
    _toolAction?.onCursorPositionChange();
  }

  /// Applies the zoom scale to the current [ViewportState.zoom] state.
  void onZoom(double scale) {
    final ViewportState(:zoom, :panOffset, :cursorPosition) = value;
    final newZoom = zoom * scale;

    value = value.copyWith(
      zoom: newZoom,
      panOffset:
          panOffset - cursorPosition * unitVirtualPixelRatio * (newZoom - zoom),
    );
  }

  /// Handle click action.
  void onCursorClick() {
    if (_toolAction case final action?) {
      action.onClick();
    } else {
      final selected = _geometryBellowCursor();
      if (selected != null) {
        if (_selectedGeometries.contains(selected)) {
          _selectedGeometries.remove(selected);
        } else {
          _selectedGeometries.add(selected);
        }
        _updateSelectedGeometries();
      }
    }
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

    // only perform snapping if there is a selected tool.
    if (_toolAction != null) {
      final snappingPoint = _snappingPoints.firstWhereOrNull(
        (point) => point.contains(
          newCursorPosition,
          5 / zoom,
        ),
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
              orthoCursorPosition =
                  Offset(snapOffset.dx, orthoCursorPosition.dy);
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
              orthoCursorPosition =
                  Offset(orthoCursorPosition.dx, snapOffset.dy);
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
                  color: ArcadiaColors.snappingLine,
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
      _hoveringGeometry = _geometryBellowCursor();
      _updateSelectedGeometries();
    }

    _toolAction?.onCursorPositionChange();
  }

  /// Add geometries to state.
  void addGeometries(List<Geometry> geometries) {
    value = value.copyWith(
      geometries: [
        ...value.geometries,
        ...geometries,
      ],
    );
    _snappingPoints = [
      _origin,
      for (final geometry in value.geometries) ...geometry.snappingPoints,
    ];
  }

  /// Add tool geometries to state.
  void addToolGeometries(List<Geometry> geometries) {
    value = value.copyWith(
      toolGeometries: [
        ...value.toolGeometries,
        ...geometries,
      ],
    );
  }

  /// Clear the tool geometries list.
  void clearToolGeometries() {
    value = value.copyWith(toolGeometries: []);
  }

  /// Called when a user types a value.
  void onUserInput(String input) {
    if (_toolAction case final tool? when tool.acceptValueInput) {
      var userInput = value.userInput;
      if (input == 'back') {
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

      tool.onValueTyped(double.tryParse(userInput));
      value = value.copyWith(userInput: userInput);
    } else {
      // TODO: improve the back logic
      if (input == 'back') {
        deleteSelectedGeometries();
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

  void _addLastSnap(Offset offset) {
    if (!_lastSnaps.contains(offset)) {
      if (_lastSnaps.length == 3) {
        _lastSnaps.removeAt(0);
      } else {
        _lastSnaps.add(offset);
      }
    }
  }

  void _updateSelectedGeometries() {
    value = value.copyWith(
      selectionGeometries: [
        if (_hoveringGeometry case final hovering?)
          hovering.copyWith(
            strokeWidth: 5,
            color: ArcadiaColors.hoveringGeometry,
          ),
        for (final geometry in _selectedGeometries)
          geometry.copyWith(
            strokeWidth: 5,
            color: ArcadiaColors.selectedGeometry,
          ),
      ],
    );
  }

  Geometry? _geometryBellowCursor() {
    return value.geometries.firstWhereOrNull(
      (geometry) => geometry.contains(
        value.cursorPosition,
        selectionTolerance / value.zoom,
      ),
    );
  }

  void _clearSelectedGeometries() {
    _selectedGeometries.clear();
    _hoveringGeometry = null;
    _updateSelectedGeometries();
  }
}
