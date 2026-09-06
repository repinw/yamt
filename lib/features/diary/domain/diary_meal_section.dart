import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

part 'diary_meal_section.g.dart';

/// Diary entry data needed by meal cards.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
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
    this.consumedAmount,
    this.consumedUnit,
    this.bundleConsumedPortions,
    this.bundleTotalPortions,
  });

  /// Creates data from persisted JSON.
  factory DiaryMealEntry.fromJson(Map<String, dynamic> json) =>
      _$DiaryMealEntryFromJson(json);

  /// Converts data to persisted JSON.
  Map<String, dynamic> toJson() => _$DiaryMealEntryToJson(this);

  /// Entry id.
  final String id;

  /// Meal section.
  @JsonKey(
    defaultValue: MealType.breakfast,
    unknownEnumValue: MealType.breakfast,
  )
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

  /// Consumed amount (e.g. in grams or milliliters).
  final double? consumedAmount;

  /// Consumed unit (grams or milliliters).
  @JsonKey(unknownEnumValue: ConsumedUnit.grams)
  final ConsumedUnit? consumedUnit;

  /// Consumed portions if part of a bundle.
  final num? bundleConsumedPortions;

  /// Total portions if part of a bundle.
  final int? bundleTotalPortions;
}

/// Diary meal section with entries and kcal total.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DiaryMealSection {
  /// Creates a diary meal section.
  const DiaryMealSection({
    required this.mealType,
    required this.entries,
    required this.totalKcal,
  });

  /// Creates data from persisted JSON.
  factory DiaryMealSection.fromJson(Map<String, dynamic> json) =>
      _$DiaryMealSectionFromJson(json);

  /// Converts data to persisted JSON.
  Map<String, dynamic> toJson() => _$DiaryMealSectionToJson(this);

  /// Meal type.
  @JsonKey(
    defaultValue: MealType.breakfast,
    unknownEnumValue: MealType.breakfast,
  )
  final MealType mealType;

  /// Entries in this meal section.
  final List<DiaryMealEntry> entries;

  /// Section kcal total.
  final double totalKcal;

  /// Total protein in grams across all entries in this section.
  double get totalProtein =>
      entries.fold<double>(0, (sum, entry) => sum + entry.totalProtein);

  /// Total carbohydrates in grams across all entries in this section.
  double get totalCarbs =>
      entries.fold<double>(0, (sum, entry) => sum + entry.totalCarbs);

  /// Total fat in grams across all entries in this section.
  double get totalFat =>
      entries.fold<double>(0, (sum, entry) => sum + entry.totalFat);
}
