import 'package:flutter/material.dart';

import '../constants/config.dart';
import '../data/viewport_state.dart';
import '../foundation/extensions/iterable_extensions.dart';
import '../foundation/geometry/rectangle_generation.dart';
import '../geometry/geometry.dart';
import '../geometry/line.dart';
import '../geometry/point.dart';
import '../tools/tool.dart';

const _origin = Point(position: .zero, color: .accent, shape: .triangle);
const _minZoom = 0.01;
const _maxZoom = 10.0;

enum _SelectionDragMode {
  window,
  crossing,
}

class _SelectionDragSession {
  _SelectionDragSession({
    required this.start,
    required this.current,
    required this.additive,
  });

  final Offset start;
  Offset current;
  final bool additive;
}

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
  final List<Geometry> _previewSelectedGeometries = [];

  Geometry? _hoveringGeometry;
  _SelectionDragSession? _selectionDragSession;

  final List<List<Geometry>> _undoStack = [];
  final List<List<Geometry>> _redoStack = [];

  /// Select the given tool and start performing its action.
  void selectTool(Tool tool) {
    _clearSelectionDragPreview();
    _clearSelectedGeometries();
    clearToolGeometries();
    _toolAction = tool.toolActionFactory()..bind(this);
    value = value.copyWith(selectedTool: tool);
  }

  /// Cancel the selected tool action and deselect the current tool.
  void cancelToolAction() {
    _clearSelectionDragPreview();
    clearToolGeometries();
    _toolAction = null;
    value = value.copyWith(selectedTool: null, userInput: '');
    _lastSnaps.clear();
    _clearSelectedGeometries();
  }

  /// Delete the selected geometries
  void deleteSelectedGeometries() {
    if (_selectedGeometries.isNotEmpty) {
      _undoStack.add(value.geometries);
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

  /// Handle click down action and initialize drag selection state.
  void onCursorClickDown({bool shiftPressed = false}) {
    if (_toolAction != null) {
      return;
    }

    _clearSelectionDragPreview();
    final cursorPosition = value.cursorPosition;
    _selectionDragSession = _SelectionDragSession(
      start: cursorPosition,
      current: cursorPosition,
      additive: shiftPressed,
    );
    _previewSelectedGeometries.clear();
  }

  /// Handle click up action, finalizing either click or drag selection.
  void onCursorClickUp({bool shiftPressed = false}) {
    if (_toolAction case final action?) {
      action.onClick();
      return;
    }

    if (_selectionDragSession case final session?) {
      if (_hasDragStarted(session)) {
        final selectionRect = Rect.fromPoints(session.start, session.current);
        final mode = _resolvedRectSelectionMode(session);
        final matches = _matchingGeometriesForRect(selectionRect, mode: mode);
        _applySelectionMatches(
          matches,
          additive: session.additive || shiftPressed,
        );
        _hoveringGeometry = null;
        _clearSelectionDragPreview();
        _updateSelectedGeometries();
        return;
      }

      _clearSelectionDragPreview();
    }

    _handleSingleSelection();
  }

  /// Cancel active pointer interactions without changing persisted selection.
  void onCursorCancel() {
    if (_toolAction == null) {
      _clearSelectionDragPreview();
      _updateSelectedGeometries();
    }
  }

  /// Handle click action.
  void onCursorClick() {
    onCursorClickUp();
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
      if (_selectionDragSession case final selectionSession?) {
        _updateDragSelectionPreview(
          selectionSession,
          cursorPosition: newCursorPosition,
        );
        _hoveringGeometry = null;
      } else {
        _hoveringGeometry = _geometryBellowCursor();
      }
      _updateSelectedGeometries();
    }

    _toolAction?.onCursorPositionChange();
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

  void _updateDragSelectionPreview(
    _SelectionDragSession session, {
    required Offset cursorPosition,
  }) {
    session.current = cursorPosition;

    if (!_hasDragStarted(session)) {
      clearToolGeometries();
      _previewSelectedGeometries.clear();
      return;
    }

    final selectionRect = Rect.fromPoints(session.start, session.current);
    final mode = _resolvedRectSelectionMode(session);
    final previewGeometries = _selectionPreviewGeometries(
      selectionRect,
      mode: mode,
    );
    value = value.copyWith(toolGeometries: previewGeometries);
    _previewSelectedGeometries
      ..clear()
      ..addAll(_matchingGeometriesForRect(selectionRect, mode: mode));
  }

  bool _hasDragStarted(_SelectionDragSession session) {
    return (session.current - session.start).distance >=
        selectionDragStartDistance;
  }

  List<Geometry> _matchingGeometriesForRect(
    Rect selectionRect, {
    required _SelectionDragMode mode,
  }) {
    return [
      for (final geometry in value.geometries)
        if (switch (mode) {
          _SelectionDragMode.window => geometry.matchesWindowSelection(
            selectionRect,
          ),
          _SelectionDragMode.crossing => geometry.matchesCrossingSelection(
            selectionRect,
          ),
        })
          geometry,
    ];
  }

  List<Geometry> _selectionPreviewGeometries(
    Rect selectionRect, {
    required _SelectionDragMode mode,
  }) {
    return rectangleLinesFromRect(
      rect: selectionRect,
      color: .accentActive,
      dashed: mode == _SelectionDragMode.crossing,
    );
  }

  _SelectionDragMode _resolvedRectSelectionMode(_SelectionDragSession session) {
    return session.current.dx >= session.start.dx
        ? _SelectionDragMode.window
        : _SelectionDragMode.crossing;
  }

  void _applySelectionMatches(
    List<Geometry> matches, {
    required bool additive,
  }) {
    if (!additive) {
      _selectedGeometries
        ..clear()
        ..addAll(matches);
      return;
    }

    for (final geometry in matches) {
      if (!_selectedGeometries.contains(geometry)) {
        _selectedGeometries.add(geometry);
      }
    }
  }

  void _clearSelectionDragPreview() {
    _selectionDragSession = null;
    _previewSelectedGeometries.clear();
    clearToolGeometries();
  }

  void _handleSingleSelection() {
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
        for (final geometry in _previewSelectedGeometries)
          if (!_selectedGeometries.contains(geometry))
            geometry.copyWith(strokeWidth: 5, color: .accentMuted),
        if (_hoveringGeometry case final hovering?
            when !_previewSelectedGeometries.contains(hovering) &&
                !_selectedGeometries.contains(hovering))
          hovering.copyWith(strokeWidth: 5, color: .accentMuted),
        for (final geometry in _selectedGeometries)
          geometry.copyWith(strokeWidth: 5, color: .primaryActive),
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
    _previewSelectedGeometries.clear();
    _hoveringGeometry = null;
    _updateSelectedGeometries();
  }
}
