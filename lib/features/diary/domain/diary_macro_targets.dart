import 'dart:math' as math;

/// Macro targets derived for one diary day.
class DiaryMacroTargets {
  /// Creates resolved diary macro targets.
  const DiaryMacroTargets({
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  /// Derives macro targets from a calorie goal using fixed percentages.
  factory DiaryMacroTargets.fromGoalKcal(double goalKcal) {
    final positiveGoalKcal = goalKcal > 0 ? goalKcal : 0.0;
    return DiaryMacroTargets(
      carbs: positiveGoalKcal * 0.45 / 4,
      protein: positiveGoalKcal * 0.25 / 4,
      fat: positiveGoalKcal * 0.30 / 9,
    );
  }

  /// Calculates macro targets based on body weight multipliers and remaining
  /// calories for carbs.
  factory DiaryMacroTargets.calculate({
    required double goalKcal,
    required double weightKg,
    required double proteinGramsPerKg,
    required double fatGramsPerKg,
  }) {
    if (goalKcal <= 0) {
      return const DiaryMacroTargets(carbs: 0, protein: 0, fat: 0);
    }
    final safeWeight = weightKg > 0 ? weightKg : 70;
    final proteinGrams = safeWeight * proteinGramsPerKg;
    final fatGrams = safeWeight * fatGramsPerKg;
    final proteinKcal = proteinGrams * 4;
    final fatKcal = fatGrams * 9;
    final remainingKcal = math.max(0, goalKcal - (proteinKcal + fatKcal));
    final carbsGrams = remainingKcal / 4;

    return DiaryMacroTargets(
      carbs: carbsGrams,
      protein: proteinGrams,
      fat: fatGrams,
    );
  }

  /// Carb goal in grams.
  final double carbs;

  /// Protein goal in grams.
  final double protein;

  /// Fat goal in grams.
  final double fat;
}
