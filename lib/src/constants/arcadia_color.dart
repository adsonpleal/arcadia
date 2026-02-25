import 'dart:ui';

typedef _C = ArcadiaColor;

/// Colors for the arcadia project.
///
/// This project is dark mode only, so no need to have colors based of
/// a theme.
class ArcadiaColor extends Color {
  /// Default constructor for [ArcadiaColor].
  const ArcadiaColor(super.value);

  /// Primary app background color.
  static const background = _C(0xFF252825);

  /// Surface color for elevated components.
  static const surface = _C(0xFF433F3F);

  /// Positive emphasis color.
  static const positive = _C(0xFF0F9224);

  /// Primary foreground color.
  static const primary = _C(0xFFFFFFFF);

  /// Secondary foreground color.
  static const secondary = _C(0x22FFFFFF);

  /// Border and separator color.
  static const border = _C(0xFF696565);

  /// The default hover color.
  static const hover = _C(0xFF565353);

  /// Active state color.
  static const active = _C(0xFF696565);

  /// Accent color.
  static const accent = _C(0xFFF76902);

  /// Active accent color.
  static const accentActive = _C(0xFFF50BDE);

  /// Muted accent overlay.
  static const accentMuted = _C(0x99FF5A13);

  /// Active primary overlay.
  static const primaryActive = _C(0x99706DF6);
}
