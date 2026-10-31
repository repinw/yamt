import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/app_accent.dart';
import 'package:yamt/core/theme/app_custom_colors.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';

/// Contrast below which the accent is too light as text on the card.
const _accentTextContrast = 3.0;

/// How far a too light accent moves toward the text color as text.
const _accentTextInk = 0.45;

/// One step between surfaces, toward the text color.
const _surfaceStep = 0.04;

/// How far an empty bar track fades from the lines toward the card.
const _trackFade = 0.4;

/// How much of the accent or signal tints a container on the card.
const _containerTint = 0.22;

/// The theme colors of the design "Individuell". Colors the user does not
/// pick are steps between the picked ones.
extension AppCustomThemeColors on AppCustomColors {
  /// The food label colors: the picked ones over the Graphit colors of
  /// [base].
  FoodLabelColors get labelColors {
    final graphit = base == Brightness.dark
        ? FoodLabelColors.dark
        : FoodLabelColors.light;
    final card = this[AppCustomColor.card];
    final ink = this[AppCustomColor.ink];
    final accent = this[AppCustomColor.accent];
    final lines = this[AppCustomColor.lines];
    return graphit.copyWith(
      paper: this[AppCustomColor.paper],
      card: card,
      ink: ink,
      muted: this[AppCustomColor.muted],
      rule: lines,
      accent: accent,
      onAccent: readableOn(accent, graphit.onAccent),
      // Links and hints need to read on the card.
      accentText: contrastRatio(accent, card) >= _accentTextContrast
          ? accent
          : Color.lerp(accent, ink, _accentTextInk),
      tile: Color.lerp(card, ink, _surfaceStep),
      onTile: ink,
      track: Color.lerp(lines, card, _trackFade),
      plan: this[AppCustomColor.plan],
    );
  }

  /// The Material colors around [labels], the [labelColors] of these colors.
  ColorScheme colorSchemeWith(FoodLabelColors labels) {
    final isDark = base == Brightness.dark;
    final signal = this[AppCustomColor.signal];
    Color step(int steps) =>
        Color.lerp(labels.card, labels.ink, _surfaceStep * steps)!;
    return ColorScheme(
      brightness: base,
      primary: labels.accent,
      onPrimary: labels.onAccent,
      primaryContainer: Color.lerp(labels.card, labels.accent, _containerTint),
      onPrimaryContainer: labels.ink,
      secondary: labels.accentText,
      onSecondary: readableOn(labels.accentText, labels.ink),
      secondaryContainer: step(2),
      onSecondaryContainer: labels.ink,
      // The Graphit tertiary blues, as in the light and dark design.
      tertiary: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
      onTertiary: isDark ? const Color(0xFF003258) : const Color(0xFFFFFFFF),
      error: signal,
      onError: readableOn(signal, labels.ink),
      errorContainer: Color.lerp(labels.card, signal, _containerTint),
      onErrorContainer: labels.ink,
      surface: labels.paper,
      onSurface: labels.ink,
      onSurfaceVariant: labels.muted,
      surfaceContainerLowest: labels.tile,
      surfaceContainerLow: labels.card,
      surfaceContainer: step(1),
      surfaceContainerHigh: step(2),
      surfaceContainerHighest: step(3),
      outline: labels.muted,
      outlineVariant: labels.rule,
      shadow: isDark ? const Color(0xFF000000) : labels.ink,
      // Inverse parts of Material widgets: the text color as the ground.
      inverseSurface: labels.ink,
      onInverseSurface: labels.paper,
      inversePrimary: labels.accent,
    );
  }

  /// The metric colors of [colorScheme] with the picked macro colors, shown
  /// as picked.
  MetricAccentColors metricColorsWith(ColorScheme colorScheme) {
    return MetricAccentColors.fromColorScheme(colorScheme).copyWith(
      protein: this[AppCustomColor.protein],
      carbs: this[AppCustomColor.carbs],
      fat: this[AppCustomColor.fat],
      macrosAsPicked: true,
    );
  }
}
