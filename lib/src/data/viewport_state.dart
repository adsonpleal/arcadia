import 'dart:ui';

import '../geometry/geometry.dart';
import '../macros/data.dart';

@Data()

/// The state of the viewport.
///
/// It contains all the [geometries] being displayed,
/// the current [zoom] and the [panOffset].
class ViewportState {
  /// The default [ViewportState] constructor
  const ViewportState({
    this.geometries = const [],
    this.zoom = 1.0,
    this.panOffset = Offset.zero,
    this.cursorPosition = Offset.zero,
  });

  /// The [Geometry] list of the viewport.
  ///
  /// All the given geometries will be rendered in the viewport,
  /// given that they intersect the viewport rect.
  final List<Geometry> geometries;

  /// The current zoom.
  final double zoom;

  /// The current pan (movement) offset.
  final Offset panOffset;

  /// The position of the cursor.
  final Offset cursorPosition;
}
