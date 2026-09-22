import 'package:yamt/features/calories/domain/macro_budget_calculator.dart';

/// Computed macro targets and percentages for the live preview card.
final class SettingsMacroGoalsPreviewData {
  /// Creates the macro goals preview data.
  const new({
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbsGrams,
    required this.proteinPct,
    required this.fatPct,
    required this.carbsPct,
    required this.isBudgetExceeded,
  });

  /// Computes macro targets and percentages from multipliers and goal calories.
  factory compute({
    required double goalKcal,
    required double weightKg,
    required double proteinMultiplier,
    required double fatMultiplier,
  }) {
    final rawProteinGrams = (weightKg * proteinMultiplier).round();
    final rawFatGrams = (weightKg * fatMultiplier).round();
    final rawProteinKcal = rawProteinGrams * 4;
    final rawFatKcal = rawFatGrams * 9;
    final isBudgetExceeded = (rawProteinKcal + rawFatKcal) > goalKcal;

    final int proteinGrams;
    final int fatGrams;
    final int carbsGrams;
    if (isBudgetExceeded) {
      proteinGrams = rawProteinGrams;
      fatGrams = rawFatGrams;
      carbsGrams = 0;
    } else {
      final targets = MacroBudgetCalculator.calculate(
        goalKcal: goalKcal,
        weightKg: weightKg,
        proteinGramsPerKg: proteinMultiplier,
        fatGramsPerKg: fatMultiplier,
      );
      proteinGrams = targets.protein.round();
      fatGrams = targets.fat.round();
      carbsGrams = targets.carbs.round();
    }

    final proteinKcal = proteinGrams * 4;
    final fatKcal = fatGrams * 9;
    final carbsKcal = carbsGrams * 4;
    final totalEffectiveKcal = proteinKcal + fatKcal + carbsKcal;

    final proteinPct = totalEffectiveKcal > 0
        ? (proteinKcal / totalEffectiveKcal * 100).round()
        : 0;
    final fatPct = totalEffectiveKcal > 0
        ? (fatKcal / totalEffectiveKcal * 100).round()
        : 0;
    final carbsPct = totalEffectiveKcal > 0
        ? (carbsKcal / totalEffectiveKcal * 100).round()
        : 0;

    return SettingsMacroGoalsPreviewData(
      proteinGrams: proteinGrams,
      fatGrams: fatGrams,
      carbsGrams: carbsGrams,
      proteinPct: proteinPct,
      fatPct: fatPct,
      carbsPct: carbsPct,
      isBudgetExceeded: isBudgetExceeded,
    );
  }

  /// Target protein in grams.
  final int proteinGrams;

  /// Target fat in grams.
  final int fatGrams;

  /// Target carbohydrates in grams.
  final int carbsGrams;

  /// Protein percentage of total calories.
  final int proteinPct;

  /// Fat percentage of total calories.
  final int fatPct;

  /// Carbs percentage of total calories.
  final int carbsPct;

  /// Whether protein + fat already exceed the calorie goal.
  final bool isBudgetExceeded;
}
