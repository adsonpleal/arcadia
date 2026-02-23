import 'dart:ui';

typedef _C = ArcadiaColor;

/// Colors for the arcadia project.
///
/// This project is dark mode only, so no need to have colors based of
/// a theme.
class ArcadiaColor extends Color {
  /// Default constructor for [ArcadiaColor].
  const ArcadiaColor(super.value);

  /// Viewport's default background color.
  static const viewportBackground = _C(0xFF252825);

  /// Component default background color.
  static const componentBackground = _C(0xFF433F3F);

  /// The color of the cursor pointer.
  static const cursor = _C(0xFF0F9224);

  /// The default color of geometries in the viewport.
  static const geometry = _C(0xFFFFFFFF);

  /// The default color of geometries in the viewport.
  static const grid = _C(0x22FFFFFF);

  /// The default separator color.
  static const separator = _C(0xFF696565);

  /// The default hover color.
  static const hover = _C(0xFF565353);

  /// The default selected color.
  static const selected = _C(0xFF696565);

  /// The default snapping point color.
  static const snappingPoint = _C(0xFFF76902);

  /// The default color for snapping lines.
  static const snappingLine = _C(0xFFF50BDE);

  /// The default hovering color for geometries.
  static const hoveringGeometry = _C(0x99FF5A13);

  /// The default selected color for geometries.
  static const selectedGeometry = _C(0x99706DF6);
}
