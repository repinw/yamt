import 'package:material_ui/material_ui.dart';

/// The tones of an accent in one brightness: `fill` for main buttons, bars
/// and markers, `text` for accent text that stays readable on the page, and
/// `container` for soft accent surfaces such as badges and selected rows.
typedef AppAccentTones = ({Color fill, Color text, Color container});

/// Accent colors the user can pick in the settings.
enum AppAccent {
  /// The Graphit lime, the default.
  lime(
    light: (
      fill: Color(0xFFB6E21F),
      text: Color(0xFF4F6A00),
      container: Color(0xFFE2F78A),
    ),
    dark: (
      fill: Color(0xFFC7F23A),
      text: Color(0xFFD4F55F),
      container: Color(0xFF3B4D00),
    ),
  ),

  /// Pink, kept away from the error red that marks "over the goal".
  pink(
    light: (
      fill: Color(0xFFE64AA8),
      text: Color(0xFFA8197C),
      container: Color(0xFFF4AED8),
    ),
    dark: (
      fill: Color(0xFFF472C8),
      text: Color(0xFFF9A3DA),
      container: Color(0xFF49223C),
    ),
  ),

  /// Violet.
  violet(
    light: (
      fill: Color(0xFF7C3AED),
      text: Color(0xFF6D28D9),
      container: Color(0xFFC4A6F7),
    ),
    dark: (
      fill: Color(0xFFA78BFA),
      text: Color(0xFFC4B5FD),
      container: Color(0xFF322A4B),
    ),
  ),

  /// Cyan.
  cyan(
    light: (
      fill: Color(0xFF22D3EE),
      text: Color(0xFF155E75),
      container: Color(0xFF9CEBF7),
    ),
    dark: (
      fill: Color(0xFF22D3EE),
      text: Color(0xFF67E8F9),
      container: Color(0xFF0A3F47),
    ),
  ),

  /// Emerald.
  emerald(
    light: (
      fill: Color(0xFF34D399),
      text: Color(0xFF047857),
      container: Color(0xFFA4EBD1),
    ),
    dark: (
      fill: Color(0xFF34D399),
      text: Color(0xFF6EE7B7),
      container: Color(0xFF103F2E),
    ),
  );

  new({required this.light, required this.dark});

  /// Tones on the light theme.
  final AppAccentTones light;

  /// Tones on the dark theme.
  final AppAccentTones dark;

  /// Tones for [brightness].
  AppAccentTones tonesFor(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// WCAG contrast ratio between [a] and [b], from 1 to 21.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
}
