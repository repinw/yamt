/// Macro targets derived for one diary day.
class DiaryMacroTargets {
  /// Creates resolved diary macro targets.
  const DiaryMacroTargets({
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  /// Derives macro targets from a calorie goal.
  factory DiaryMacroTargets.fromGoalKcal(double goalKcal) {
    final positiveGoalKcal = goalKcal > 0 ? goalKcal : 0.0;
    return DiaryMacroTargets(
      carbs: positiveGoalKcal * 0.45 / 4,
      protein: positiveGoalKcal * 0.25 / 4,
      fat: positiveGoalKcal * 0.30 / 9,
    );
  }

  /// Carb goal in grams.
  final double carbs;

  /// Protein goal in grams.
  final double protein;

  /// Fat goal in grams.
  final double fat;
}
