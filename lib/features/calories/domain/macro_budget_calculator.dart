import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Result containing balanced macro targets in grams.
@immutable
class MacroCalculationResult {
  /// Creates balanced macro targets result.
  const new({required this.carbs, required this.protein, required this.fat});

  /// Carbs in grams.
  final double carbs;

  /// Protein in grams.
  final double protein;

  /// Fat in grams.
  final double fat;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MacroCalculationResult &&
          runtimeType == other.runtimeType &&
          carbs == other.carbs &&
          protein == other.protein &&
          fat == other.fat;

  @override
  int get hashCode => Object.hash(carbs, protein, fat);

  @override
  String toString() =>
      'MacroCalculationResult(carbs: $carbs, protein: $protein, fat: $fat)';
}

/// Domain calculator for macro budgets.
///
/// Protein and fat start from their targets. Carbs get the rest, but at most
/// [maximumCarbsKcalShare] of the kcal; what lies above that cap goes to fat.
/// On a small budget carbs keep [minimumCarbsFloorGrams] first: fat drops to
/// its floor, then protein to [minimumProteinFloorGramsPerKg]; below that,
/// carbs get the rest.
///
/// The default protein target already takes the share above the cap from the
/// weekly average (see `MacroGoalSettings.resolveProteinGrams`), so protein
/// stays the same on every day of the week unless a day's budget is that
/// small.
abstract final class MacroBudgetCalculator {
  /// Minimum carbs floor in grams to prevent ketosis / hypoglycemia.
  static const double minimumCarbsFloorGrams = 100;

  /// Largest share of the daily kcal that carbs get.
  static const double maximumCarbsKcalShare = 0.40;

  /// Minimum physiological fat floor in g/kg body weight.
  static const double minimumFatFloorGramsPerKg = 0.6;

  /// Minimum fat percentage of daily calories.
  static const double minimumFatCalorieFraction = 0.20;

  /// Minimum protein in g/kg body weight. On a small budget protein is cut
  /// for the carb floor only down to this.
  static const double minimumProteinFloorGramsPerKg = 0.8;

  /// Energy density for carbs in standard daily calculation.
  static const double standardCarbKcalPerGram = 4;

  /// Energy density for protein in standard daily calculation.
  static const double standardProteinKcalPerGram = 4;

  /// Energy density for fat in standard daily calculation.
  static const double standardFatKcalPerGram = 9;

  /// Largest carb target in grams for [goalKcal]: the cap share, but never
  /// below the carb floor.
  static double carbsCapGrams(double goalKcal) {
    return math.max<double>(
      minimumCarbsFloorGrams,
      goalKcal * maximumCarbsKcalShare / standardCarbKcalPerGram,
    );
  }

  /// Calculates balanced macros, capping carbs and keeping the carb, fat and
  /// protein floors as far as the kcal allow.
  static MacroCalculationResult calculate({
    required double goalKcal,
    required double weightKg,
    required double proteinGramsPerKg,
    required double fatGramsPerKg,
  }) {
    if (goalKcal <= 0) {
      return const MacroCalculationResult(carbs: 0, protein: 0, fat: 0);
    }
    final safeWeight = weightKg > 0 ? weightKg : 70.0;
    final targetProteinGrams = safeWeight * proteinGramsPerKg;
    final targetFatGrams = safeWeight * fatGramsPerKg;

    if (proteinGramsPerKg == 0 && fatGramsPerKg == 0) {
      return MacroCalculationResult(
        carbs: goalKcal / standardCarbKcalPerGram,
        protein: 0,
        fat: 0,
      );
    }

    return _balanceMacros(
      goalKcal: goalKcal,
      safeWeight: safeWeight,
      targetProteinGrams: targetProteinGrams,
      targetFatGrams: targetFatGrams,
    );
  }

  static MacroCalculationResult _balanceMacros({
    required double goalKcal,
    required double safeWeight,
    required double targetProteinGrams,
    required double targetFatGrams,
  }) {
    final proteinKcal = targetProteinGrams * standardProteinKcalPerGram;
    final fatKcal = targetFatGrams * standardFatKcalPerGram;
    final remainingKcal = goalKcal - (proteinKcal + fatKcal);
    final initialCarbsGrams = remainingKcal / standardCarbKcalPerGram;

    if (initialCarbsGrams >= minimumCarbsFloorGrams) {
      return _capCarbs(
        goalKcal: goalKcal,
        targetProteinGrams: targetProteinGrams,
        targetFatGrams: targetFatGrams,
        carbsGrams: initialCarbsGrams,
      );
    }

    return _balanceLowCalorieBudget(
      goalKcal: goalKcal,
      safeWeight: safeWeight,
      targetProteinGrams: targetProteinGrams,
      targetFatGrams: targetFatGrams,
      remainingKcal: remainingKcal,
    );
  }

  static MacroCalculationResult _capCarbs({
    required double goalKcal,
    required double targetProteinGrams,
    required double targetFatGrams,
    required double carbsGrams,
  }) {
    final capGrams = carbsCapGrams(goalKcal);
    if (carbsGrams <= capGrams) {
      return MacroCalculationResult(
        carbs: carbsGrams,
        protein: targetProteinGrams,
        fat: targetFatGrams,
      );
    }
    final excessKcal = (carbsGrams - capGrams) * standardCarbKcalPerGram;
    return MacroCalculationResult(
      carbs: capGrams,
      protein: targetProteinGrams,
      fat: targetFatGrams + excessKcal / standardFatKcalPerGram,
    );
  }

  static MacroCalculationResult _balanceLowCalorieBudget({
    required double goalKcal,
    required double safeWeight,
    required double targetProteinGrams,
    required double targetFatGrams,
    required double remainingKcal,
  }) {
    const targetCarbsKcal = minimumCarbsFloorGrams * standardCarbKcalPerGram;
    final deficitKcal = targetCarbsKcal - remainingKcal;
    final fatAdjustment = _reduceFatForFloor(
      goalKcal: goalKcal,
      safeWeight: safeWeight,
      targetFatGrams: targetFatGrams,
      deficitKcal: deficitKcal,
    );

    final remainingDeficit = deficitKcal - fatAdjustment.savedKcal;
    final adjustedProteinGrams = _reduceProteinForDeficit(
      safeWeight: safeWeight,
      targetProteinGrams: targetProteinGrams,
      deficitKcal: remainingDeficit,
    );

    final usedKcal =
        (adjustedProteinGrams * standardProteinKcalPerGram) +
        (fatAdjustment.fatGrams * standardFatKcalPerGram);
    final finalCarbsKcal = math.max(0, goalKcal - usedKcal);

    return MacroCalculationResult(
      carbs: finalCarbsKcal / standardCarbKcalPerGram,
      protein: adjustedProteinGrams,
      fat: fatAdjustment.fatGrams,
    );
  }

  static ({double fatGrams, double savedKcal}) _reduceFatForFloor({
    required double goalKcal,
    required double safeWeight,
    required double targetFatGrams,
    required double deficitKcal,
  }) {
    final fatFloorGrams = math.max<double>(
      safeWeight * minimumFatFloorGramsPerKg,
      (goalKcal * minimumFatCalorieFraction) / standardFatKcalPerGram,
    );
    final initialFatKcal = targetFatGrams * standardFatKcalPerGram;
    final fatFloorKcal = fatFloorGrams * standardFatKcalPerGram;
    final maxFatReduction = math.max<double>(0, initialFatKcal - fatFloorKcal);
    final fatReductionKcal = math.min<double>(deficitKcal, maxFatReduction);
    final finalFatGrams =
        targetFatGrams - (fatReductionKcal / standardFatKcalPerGram);

    return (fatGrams: finalFatGrams, savedKcal: fatReductionKcal);
  }

  static double _reduceProteinForDeficit({
    required double safeWeight,
    required double targetProteinGrams,
    required double deficitKcal,
  }) {
    if (deficitKcal <= 0) {
      return targetProteinGrams;
    }
    // Protein goes down to its floor at most; protein already below it stays.
    final proteinFloorGrams = math.min<double>(
      targetProteinGrams,
      safeWeight * minimumProteinFloorGramsPerKg,
    );
    final maxReductionKcal =
        (targetProteinGrams - proteinFloorGrams) * standardProteinKcalPerGram;
    final reductionKcal = math.min<double>(maxReductionKcal, deficitKcal);
    return targetProteinGrams - (reductionKcal / standardProteinKcalPerGram);
  }
}
