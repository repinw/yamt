import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';

part 'diary_nutrition_bars_data.g.dart';

/// Data for the diary nutrition bars.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DiaryNutritionBarsData {
  /// Creates diary nutrition bars data.
  const DiaryNutritionBarsData({
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.goals,
  });

  /// Creates data from persisted JSON.
  factory DiaryNutritionBarsData.fromJson(Map<String, dynamic> json) =>
      _$DiaryNutritionBarsDataFromJson(json);

  /// Converts data to persisted JSON.
  Map<String, dynamic> toJson() => _$DiaryNutritionBarsDataToJson(this);

  /// Consumed carbs in grams.
  final double carbs;

  /// Consumed protein in grams.
  final double protein;

  /// Consumed fat in grams.
  final double fat;

  /// Target macro grams.
  final DiaryMacroTargets goals;
}
