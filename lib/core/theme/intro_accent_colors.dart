import 'package:material_ui/material_ui.dart';

/// Accent colors of the onboarding intro chapters.
///
/// Every chapter owns one accent that tints its kicker, its highlighted words,
/// its progress segment, and the wash behind the page. The values are
/// harmonized against the active `colorScheme.primary` and toned per
/// brightness, so a user-picked theme color still comes through.
class IntroAccentColors extends ThemeExtension<IntroAccentColors> {
  /// Creates intro accent colors.
  const new({
    required this.amber,
    required this.cyan,
    required this.emerald,
    required this.violet,
    required this.sky,
    required this.rose,
  });

  /// Builds intro accents from the active app color scheme.
  factory fromColorScheme(ColorScheme colors) {
    final isDark = colors.brightness == Brightness.dark;
    final lightness = isDark ? 0.68 : 0.46;

    Color accent(Color base) {
      return _tone(
        Color.lerp(base, colors.primary, _harmonizeAmount)!,
        lightness: lightness,
        minSaturation: 0.6,
      );
    }

    return IntroAccentColors(
      amber: accent(const Color(0xFFF59E0B)),
      cyan: accent(const Color(0xFF06B6D4)),
      emerald: accent(const Color(0xFF10B981)),
      violet: accent(const Color(0xFF8B5CF6)),
      sky: accent(const Color(0xFF0EA5E9)),
      rose: accent(const Color(0xFFF43F5E)),
    );
  }

  /// How far each accent is pulled towards the theme's primary color.
  static const _harmonizeAmount = 0.16;

  /// Default intro accents, used before a theme provides them.
  static const fallback = IntroAccentColors(
    amber: Color(0xFFF59E0B),
    cyan: Color(0xFF06B6D4),
    emerald: Color(0xFF10B981),
    violet: Color(0xFF8B5CF6),
    sky: Color(0xFF0EA5E9),
    rose: Color(0xFFF43F5E),
  );

  /// Warm accent.
  final Color amber;

  /// Cool accent.
  final Color cyan;

  /// Green accent.
  final Color emerald;

  /// Purple accent.
  final Color violet;

  /// Blue accent.
  final Color sky;

  /// Red accent.
  final Color rose;

  @override
  IntroAccentColors copyWith({
    Color? amber,
    Color? cyan,
    Color? emerald,
    Color? violet,
    Color? sky,
    Color? rose,
  }) {
    return IntroAccentColors(
      amber: amber ?? this.amber,
      cyan: cyan ?? this.cyan,
      emerald: emerald ?? this.emerald,
      violet: violet ?? this.violet,
      sky: sky ?? this.sky,
      rose: rose ?? this.rose,
    );
  }

  @override
  IntroAccentColors lerp(ThemeExtension<IntroAccentColors>? other, double t) {
    if (other is! IntroAccentColors) {
      return this;
    }
    return IntroAccentColors(
      amber: Color.lerp(amber, other.amber, t)!,
      cyan: Color.lerp(cyan, other.cyan, t)!,
      emerald: Color.lerp(emerald, other.emerald, t)!,
      violet: Color.lerp(violet, other.violet, t)!,
      sky: Color.lerp(sky, other.sky, t)!,
      rose: Color.lerp(rose, other.rose, t)!,
    );
  }

  static Color _tone(
    Color color, {
    required double lightness,
    required double minSaturation,
  }) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness(lightness.clamp(0.0, 1.0))
        .withSaturation(
          hsl.saturation < minSaturation ? minSaturation : hsl.saturation,
        )
        .toColor();
  }
}

/// Returns the intro accents of the active theme.
IntroAccentColors introAccentsOf(BuildContext context) {
  final theme = Theme.of(context);
  return theme.extension<IntroAccentColors>() ??
      IntroAccentColors.fromColorScheme(theme.colorScheme);
}
