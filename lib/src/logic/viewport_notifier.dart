import 'package:flutter/material.dart';

import '../data/viewport_state.dart';
import '../geometry/geometry.dart';
import '../tools/tool.dart';

// TODO: Add tests.
// this file depends on both flutter and macro stuff, so we can't test
// it for now.

/// A [ValueNotifier] that holds the [ViewportState].
///
/// This notifier holds all the necessary logic to
/// display and control the viewport.
class ViewportNotifier extends ValueNotifier<ViewportState> {
  /// The default constructor for [ViewportNotifier]
  ViewportNotifier() : super(const ViewportState());

  ToolAction? _toolAction;

  /// Select the given tool and start performing its action.
  void selectTool(Tool tool) {
    _toolAction = tool.toolActionFactory()..bind(this);
    value = value.copyWith(selectedTool: tool);
  }

  /// Cancel the selected tool action and deselect the current tool.
  void cancelToolAction() {
    clearToolGeometries();
    _toolAction = null;
    value = value.copyWith(selectedTool: null);
  }

  /// Applies the pan delta to the current [ViewportState.panOffset] state.
  void onPan(Offset delta) {
    final ViewportState(:zoom, :panOffset, :cursorPosition) = value;

    value = value.copyWith(
      panOffset: panOffset + delta,
      cursorPosition: cursorPosition - delta / zoom,
    );
    _toolAction?.onCursorPositionChange();
  }

  /// Applies the zoom scale to the current [ViewportState.zoom] state.
  void onZoom(double scale) {
    final ViewportState(:zoom, :panOffset, :cursorPosition) = value;
    final newZoom = zoom * scale;

    value = value.copyWith(
      zoom: newZoom,
      panOffset: panOffset - cursorPosition * (newZoom - zoom),
    );
  }

  /// Handle click action.
  void onCursorClick() {
    // TODO: handle selection
    _toolAction?.onClick();
  }

  /// Handle cursor movement.
  void onCursorMove({
    required Offset viewportPosition,
    required Offset viewportMidPoint,
  }) {
    final ViewportState(:zoom, :panOffset) = value;
    // TODO: handle snapping
    value = value.copyWith(
      cursorPosition: (viewportPosition - viewportMidPoint - panOffset) / zoom,
    );
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
  }

  /// Add tool geometries to state.
  void addToolGeometries(List<Geometry> geometries) {
    value = value.copyWith(
      toolGeometries: [
        ...value.geometries,
        ...geometries,
      ],
    );
  }

  /// Clear the tool geometries list.
  void clearToolGeometries() {
    value = value.copyWith(toolGeometries: []);
  }
}
