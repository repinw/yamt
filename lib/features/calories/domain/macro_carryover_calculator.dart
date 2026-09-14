import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Conversion factor: Carbs kcal per gram (sports nutrition standard).
const carbEnergyDensityKcalPerGram = 4.1;

/// Conversion factor: Fat kcal per gram (sports nutrition standard).
const fatEnergyDensityKcalPerGram = 9.3;

/// Proportion of carryover allocated to carbs (75%).
const carryoverCarbFraction = 0.75;

/// Proportion of carryover allocated to fat (25%).
const carryoverFatFraction = 0.25;

/// Minimum carbs in grams (Ketose- / Unterzuckerungsschutz).
const minimumCarbsFloorGrams = 100.0;

/// Minimum fat in grams per kg body weight (Schutzregel B - Fat Floor).
const minimumFatFloorGramsPerKg = 0.6;

/// Minimum fat percentage of daily calories (Schutzregel B - Fat Floor).
const minimumFatCalorieFraction = 0.20;

/// Represents the delta applied to base macros due to carryover.
@immutable
class MacroCarryoverDelta {
  /// Creates a carryover delta result.
  const MacroCarryoverDelta({
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
      return _positiveCarryoverDelta(carryoverKcal);
    }
    return _negativeCarryoverDelta(
      baseCarbs: baseCarbs,
      baseFat: baseFat,
      carryoverKcal: carryoverKcal,
      weightKg: weightKg,
      baseGoalKcal: baseGoalKcal,
    );
  }

  static MacroCarryoverDelta _positiveCarryoverDelta(double carryoverKcal) {
    return MacroCarryoverDelta(
      proteinGrams: 0,
      carbsGrams:
          (carryoverKcal * carryoverCarbFraction) /
          carbEnergyDensityKcalPerGram,
      fatGrams:
          (carryoverKcal * carryoverFatFraction) / fatEnergyDensityKcalPerGram,
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
    final minCarbs = math.min<double>(baseCarbs, minimumCarbsFloorGrams);
    final newCarbs = math.max<double>(minCarbs, baseCarbs - reductionGrams);
    final delta = newCarbs - baseCarbs;
    final wasFloorApplied =
        newCarbs == minimumCarbsFloorGrams ||
        (baseCarbs < minimumCarbsFloorGrams && delta == 0);
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
    final fatFloorByWeight = safeWeight * minimumFatFloorGramsPerKg;
    final fatFloorByCalories = effectiveDayKcal > 0
        ? (effectiveDayKcal * minimumFatCalorieFraction) /
              fatEnergyDensityKcalPerGram
        : 0.0;
    return math.max<double>(fatFloorByWeight, fatFloorByCalories);
  }
}
