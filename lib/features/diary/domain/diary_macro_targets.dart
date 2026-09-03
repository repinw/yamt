import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Conversion factor: Carbs kcal per gram (sports nutrition standard).
const carbEnergyDensityKcalPerGram = 4.1;

/// Conversion factor: Fat kcal per gram (sports nutrition standard).
const fatEnergyDensityKcalPerGram = 9.3;

/// Conversion factor: Protein kcal per gram.
const proteinEnergyDensityKcalPerGram = 4;

/// Proportion of carryover allocated to carbs (75%).
const carryoverCarbFraction = 0.75;

/// Proportion of carryover allocated to fat (25%).
const carryoverFatFraction = 0.25;

/// Minimum carbs in grams (Ketose- / Unterzuckerungsschutz).
const minimumCarbsFloorGrams = 50.0;

/// Minimum fat in grams per kg body weight (Schutzregel B - Fat Floor).
const minimumFatFloorGramsPerKg = 0.6;

/// Minimum fat percentage of daily calories (Schutzregel B - Fat Floor).
const minimumFatCalorieFraction = 0.20;

/// Represents the delta applied to base macros due to carryover.
@immutable
class DiaryMacroCarryoverDelta {
  /// Creates a carryover delta result.
  const DiaryMacroCarryoverDelta({
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.wasFatFloorApplied = false,
    this.wasCarbsFloorApplied = false,
  });

  /// Protein adjustment in grams (always 0.0 - Schutzregel A).
  final double proteinGrams;

  /// Carbs adjustment in grams.
  final double carbsGrams;

  /// Fat adjustment in grams.
  final double fatGrams;

  /// Whether fat reduction was limited by the physiological Fat Floor.
  final bool wasFatFloorApplied;

  /// Whether carbs reduction was limited by the 50g minimum floor.
  final bool wasCarbsFloorApplied;
}

/// Macro targets derived for one diary day.
@immutable
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

  /// Returns a new [DiaryMacroTargets] with positive or negative carryover.
  ///
  /// Implements:
  /// - Protein remains 100% constant (Schutzregel A).
  /// - Positive carryover: +75% kcal to carbs (/ 4.1), +25% kcal to fat (/ 9.3).
  /// - Negative carryover: -25% kcal from fat (/ 9.3) down to the Fat Floor
  ///   (>= 0.6 g/kg or >= 20% of daily kcal). Any excess reduction that would
  ///   breach the Fat Floor is redirected to carbs.
  /// - Carbs are reduced by remaining reduction (/ 4.1), never below 50g floor.
  DiaryMacroTargets applyCarryover({
    required double carryoverKcal,
    required double weightKg,
    double? baseGoalKcal,
  }) {
    if (carryoverKcal == 0) {
      return this;
    }
    final delta = calculateCarryoverDelta(
      baseTargets: this,
      carryoverKcal: carryoverKcal,
      weightKg: weightKg,
      baseGoalKcal: baseGoalKcal,
    );
    return DiaryMacroTargets(
      protein: protein + delta.proteinGrams,
      carbs: carbs + delta.carbsGrams,
      fat: fat + delta.fatGrams,
    );
  }

  /// Calculates the delta applied to base macros for a given carryover.
  static DiaryMacroCarryoverDelta calculateCarryoverDelta({
    required DiaryMacroTargets baseTargets,
    required double carryoverKcal,
    required double weightKg,
    double? baseGoalKcal,
  }) {
    if (carryoverKcal == 0) {
      return const DiaryMacroCarryoverDelta(
        proteinGrams: 0,
        carbsGrams: 0,
        fatGrams: 0,
      );
    }

    if (carryoverKcal > 0) {
      return DiaryMacroCarryoverDelta(
        proteinGrams: 0,
        carbsGrams: (carryoverKcal * carryoverCarbFraction) /
            carbEnergyDensityKcalPerGram,
        fatGrams: (carryoverKcal * carryoverFatFraction) /
            fatEnergyDensityKcalPerGram,
      );
    }

    final reductionKcal = carryoverKcal.abs();
    final fatFloor = _calculateFatFloor(
      weightKg: weightKg,
      reductionKcal: reductionKcal,
      baseGoalKcal: baseGoalKcal,
    );
    final plannedFatReduction = (reductionKcal * carryoverFatFraction) /
        fatEnergyDensityKcalPerGram;

    double actualFatDelta;
    double carbsReductionKcal;

    if (baseTargets.fat - plannedFatReduction >= fatFloor) {
      actualFatDelta = -plannedFatReduction;
      carbsReductionKcal = reductionKcal * carryoverCarbFraction;
    } else {
      final newFat = math.max<double>(
        fatFloor,
        math.min<double>(baseTargets.fat, fatFloor),
      );
      actualFatDelta = newFat - baseTargets.fat;
      final savedFatKcal = actualFatDelta.abs() * fatEnergyDensityKcalPerGram;
      carbsReductionKcal = math.max<double>(0, reductionKcal - savedFatKcal);
    }

    final carbsReductionGrams =
        carbsReductionKcal / carbEnergyDensityKcalPerGram;
    final minCarbs = math.min<double>(
      baseTargets.carbs,
      minimumCarbsFloorGrams,
    );
    final newCarbs = math.max<double>(
      minCarbs,
      baseTargets.carbs - carbsReductionGrams,
    );
    final actualCarbsDelta = newCarbs - baseTargets.carbs;

    return DiaryMacroCarryoverDelta(
      proteinGrams: 0,
      carbsGrams: actualCarbsDelta,
      fatGrams: actualFatDelta,
      wasFatFloorApplied: baseTargets.fat - plannedFatReduction < fatFloor,
      wasCarbsFloorApplied: newCarbs == minimumCarbsFloorGrams ||
          (baseTargets.carbs < minimumCarbsFloorGrams && actualCarbsDelta == 0),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiaryMacroTargets &&
          runtimeType == other.runtimeType &&
          carbs == other.carbs &&
          protein == other.protein &&
          fat == other.fat;

  @override
  int get hashCode => Object.hash(carbs, protein, fat);

  @override
  String toString() =>
      'DiaryMacroTargets(carbs: $carbs, protein: $protein, fat: $fat)';
}

/// Calculates the physiological Fat Floor (Schutzregel B).
double _calculateFatFloor({
  required double weightKg,
  required double reductionKcal,
  double? baseGoalKcal,
}) {
  final safeWeight = weightKg > 0 ? weightKg : 70;
  final effectiveDayKcal = baseGoalKcal != null
      ? math.max<double>(0, baseGoalKcal - reductionKcal)
      : 0;
  final fatFloorByWeight = safeWeight * minimumFatFloorGramsPerKg;
  final fatFloorByCalories = effectiveDayKcal > 0
      ? (effectiveDayKcal * minimumFatCalorieFraction) /
          fatEnergyDensityKcalPerGram
      : 0.toDouble();
  return math.max<double>(fatFloorByWeight, fatFloorByCalories);
}
