import 'package:flutter/material.dart';

/// Semantic accent colors used by diary widgets.
class DiaryAccentColors extends ThemeExtension<DiaryAccentColors> {
  /// Creates diary accent colors.
  const DiaryAccentColors({
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
    required this.heart,
    required this.heartDark,
    required this.steps,
    required this.stepsDark,
  });

  /// Default diary accent colors.
  static const fallback = DiaryAccentColors(
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
    heart: Color(0xFFE11D48),
    heartDark: Color(0xFFFB7185),
    steps: Color(0xFF6366F1),
    stepsDark: Color(0xFF818CF8),
  );

  /// Returns diary accent colors from the active theme or defaults.
  static DiaryAccentColors of(BuildContext context) {
    return Theme.of(context).extension<DiaryAccentColors>() ?? fallback;
  }

  /// Activity accent color adapted for brightness.
  Color activityFor(Brightness brightness) {
    return brightness == Brightness.dark ? activityDark : activity;
  }

  /// Activity text accent color adapted for brightness.
  Color activityTextFor(Brightness brightness) {
    return brightness == Brightness.dark ? activityTextDark : activityText;
  }

  /// Steps accent color adapted for brightness.
  Color stepsFor(Brightness brightness) {
    return brightness == Brightness.dark ? stepsDark : steps;
  }

  /// Heart-day accent color adapted for brightness.
  Color heartFor(Brightness brightness) {
    return brightness == Brightness.dark ? heartDark : heart;
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

  /// Heart day.
  final Color heart;

  /// Heart day in dark mode.
  final Color heartDark;

  /// Steps.
  final Color steps;

  /// Steps in dark mode.
  final Color stepsDark;

  @override
  DiaryAccentColors copyWith({
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
    Color? heart,
    Color? heartDark,
    Color? steps,
    Color? stepsDark,
  }) {
    return DiaryAccentColors(
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
      heart: heart ?? this.heart,
      heartDark: heartDark ?? this.heartDark,
      steps: steps ?? this.steps,
      stepsDark: stepsDark ?? this.stepsDark,
    );
  }

  @override
  DiaryAccentColors lerp(ThemeExtension<DiaryAccentColors>? other, double t) {
    if (other is! DiaryAccentColors) {
      return this;
    }
    return DiaryAccentColors(
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
      heart: Color.lerp(heart, other.heart, t)!,
      heartDark: Color.lerp(heartDark, other.heartDark, t)!,
      steps: Color.lerp(steps, other.steps, t)!,
      stepsDark: Color.lerp(stepsDark, other.stepsDark, t)!,
    );
  }
}
