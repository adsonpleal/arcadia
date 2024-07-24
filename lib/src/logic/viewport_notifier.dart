import 'dart:math' hide Point;

import 'package:flutter/material.dart';

import '../data/viewport_state.dart';
import '../geometry/geometry.dart';

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

  /// Applies the pan delta to the current [ViewportState.panOffset] state.
  void onPan(Offset delta) {
    final ViewportState(:zoom, :panOffset, :cursorPosition) = value;

    value = value.copyWith(
      panOffset: panOffset + delta,
      cursorPosition: cursorPosition - delta / zoom,
    );
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
    // TODO: implement actual logic
    final random = Random();
    value = value.copyWith(
      geometries: [
        ...value.geometries,
        Point(
          position: value.cursorPosition,
          color: [
            Colors.red,
            Colors.blue,
            Colors.white,
          ][random.nextInt(3)],
          shape: PointShape.values[random.nextInt(PointShape.values.length)],
        ),
      ],
    );
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
  }
}
