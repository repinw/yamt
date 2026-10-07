import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/macro_budget_calculator.dart';

/// Conversion factor: Carbs kcal per gram (sports nutrition standard).
const carbEnergyDensityKcalPerGram = 4.1;

/// Conversion factor: Fat kcal per gram (sports nutrition standard).
const fatEnergyDensityKcalPerGram = 9.3;

/// Proportion of carryover allocated to carbs (75%).
const carryoverCarbFraction = 0.75;

/// Proportion of carryover allocated to fat (25%).
const carryoverFatFraction = 0.25;

/// Represents the delta applied to base macros due to carryover.
@immutable
class MacroCarryoverDelta {
  /// Creates a carryover delta result.
  const new({
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

  /// Whether carbs reduction was limited by the 100g minimum floor.
  final bool wasCarbsFloorApplied;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MacroCarryoverDelta &&
          runtimeType == other.runtimeType &&
          proteinGrams == other.proteinGrams &&
          carbsGrams == other.carbsGrams &&
          fatGrams == other.fatGrams &&
          wasFatFloorApplied == other.wasFatFloorApplied &&
          wasCarbsFloorApplied == other.wasCarbsFloorApplied;

  @override
  int get hashCode => Object.hash(
    proteinGrams,
    carbsGrams,
    fatGrams,
    wasFatFloorApplied,
    wasCarbsFloorApplied,
  );
}

/// Domain calculator for macro carryover adjustments.
abstract final class MacroCarryoverCalculator {
  /// Calculates the delta applied to base macros for a given carryover.
  static MacroCarryoverDelta calculateCarryoverDelta({
    required double baseCarbs,
    required double baseFat,
    required double carryoverKcal,
    required double weightKg,
    double? baseGoalKcal,
  }) {
    if (carryoverKcal == 0) {
      return const MacroCarryoverDelta(
        proteinGrams: 0,
        carbsGrams: 0,
        fatGrams: 0,
      );
    }
    if (carryoverKcal > 0) {
      return _positiveCarryoverDelta(
        baseCarbs: baseCarbs,
        carryoverKcal: carryoverKcal,
        baseGoalKcal: baseGoalKcal,
      );
    }
    return _negativeCarryoverDelta(
      baseCarbs: baseCarbs,
      baseFat: baseFat,
      carryoverKcal: carryoverKcal,
      weightKg: weightKg,
      baseGoalKcal: baseGoalKcal,
    );
  }

  /// Splits a positive carryover 75/25 between carbs and fat. Carbs stop at
  /// [MacroBudgetCalculator.maximumCarbsKcalShare] of the day's kcal with the
  /// carryover; the rest goes to fat. Protein stays the same every day.
  static MacroCarryoverDelta _positiveCarryoverDelta({
    required double baseCarbs,
    required double carryoverKcal,
    double? baseGoalKcal,
  }) {
    final plannedCarbsGrams =
        (carryoverKcal * carryoverCarbFraction) / carbEnergyDensityKcalPerGram;
    final carbsGrams = baseGoalKcal == null
        ? plannedCarbsGrams
        : math.min<double>(
            plannedCarbsGrams,
            math.max<double>(
              0,
              MacroBudgetCalculator.carbsCapGrams(
                    baseGoalKcal + carryoverKcal,
                  ) -
                  baseCarbs,
            ),
          );
    final fatKcal = carryoverKcal - carbsGrams * carbEnergyDensityKcalPerGram;
    return MacroCarryoverDelta(
      proteinGrams: 0,
      carbsGrams: carbsGrams,
      fatGrams: fatKcal / fatEnergyDensityKcalPerGram,
    );
  }

  static MacroCarryoverDelta _negativeCarryoverDelta({
    required double baseCarbs,
    required double baseFat,
    required double carryoverKcal,
    required double weightKg,
    double? baseGoalKcal,
  }) {
    final reductionKcal = carryoverKcal.abs();
    final fatFloor = _calculateFatFloor(
      weightKg: weightKg,
      reductionKcal: reductionKcal,
      baseGoalKcal: baseGoalKcal,
    );
    final fatResult = _calculateFatReduction(
      baseFat: baseFat,
      reductionKcal: reductionKcal,
      fatFloor: fatFloor,
    );
    final carbsResult = _calculateCarbsReduction(
      baseCarbs: baseCarbs,
      carbsReductionKcal: fatResult.remainingReductionKcal,
    );

    return MacroCarryoverDelta(
      proteinGrams: 0,
      carbsGrams: carbsResult.delta,
      fatGrams: fatResult.delta,
      wasFatFloorApplied: fatResult.wasFloorApplied,
      wasCarbsFloorApplied: carbsResult.wasFloorApplied,
    );
  }

  static ({double delta, double remainingReductionKcal, bool wasFloorApplied})
  _calculateFatReduction({
    required double baseFat,
    required double reductionKcal,
    required double fatFloor,
  }) {
    final plannedReduction =
        (reductionKcal * carryoverFatFraction) / fatEnergyDensityKcalPerGram;
    if (baseFat - plannedReduction >= fatFloor) {
      return (
        delta: -plannedReduction,
        remainingReductionKcal: reductionKcal * carryoverCarbFraction,
        wasFloorApplied: false,
      );
    }
    final newFat = math.max<double>(
      fatFloor,
      math.min<double>(baseFat, fatFloor),
    );
    final actualDelta = newFat - baseFat;
    final savedKcal = actualDelta.abs() * fatEnergyDensityKcalPerGram;
    return (
      delta: actualDelta,
      remainingReductionKcal: math.max<double>(0, reductionKcal - savedKcal),
      wasFloorApplied: true,
    );
  }

  static ({double delta, bool wasFloorApplied}) _calculateCarbsReduction({
    required double baseCarbs,
    required double carbsReductionKcal,
  }) {
    final reductionGrams = carbsReductionKcal / carbEnergyDensityKcalPerGram;
    final minCarbs = math.min<double>(
      baseCarbs,
      MacroBudgetCalculator.minimumCarbsFloorGrams,
    );
    final newCarbs = math.max<double>(minCarbs, baseCarbs - reductionGrams);
    final delta = newCarbs - baseCarbs;
    final wasFloorApplied =
        newCarbs == MacroBudgetCalculator.minimumCarbsFloorGrams ||
        (baseCarbs < MacroBudgetCalculator.minimumCarbsFloorGrams &&
            delta == 0);
    return (delta: delta, wasFloorApplied: wasFloorApplied);
  }

  static double _calculateFatFloor({
    required double weightKg,
    required double reductionKcal,
    double? baseGoalKcal,
  }) {
    final safeWeight = weightKg > 0 ? weightKg : 70.0;
    final effectiveDayKcal = baseGoalKcal != null
        ? math.max<double>(0, baseGoalKcal - reductionKcal)
        : 0.0;
    final fatFloorByWeight =
        safeWeight * MacroBudgetCalculator.minimumFatFloorGramsPerKg;
    final fatFloorByCalories = effectiveDayKcal > 0
        ? (effectiveDayKcal * MacroBudgetCalculator.minimumFatCalorieFraction) /
              fatEnergyDensityKcalPerGram
        : 0.0;
    return math.max<double>(fatFloorByWeight, fatFloorByCalories);
  }
}
