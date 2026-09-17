import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:yamt/features/calories/domain/macro_budget_calculator.dart';
import 'package:yamt/features/calories/domain/macro_carryover_calculator.dart';

part 'diary_macro_targets.g.dart';

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
typedef DiaryMacroCarryoverDelta = MacroCarryoverDelta;

/// Macro targets derived for one diary day.
@immutable
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DiaryMacroTargets {
  /// Creates resolved diary macro targets.
  const new({required this.carbs, required this.protein, required this.fat});

  /// Derives macro targets from a calorie goal using fixed percentages.
  factory fromGoalKcal(double goalKcal) {
    final positiveGoalKcal = goalKcal > 0 ? goalKcal : 0.0;
    return DiaryMacroTargets(
      carbs: positiveGoalKcal * 0.45 / 4,
      protein: positiveGoalKcal * 0.25 / 4,
      fat: positiveGoalKcal * 0.30 / 9,
    );
  }

  /// Calculates macro targets based on body weight multipliers and remaining
  /// calories for carbs, guaranteeing at least 100g carbs when possible.
  factory calculate({
    required double goalKcal,
    required double weightKg,
    required double proteinGramsPerKg,
    required double fatGramsPerKg,
  }) {
    final result = MacroBudgetCalculator.calculate(
      goalKcal: goalKcal,
      weightKg: weightKg,
      proteinGramsPerKg: proteinGramsPerKg,
      fatGramsPerKg: fatGramsPerKg,
    );
    return DiaryMacroTargets(
      carbs: result.carbs,
      protein: result.protein,
      fat: result.fat,
    );
  }

  /// Creates data from persisted JSON.
  factory fromJson(Map<String, dynamic> json) =>
      _$DiaryMacroTargetsFromJson(json);

  /// Converts data to persisted JSON.
  Map<String, dynamic> toJson() => _$DiaryMacroTargetsToJson(this);

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
    return MacroCarryoverCalculator.calculateCarryoverDelta(
      baseCarbs: baseTargets.carbs,
      baseFat: baseTargets.fat,
      carryoverKcal: carryoverKcal,
      weightKg: weightKg,
      baseGoalKcal: baseGoalKcal,
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
