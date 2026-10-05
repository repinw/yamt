import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/app_accent.dart';

/// Semantic accent colors used by compact metric widgets.
class MetricAccentColors extends ThemeExtension<MetricAccentColors> {
  /// Creates metric accent colors.
  const new({
    required this.activity,
    required this.activityDark,
    required this.activityText,
    required this.activityTextDark,
    required this.weight,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.meal,
    required this.today,
    required this.steps,
    required this.stepsDark,
  });

  /// Builds metric accent colors for the brightness of [colors].
  ///
  /// The data colors are harmonized against the lime accent, so they look
  /// the same whatever accent the user picks. Only [meal] and [today] follow
  /// the picked accent through `colors.primary`.
  factory fromColorScheme(ColorScheme colors) {
    final lime = AppAccent.lime.tonesFor(colors.brightness).fill;
    final warm = _harmonize(const Color(0xFFF97316), lime, 0.14);
    final warmDark = _harmonize(const Color(0xFFFBBF24), lime, 0.1);
    final steps = _harmonize(const Color(0xFF6366F1), lime, 0.2);
    final stepsDark = _harmonize(const Color(0xFF818CF8), lime, 0.16);

    return MetricAccentColors(
      activity: _tone(warm, lightness: 0.52, minSaturation: 0.68),
      activityDark: _tone(warmDark, lightness: 0.7, minSaturation: 0.72),
      activityText: _tone(warm, lightness: 0.44, minSaturation: 0.68),
      activityTextDark: _tone(warmDark, lightness: 0.72, minSaturation: 0.72),
      weight: _tone(
        _harmonize(const Color(0xFF0EA5E9), lime, 0.12),
        lightness: colors.brightness == Brightness.dark ? 0.68 : 0.48,
        minSaturation: 0.62,
      ),
      carbs: _tone(
        _harmonize(const Color(0xFF2563EB), lime, 0.08),
        lightness: colors.brightness == Brightness.dark ? 0.66 : 0.5,
        minSaturation: 0.62,
      ),
      protein: _tone(
        _harmonize(const Color(0xFFE11D48), lime, 0.08),
        lightness: colors.brightness == Brightness.dark ? 0.66 : 0.5,
        minSaturation: 0.62,
      ),
      fat: _tone(
        _harmonize(const Color(0xFFF59E0B), lime, 0.08),
        lightness: colors.brightness == Brightness.dark ? 0.68 : 0.5,
        minSaturation: 0.66,
      ),
      meal: colors.primary,
      today: colors.primary,
      steps: _tone(steps, lightness: 0.5, minSaturation: 0.58),
      stepsDark: _tone(stepsDark, lightness: 0.7, minSaturation: 0.58),
    );
  }

  /// Default metric accent colors.
  static const fallback = MetricAccentColors(
    activity: Color(0xFFF97316),
    activityDark: Color(0xFFFBBF24),
    activityText: Color(0xFFEA580C),
    activityTextDark: Color(0xFFF59E0B),
    weight: Color(0xFF3B82F6),
    carbs: Color(0xFF3B82F6),
    protein: Color(0xFFEF4444),
    fat: Color(0xFFEAB308),
    meal: Color(0xFF059669),
    today: Color(0xFF10B981),
    steps: Color(0xFF6366F1),
    stepsDark: Color(0xFF818CF8),
  );

  /// Returns metric accent colors from the active theme or defaults.
  // ignore: prefer_constructors_over_static_methods
  static MetricAccentColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<MetricAccentColors>() ??
        MetricAccentColors.fromColorScheme(theme.colorScheme);
  }

  /// Activity accent color adapted for brightness.
  Color activityFor(Brightness brightness) {
    return brightness == Brightness.dark ? activityDark : activity;
  }

  /// Activity text accent color adapted for brightness.
  Color activityTextFor(Brightness brightness) {
    return brightness == Brightness.dark ? activityTextDark : activityText;
  }

  /// Activity.
  final Color activity;

  /// Activity in dark mode.
  final Color activityDark;

  /// Activity text.
  final Color activityText;

  /// Activity text in dark mode.
  final Color activityTextDark;

  /// Weight.
  final Color weight;

  /// Carbs.
  final Color carbs;

  /// Protein.
  final Color protein;

  /// Fat.
  final Color fat;

  /// Meal.
  final Color meal;

  /// Today/current day.
  final Color today;

  /// Steps.
  final Color steps;

  /// Steps in dark mode.
  final Color stepsDark;

  @override
  MetricAccentColors copyWith({
    Color? activity,
    Color? activityDark,
    Color? activityText,
    Color? activityTextDark,
    Color? weight,
    Color? carbs,
    Color? protein,
    Color? fat,
    Color? meal,
    Color? today,
    Color? steps,
    Color? stepsDark,
  }) {
    return MetricAccentColors(
      activity: activity ?? this.activity,
      activityDark: activityDark ?? this.activityDark,
      activityText: activityText ?? this.activityText,
      activityTextDark: activityTextDark ?? this.activityTextDark,
      weight: weight ?? this.weight,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      meal: meal ?? this.meal,
      today: today ?? this.today,
      steps: steps ?? this.steps,
      stepsDark: stepsDark ?? this.stepsDark,
    );
  }

  @override
  MetricAccentColors lerp(ThemeExtension<MetricAccentColors>? other, double t) {
    if (other is! MetricAccentColors) {
      return this;
    }
    return MetricAccentColors(
      activity: Color.lerp(activity, other.activity, t)!,
      activityDark: Color.lerp(activityDark, other.activityDark, t)!,
      activityText: Color.lerp(activityText, other.activityText, t)!,
      activityTextDark: Color.lerp(
        activityTextDark,
        other.activityTextDark,
        t,
      )!,
      weight: Color.lerp(weight, other.weight, t)!,
      carbs: Color.lerp(carbs, other.carbs, t)!,
      protein: Color.lerp(protein, other.protein, t)!,
      fat: Color.lerp(fat, other.fat, t)!,
      meal: Color.lerp(meal, other.meal, t)!,
      today: Color.lerp(today, other.today, t)!,
      steps: Color.lerp(steps, other.steps, t)!,
      stepsDark: Color.lerp(stepsDark, other.stepsDark, t)!,
    );
  }

  static Color _harmonize(Color color, Color seed, double amount) {
    return Color.lerp(color, seed, amount)!;
  }

  static Color _tone(
    Color color, {
    required double lightness,
    required double minSaturation,
  }) {
    final hsl = HSLColor.fromColor(color);
    final saturation = hsl.saturation.clamp(minSaturation, 1.0);
    final resolvedLightness = lightness.clamp(0.0, 1.0);
    return hsl
        .withSaturation(saturation)
        .withLightness(resolvedLightness)
        .toColor();
  }
}
