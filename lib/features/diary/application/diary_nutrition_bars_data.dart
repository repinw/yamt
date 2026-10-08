import 'package:yamt/features/diary/domain/diary_macro_targets.dart';

/// Data for the diary nutrition bars.
class DiaryNutritionBarsData {
  /// Creates diary nutrition bars data.
  const new({
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.goals,
  });

  /// Consumed carbs in grams.
  final double carbs;

  /// Consumed protein in grams.
  final double protein;

  /// Consumed fat in grams.
  final double fat;

  /// Target macro grams.
  final DiaryMacroTargets goals;
}
