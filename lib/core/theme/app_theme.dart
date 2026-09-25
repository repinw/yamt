import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';

/// Centralized app themes for light and dark modes.
abstract final class AppTheme {
  /// Builds standard light Material 3 theme with Graphit colors.
  static ThemeData light() {
    const labelColors = FoodLabelColors.light;
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: labelColors.accent,
      onPrimary: labelColors.onAccent,
      primaryContainer: const Color(0xFFE2F78A),
      onPrimaryContainer: labelColors.ink,
      secondary: labelColors.accentText,
      onSecondary: const Color(0xFFFFFFFF),
      secondaryContainer: const Color(0xFFE5ECC8),
      onSecondaryContainer: labelColors.ink,
      tertiary: const Color(0xFF3B82F6),
      onTertiary: const Color(0xFFFFFFFF),
      error: const Color(0xFFBA1A1A),
      onError: const Color(0xFFFFFFFF),
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: labelColors.paper,
      onSurface: labelColors.ink,
      onSurfaceVariant: labelColors.muted,
      surfaceContainerLowest: labelColors.tile,
      surfaceContainerLow: labelColors.card,
      surfaceContainer: const Color(0xFFF4F4F1),
      surfaceContainerHigh: const Color(0xFFEEEEEC),
      surfaceContainerHighest: const Color(0xFFE5E5E1),
      outline: const Color(0xFF757571),
      outlineVariant: labelColors.rule,
      shadow: labelColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      dividerColor: colorScheme.outlineVariant,
      extensions: [
        labelColors,
        MetricAccentColors.fromColorScheme(colorScheme),
      ],
    );
  }

  /// Builds standard dark Material 3 theme with Graphit colors.
  static ThemeData dark() {
    const labelColors = FoodLabelColors.dark;
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: labelColors.accent,
      onPrimary: labelColors.onAccent,
      primaryContainer: const Color(0xFF3B4D00),
      onPrimaryContainer: labelColors.accentText,
      secondary: labelColors.accentText,
      onSecondary: labelColors.onAccent,
      secondaryContainer: const Color(0xFF2C3714),
      onSecondaryContainer: labelColors.accentText,
      tertiary: const Color(0xFF60A5FA),
      onTertiary: const Color(0xFF003258),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: labelColors.paper,
      onSurface: labelColors.ink,
      onSurfaceVariant: labelColors.muted,
      surfaceContainerLowest: const Color(0xFF0C0C0C),
      surfaceContainerLow: labelColors.card,
      surfaceContainer: const Color(0xFF212222),
      surfaceContainerHigh: const Color(0xFF272828),
      surfaceContainerHighest: const Color(0xFF333434),
      outline: const Color(0xFF8A8A85),
      outlineVariant: labelColors.rule,
      shadow: const Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      dividerColor: colorScheme.outlineVariant,
      extensions: [
        labelColors,
        MetricAccentColors.fromColorScheme(colorScheme),
      ],
    );
  }
}
