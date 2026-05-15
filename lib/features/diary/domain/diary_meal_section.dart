import 'package:yamt/core/domain/meal_type.dart';

/// Diary entry data needed by meal cards.
class DiaryMealEntry {
  /// Creates diary meal entry presentation data.
  const DiaryMealEntry({
    required this.id,
    required this.mealType,
    required this.name,
    required this.totalKcal,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    this.imageUrl,
    this.imageAssetId,
  });

  /// Entry id.
  final String id;

  /// Meal section.
  final MealType mealType;

  /// Display name.
  final String name;

  /// Image URL from the food source.
  final String? imageUrl;

  /// Local image asset id.
  final String? imageAssetId;

  /// Total kcal.
  final double totalKcal;

  /// Total protein in grams.
  final double totalProtein;

  /// Total carbs in grams.
  final double totalCarbs;

  /// Total fat in grams.
  final double totalFat;
}

/// Diary meal section with entries and kcal total.
class DiaryMealSection {
  /// Creates a diary meal section.
  const DiaryMealSection({
    required this.mealType,
    required this.entries,
    required this.totalKcal,
  });

  /// Meal type.
  final MealType mealType;

  /// Entries in this meal section.
  final List<DiaryMealEntry> entries;

  /// Section kcal total.
  final double totalKcal;
}
