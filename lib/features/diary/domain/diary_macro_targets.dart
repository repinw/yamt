import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'diary_macro_targets.g.dart';

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
