import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

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
  // Borders stay subtle in dark mode and clearer in light mode.

  /// Card border alpha for light mode.
  static const double lightCardBorderAlpha = 0.28;

  /// Card border alpha for dark mode.
  static const double darkCardBorderAlpha = 0.18;
}

/// Editorial design tokens for inventory surfaces and accents.
abstract final class AppInventoryEditorial {
  /// Main editorial accent.
  static const Color primary = Color(0xFF006941);

  /// Darker primary accent.
  static const Color primaryDim = Color(0xFF005C38);

  /// Warning accent.
  static const Color warning = Color(0xFFAB2D00);

  /// Shadow alpha for ambient overlays.
  static const double ambientShadowAlpha = 0.06;

  /// Border alpha for ghost outlines.
  static const double ghostBorderAlpha = 0.15;

  /// Surface opacity for glass panels.
  static const double glassOpacity = 0.8;

  /// Blur amount for glass panels.
  static const double glassBlur = 20;

  /// Editorial card radius.
  static const double cardRadius = AppRadius.xl;

  /// Square image tile size.
  static const double imageTileSize = 56;

  /// Action tile size.
  static const double actionTileSize = 48;

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
abstract final class AppInventoryEditorialSurfaces {
  /// Lowest-elevation lifted card surface.
  static Color liftedCard(ColorScheme colors) => colors.surfaceContainerLowest;

  /// Section background surface.
  static Color section(ColorScheme colors) => colors.surfaceContainerLow;

  /// Translucent glass-like surface.
  static Color glass(ColorScheme colors) {
    return colors.surfaceContainerLow.withValues(
      alpha: AppInventoryEditorial.glassOpacity,
    );
  }

  /// Border color for ghost outlines.
  static Color ghostBorder(ColorScheme colors) {
    return colors.outlineVariant.withValues(
      alpha: AppInventoryEditorial.ghostBorderAlpha,
    );
  }

  /// Ambient shadow color.
  static Color ambientShadow(ColorScheme colors) {
    return colors.onSurface.withValues(
      alpha: AppInventoryEditorial.ambientShadowAlpha,
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

  /// Background gradient for editorial inventory screens.
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
      border: Border.all(color: ghostBorder(colors)),
      boxShadow: [
        ambientBoxShadow(colors, blurRadius: blurRadius, offset: shadowOffset),
      ],
    );
  }
}
