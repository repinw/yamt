import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:yamt/features/calories/domain/macro_budget_calculator.dart';
import 'package:yamt/features/calories/domain/macro_carryover_calculator.dart';

part 'diary_macro_targets.g.dart';

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
