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
/// Protein and fat start from their g/kg targets. Carbs get the rest, but at
/// most [maximumCarbsKcalShare] of the kcal. What lies above that cap goes to
/// protein up to [maximumProteinGramsPerKg], then to fat. On a small budget
/// carbs keep at least [minimumCarbsFloorGrams].
abstract final class MacroBudgetCalculator {
  /// Minimum carbs floor in grams to prevent ketosis / hypoglycemia.
  static const double minimumCarbsFloorGrams = 100;

  /// Largest share of the daily kcal that carbs get.
  static const double maximumCarbsKcalShare = 0.40;

  /// Protein limit in g/kg for the kcal above the carb cap.
  static const double maximumProteinGramsPerKg = 2;

  /// Minimum physiological fat floor in g/kg body weight.
  static const double minimumFatFloorGramsPerKg = 0.6;

  /// Minimum fat percentage of daily calories.
  static const double minimumFatCalorieFraction = 0.20;

  /// Energy density for carbs in standard daily calculation.
  static const double standardCarbKcalPerGram = 4;

  /// Energy density for protein in standard daily calculation.
  static const double standardProteinKcalPerGram = 4;

  /// Energy density for fat in standard daily calculation.
  static const double standardFatKcalPerGram = 9;

  /// Calculates balanced macros, capping carbs and ensuring at least 100 g
  /// carbs when possible.
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
        safeWeight: safeWeight,
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
    required double safeWeight,
    required double targetProteinGrams,
    required double targetFatGrams,
    required double carbsGrams,
  }) {
    final capGrams = math.max<double>(
      minimumCarbsFloorGrams,
      goalKcal * maximumCarbsKcalShare / standardCarbKcalPerGram,
    );
    if (carbsGrams <= capGrams) {
      return MacroCalculationResult(
        carbs: carbsGrams,
        protein: targetProteinGrams,
        fat: targetFatGrams,
      );
    }
    final excessKcal = (carbsGrams - capGrams) * standardCarbKcalPerGram;
    final proteinRoomGrams = math.max<double>(
      0,
      safeWeight * maximumProteinGramsPerKg - targetProteinGrams,
    );
    final addedProteinGrams = math.min<double>(
      proteinRoomGrams,
      excessKcal / standardProteinKcalPerGram,
    );
    final addedFatKcal =
        excessKcal - addedProteinGrams * standardProteinKcalPerGram;
    return MacroCalculationResult(
      carbs: capGrams,
      protein: targetProteinGrams + addedProteinGrams,
      fat: targetFatGrams + addedFatKcal / standardFatKcalPerGram,
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
    required double targetProteinGrams,
    required double deficitKcal,
  }) {
    if (deficitKcal <= 0) {
      return targetProteinGrams;
    }
    final proteinKcal = targetProteinGrams * standardProteinKcalPerGram;
    final reductionKcal = math.min<double>(proteinKcal, deficitKcal);
    return targetProteinGrams - (reductionKcal / standardProteinKcalPerGram);
  }
}
