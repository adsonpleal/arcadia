import 'dart:ui';

/// Colors for the arcadia project.
///
/// This project is dark mode only, so no need to have colors based of
/// a theme.
abstract final class ArcadiaColors {
  /// Viewport's default background color.
  static const Color viewportBackground = Color(0xFF252825);

  /// Component default background color.
  static const Color componentBackground = Color(0xFF433F3F);

  /// The color of the cursor pointer.
  static const Color cursor = Color(0xFF0F9224);

  /// The default color of geometries in the viewport.
  static const Color geometry = Color(0xFFFFFFFF);

  /// The default color of geometries in the viewport.
  static const Color grid = Color(0x22FFFFFF);

  /// The default separator color.
  static const Color separator = Color(0xFF696565);

  /// The default hover color.
  static const Color hover = Color(0xFF565353);

  /// The default selected color.
  static const Color selected = Color(0xFF696565);

  /// The default snapping point color.
  static const Color snappingPoint = Color(0xFFF76902);

  /// The default color for snapping lines.
  static const Color snappingLine = Color(0xFFF50BDE);

  /// The default hovering color for geometries.
  static const Color hoveringGeometry = Color(0x99FF5A13);

  /// The default selected color for geometries.
  static const Color selectedGeometry = Color(0x99706DF6);
}
