import 'dart:ui';

/// Colors for the arcadia project.
///
/// This project is dark mode only, so no need to have colors based of
/// a theme.
enum ArcadiaColor {
  /// Viewport's default background color.
  viewportBackground(Color(0xFF252825)),

  /// Component default background color.
  componentBackground(Color(0xFF433F3F)),

  /// The color of the cursor pointer.
  cursor(Color(0xFF0F9224)),

  /// The default color of geometries in the viewport.
  geometry(Color(0xFFFFFFFF)),

  /// The default color of geometries in the viewport.
  grid(Color(0x22FFFFFF)),

  /// The default separator color.
  separator(Color(0xFF696565)),

  /// The default hover color.
  hover(Color(0xFF565353)),

  /// The default selected color.
  selected(Color(0xFF696565)),

  /// The default snapping point color.
  snappingPoint(Color(0xFFF76902)),

  /// The default color for snapping lines.
  snappingLine(Color(0xFFF50BDE)),

  /// The default hovering color for geometries.
  hoveringGeometry(Color(0x99FF5A13)),

  /// The default selected color for geometries.
  selectedGeometry(Color(0x99706DF6));

  const ArcadiaColor(this.color);

  /// The concrete color consumed by Flutter painting APIs.
  final Color color;
}
