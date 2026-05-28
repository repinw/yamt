import 'package:flutter/material.dart';
import 'package:yamt/core/theme/app_theme_layout_tokens.dart';

/// Top-level colors used by app theme setup.
abstract final class AppColors {
  /// Default seed color for generated color schemes.
  static const Color seed = AppSeedColors.teal;
}

/// Available theme seed colors users can choose from.
abstract final class AppSeedColors {
  /// Lime seed color.
  static const Color lime = Color(0xFF29F006);

  /// Blue seed color.
  static const Color blue = Color(0xFF0D47A1);

  /// Teal seed color.
  static const Color teal = Color(0xFF00695C);

  /// Pink seed color.
  static const Color pink = Color.fromARGB(255, 255, 0, 111);

  /// Orange seed color.
  static const Color orange = Color(0xFFE65100);

  /// All supported seed colors.
  static const List<Color> values = <Color>[lime, blue, teal, pink, orange];
}

/// Background tuning values for light and dark surfaces.
abstract final class AppThemeBackground {
  // Subtle light/dark tinting tuned against Material 3 surface tones.
  /// Surface tint alpha for light mode.
  static const double lightTintAlpha = 0.04;

  /// Surface tint alpha for dark mode.
  static const double darkTintAlpha = 0.18;
  // Borders stay almost invisible in dark mode, like the diary mock.

  /// Card border alpha for light mode.
  static const double lightCardBorderAlpha = 0.18;

  /// Card border alpha for dark mode.
  static const double darkCardBorderAlpha = 0.07;
}

/// App-wide editorial design tokens for surfaces and accents.
abstract final class AppEditorial {
  /// Warning accent.
  static const Color warning = Color(0xFFAB2D00);

  /// Shadow alpha for ambient overlays.
  static const double ambientShadowAlpha = 0.06;

  /// Border alpha for ghost outlines.
  static const double ghostBorderAlpha = 0.08;

  /// Surface opacity for glass panels.
  static const double glassOpacity = 0.8;

  /// Blur amount for glass panels.
  static const double glassBlur = 20;

  /// Editorial card radius.
  static const double cardRadius = AppThemeRadius.xl;

  /// Square image tile size.
  static const double imageTileSize = 56;

  /// Context floating action button size.
  static const double contextFabSize = 64;

  /// Highlight size for empty-state action.
  static const double emptyStateActionHighlightSize = 96;

  /// Halo size for empty-state action.
  static const double emptyStateActionHaloSize = 68;

  /// Light-mode blur radius for empty-state action.
  static const double emptyStateActionLightBlurRadius = 24;

  /// Dark-mode blur radius for empty-state action.
  static const double emptyStateActionDarkBlurRadius = 28;

  /// Light-mode spread radius for empty-state action.
  static const double emptyStateActionLightSpreadRadius = 3;

  /// Dark-mode spread radius for empty-state action.
  static const double emptyStateActionDarkSpreadRadius = 4;

  /// Progress bar height.
  static const double progressHeight = 8;
}

/// Derived editorial surfaces built from current color scheme.
abstract final class AppEditorialSurfaces {
  /// App background tied to brightness and chosen accent hue.
  static Color appBackground(ColorScheme colors) {
    return _accentSurface(
      colors,
      darkLightness: 0.065,
      lightLightness: 0.96,
      darkSaturationFactor: 0.34,
      lightSaturationFactor: 0.22,
      minSaturation: 0.08,
      maxSaturation: 0.22,
    );
  }

  /// Lowest-elevation lifted card surface.
  static Color liftedCard(ColorScheme colors) {
    return _accentSurface(
      colors,
      darkLightness: 0.12,
      lightLightness: 0.99,
      darkSaturationFactor: 0.28,
      lightSaturationFactor: 0.13,
      minSaturation: 0.06,
      maxSaturation: 0.18,
    );
  }

  /// Section background surface.
  static Color section(ColorScheme colors) {
    return _accentSurface(
      colors,
      darkLightness: 0.16,
      lightLightness: 0.935,
      darkSaturationFactor: 0.24,
      lightSaturationFactor: 0.16,
      minSaturation: 0.06,
      maxSaturation: 0.18,
    );
  }

  /// Solid chrome surface.
  static Color glass(ColorScheme colors) => section(colors);

  /// Track color for compact progress bars on lifted cards.
  static Color compactProgressTrack(ColorScheme colors) {
    final isDark = colors.brightness == Brightness.dark;
    final overlay = (isDark ? Colors.black : colors.outlineVariant).withValues(
      alpha: isDark ? 0.28 : 0.34,
    );

    return Color.alphaBlend(overlay, liftedCard(colors));
  }

  /// Border color for solid cards.
  static Color cardBorder(ColorScheme colors) {
    return _accentSurface(
      colors,
      darkLightness: 0.18,
      lightLightness: 0.78,
      darkSaturationFactor: 0.24,
      lightSaturationFactor: 0.16,
      minSaturation: 0.06,
      maxSaturation: 0.2,
    );
  }

  /// Border color for solid cards after mode-specific opacity.
  static Color solidCardBorder(ColorScheme colors) {
    final alpha = colors.brightness == Brightness.dark
        ? AppThemeBackground.darkCardBorderAlpha
        : AppThemeBackground.lightCardBorderAlpha;

    return cardBorder(colors).withValues(alpha: alpha);
  }

  /// Border color for ghost outlines.
  static Color ghostBorder(ColorScheme colors) {
    return cardBorder(colors).withValues(alpha: AppEditorial.ghostBorderAlpha);
  }

  /// Accent color for repeated ingredient markers.
  static Color ingredientAccent(ColorScheme colors, int index) {
    final palette = <Color>[
      colors.primary,
      colors.secondary,
      colors.tertiary,
      colors.inversePrimary,
    ];
    return palette[index % palette.length];
  }

  /// Ambient shadow color.
  static Color ambientShadow(ColorScheme colors) {
    return Colors.black.withValues(
      alpha: colors.brightness == Brightness.dark ? 0.34 : 0.1,
    );
  }

  /// Standard ambient box shadow.
  static BoxShadow ambientBoxShadow(
    ColorScheme colors, {
    double blurRadius = 36,
    Offset offset = const Offset(0, 18),
  }) {
    return BoxShadow(
      color: ambientShadow(colors),
      blurRadius: blurRadius,
      offset: offset,
    );
  }

  /// Card decoration with border and ambient shadow.
  static BoxDecoration liftedCardDecoration(
    ColorScheme colors, {
    required BorderRadiusGeometry borderRadius,
    Color? color,
    double blurRadius = 36,
    Offset shadowOffset = const Offset(0, 18),
  }) {
    return _layeredDecoration(
      colors: colors,
      color: color ?? liftedCard(colors),
      borderRadius: borderRadius,
      blurRadius: blurRadius,
      shadowOffset: shadowOffset,
    );
  }

  /// Primary editorial gradient.
  static LinearGradient soulGradient(ColorScheme colors) {
    final primaryHsl = HSLColor.fromColor(colors.primary);
    final dimLightness = colors.brightness == Brightness.dark
        ? (primaryHsl.lightness - 0.1).clamp(0.0, 1.0)
        : (primaryHsl.lightness - 0.08).clamp(0.0, 1.0);
    final dimColor = primaryHsl.withLightness(dimLightness).toColor();
    final start = Color.alphaBlend(
      colors.primary.withValues(alpha: 0.92),
      colors.primary,
    );
    final end = Color.alphaBlend(
      dimColor.withValues(alpha: 0.92),
      colors.primary,
    );

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [start, end],
      transform: const GradientRotation(0.45),
    );
  }

  /// Background gradient for editorial app screens.
  static LinearGradient backdropGradient(ColorScheme colors) {
    final isDark = colors.brightness == Brightness.dark;
    final startColor = Color.alphaBlend(
      colors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
      colors.surface,
    );
    final middleColor = Color.alphaBlend(
      colors.surfaceContainerLowest.withValues(alpha: isDark ? 0.4 : 0.9),
      colors.surface,
    );
    final endColor = Color.alphaBlend(
      colors.outlineVariant.withValues(alpha: isDark ? 0.16 : 0.1),
      colors.surface,
    );

    return LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [startColor, middleColor, endColor],
      stops: const [0, 0.5, 1],
    );
  }

  static BoxDecoration _layeredDecoration({
    required ColorScheme colors,
    required Color color,
    required BorderRadiusGeometry borderRadius,
    required double blurRadius,
    required Offset shadowOffset,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius,
      border: Border.all(color: solidCardBorder(colors)),
      boxShadow: [
        ambientBoxShadow(colors, blurRadius: blurRadius, offset: shadowOffset),
      ],
    );
  }

  static Color _accentSurface(
    ColorScheme colors, {
    required double darkLightness,
    required double lightLightness,
    required double darkSaturationFactor,
    required double lightSaturationFactor,
    required double minSaturation,
    required double maxSaturation,
  }) {
    final isDark = colors.brightness == Brightness.dark;
    final accent = HSLColor.fromColor(colors.primary);
    final saturationFactor = isDark
        ? darkSaturationFactor
        : lightSaturationFactor;
    final saturation = (accent.saturation * saturationFactor).clamp(
      minSaturation,
      maxSaturation,
    );
    final lightness = isDark ? darkLightness : lightLightness;
    return accent.withSaturation(saturation).withLightness(lightness).toColor();
  }
}

/// Quiet grouped-list surfaces used by settings-style pages.
abstract final class AppQuietSurfaces {
  /// Shared card radius for quiet grouped cards.
  static const double cardRadius = 16;

  /// Shared quiet page background.
  static Color pageBackground(ColorScheme colors) {
    return Color.alphaBlend(
      colors.primary.withValues(alpha: 0.035),
      colors.surface,
    );
  }

  /// Shared quiet card border radius.
  static BorderRadius cardBorderRadius() => BorderRadius.circular(cardRadius);

  /// Shared quiet card decoration.
  static BoxDecoration cardDecoration(
    ColorScheme colors, {
    bool withShadow = true,
  }) {
    final isDark = colors.brightness == Brightness.dark;

    return BoxDecoration(
      color: isDark ? colors.surfaceContainerLow : colors.surface,
      borderRadius: cardBorderRadius(),
      border: Border.all(
        color: colors.outlineVariant.withValues(alpha: isDark ? 0.24 : 0.18),
      ),
      boxShadow: withShadow
          ? [
              BoxShadow(
                color: colors.shadow.withValues(alpha: isDark ? 0.18 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    );
  }
}

/// App-wide raised card design used by primary content cards.
abstract final class AppSurfaceCard {
  /// Shared radius for primary content cards.
  static const double radius = 20;

  /// Shared padding for primary content cards.
  static const EdgeInsets padding = EdgeInsets.all(AppThemeSpacing.md);

  /// Shared card border radius.
  static BorderRadius borderRadius() => BorderRadius.circular(radius);

  /// Decoration for raised content cards.
  static BoxDecoration decoration(ColorScheme colors) {
    final isDark = colors.brightness == Brightness.dark;

    return BoxDecoration(
      color: AppEditorialSurfaces.liftedCard(colors),
      borderRadius: borderRadius(),
      border: Border.all(color: AppEditorialSurfaces.solidCardBorder(colors)),
      boxShadow: [
        BoxShadow(
          color: AppEditorialSurfaces.ambientShadow(colors),
          blurRadius: isDark ? 18 : 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
