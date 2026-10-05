import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/diary/domain/diary_meal_entry_group.dart';

part 'diary_meal_section.g.dart';

// Temporary compatibility, added in 3.4.1: the JSON defaults, unknown enum
// fallbacks, and flexible converters in this file go from 3.7.0 on, once a
// migration has re-saved the stored data in the strict shape.

/// Diary entry data needed by meal cards.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DiaryMealEntry {
  /// Creates diary meal entry presentation data.
  const new({
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
    this.combinedFoods,
  });

  /// Creates data from persisted JSON.
  factory fromJson(Map<String, dynamic> json) => _$DiaryMealEntryFromJson(json);

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

  /// Foods of a combined entry, or null when the entry is one food or a
  /// prepared meal.
  final List<CalorieEntryBundleComponent>? combinedFoods;

  /// Whether the entry is portions of a prepared meal.
  bool get isPreparedMeal =>
      combinedFoods == null && (bundleTotalPortions ?? 0) > 0;
}

/// Diary meal section with entries and kcal total.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DiaryMealSection {
  /// Creates a diary meal section.
  new({
    required this.mealType,
    required this.entries,
    required this.plannedEntries,
    required this.countsPlans,
    required this.totalKcal,
  }) : entryGroups = groupDiaryMealEntries(entries);

  /// Creates data from persisted JSON.
  factory fromJson(Map<String, dynamic> json) =>
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

  /// Plans in this meal. They show below [entries] and never merge with them.
  final List<DiaryMealEntry> plannedEntries;

  /// Whether [plannedEntries] count toward the day and so toward [totalKcal].
  final bool countsPlans;

  /// Section kcal total, with the plans when they count toward the day.
  final double totalKcal;

  /// How many rows [totalKcal] sums up: the merged entries, and the plans
  /// when they count.
  int get countedRowCount =>
      entryGroups.length + (countsPlans ? plannedEntries.length : 0);

  /// [entries] with identical foods merged, computed once.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<DiaryMealEntryGroup> entryGroups;

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
