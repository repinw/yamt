import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/calories/domain/calorie_nutrient_details.dart';
import 'package:yamt/features/calories/domain/calories_json_converters.dart';

part 'calorie_entry.g.dart';

// Temporary compatibility, added in 3.4.1: the JSON defaults, unknown enum
// fallbacks, and flexible converters in this file go from 3.7.0 on, once a
// migration has re-saved the stored data in the strict shape.

/// Defines consumed unit.
@JsonEnum(valueField: 'jsonValue')
enum ConsumedUnit {
  /// Grams.
  grams('g'),

  /// Milliliters.
  milliliters('ml');

  new(this.jsonValue);

  /// The json value.
  final String jsonValue;

  /// From json value.
  static ConsumedUnit fromJsonValue(String? value) {
    return switch (value) {
      'ml' => ConsumedUnit.milliliters,
      _ => ConsumedUnit.grams,
    };
  }
}

/// Defines calorie entry.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CalorieEntry {
  /// The calorie entry.
  const new({
    required this.id,
    required this.userId,
    required this.name,
    required this.mealType,
    required this.consumedAmount,
    required this.consumedUnit,
    required this.per100Kcal,
    required this.per100Protein,
    required this.per100Carbs,
    required this.per100Fat,
    required this.totalKcal,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.loggedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.isQuickEntry,
    this.brand,
    this.imageUrl,
    this.imageAssetId,
    this.sourceInventoryItemId,
    this.sourceInventoryAmountToRestore,
    this.bundleSourcePreparedMealId,
    this.bundleConsumedPortions,
    this.bundleTotalPortions,
    this.bundleComponents = const <CalorieEntryBundleComponent>[],
    this.nutrientDetails,
  });

  /// Creates a [CalorieEntry] for create.
  factory create({
    required String id,
    required String userId,
    required String name,
    required MealType mealType,
    required double consumedAmount,
    required ConsumedUnit consumedUnit,
    required double per100Kcal,
    required double per100Protein,
    required double per100Carbs,
    required double per100Fat,
    DateTime? loggedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? brand,
    String? imageUrl,
    String? imageAssetId,
    String? sourceInventoryItemId,
    int? sourceInventoryAmountToRestore,
    CalorieNutrientDetails? nutrientDetails,
  }) {
    final now = DateTime.now();
    final factor = consumedAmount / 100;

    return CalorieEntry(
      id: id,
      userId: userId,
      name: name,
      mealType: mealType,
      consumedAmount: consumedAmount,
      consumedUnit: consumedUnit,
      per100Kcal: per100Kcal,
      per100Protein: per100Protein,
      per100Carbs: per100Carbs,
      per100Fat: per100Fat,
      totalKcal: per100Kcal * factor,
      totalProtein: per100Protein * factor,
      totalCarbs: per100Carbs * factor,
      totalFat: per100Fat * factor,
      loggedAt: loggedAt ?? now,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      brand: brand,
      imageUrl: imageUrl,
      imageAssetId: imageAssetId,
      sourceInventoryItemId: sourceInventoryItemId,
      sourceInventoryAmountToRestore: sourceInventoryAmountToRestore,
      nutrientDetails: nutrientDetails,
      isQuickEntry: false,
    );
  }

  /// Creates a [CalorieEntry] for bundle.
  factory bundle({
    required String id,
    required String userId,
    required String name,
    required MealType mealType,
    required double totalKcal,
    required double totalProtein,
    required double totalCarbs,
    required double totalFat,
    required String bundleSourcePreparedMealId,
    required num bundleConsumedPortions,
    required int bundleTotalPortions,
    required List<CalorieEntryBundleComponent> bundleComponents,
    DateTime? loggedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? brand,
    String? imageUrl,
    String? imageAssetId,
  }) {
    final now = DateTime.now();

    return CalorieEntry(
      id: id,
      userId: userId,
      name: name,
      brand: brand,
      imageUrl: imageUrl,
      imageAssetId: imageAssetId,
      mealType: mealType,
      consumedAmount: 100,
      consumedUnit: ConsumedUnit.grams,
      per100Kcal: totalKcal,
      per100Protein: totalProtein,
      per100Carbs: totalCarbs,
      per100Fat: totalFat,
      totalKcal: totalKcal,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      loggedAt: loggedAt ?? now,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      bundleSourcePreparedMealId: bundleSourcePreparedMealId,
      bundleConsumedPortions: bundleConsumedPortions,
      bundleTotalPortions: bundleTotalPortions,
      bundleComponents: bundleComponents,
      isQuickEntry: false,
    );
  }

  /// Creates a [CalorieEntry] used as an onboarding placeholder.
  ///
  /// Onboarding placeholders represent food the user has eaten before
  /// they started tracking actively. They expose only [totalKcal] —
  /// macros are estimated with a generic 50% carbs / 25% protein / 25%
  /// fat split so totals are roughly self-consistent.
  factory placeholder({
    required String id,
    required String name,
    required MealType mealType,
    required double totalKcal,
    String userId = '',
    DateTime? loggedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    final safeKcal = totalKcal < 0 ? 0.0 : totalKcal;
    // Generic macro split: 50% kcal from carbs, 25% protein, 25% fat.
    // 1 g carbs/protein = 4 kcal, 1 g fat = 9 kcal.
    final totalCarbs = (safeKcal * 0.50) / 4;
    final totalProtein = (safeKcal * 0.25) / 4;
    final totalFat = (safeKcal * 0.25) / 9;

    return CalorieEntry(
      id: id,
      userId: userId,
      name: name,
      mealType: mealType,
      consumedAmount: 100,
      consumedUnit: ConsumedUnit.grams,
      per100Kcal: safeKcal,
      per100Protein: totalProtein,
      per100Carbs: totalCarbs,
      per100Fat: totalFat,
      totalKcal: safeKcal,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      loggedAt: loggedAt ?? now,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      isQuickEntry: false,
    );
  }

  /// Creates a [CalorieEntry] for from json.
  factory fromJson(Map<String, dynamic> json) {
    return _$CalorieEntryFromJson(json);
  }

  /// The id.
  final String id;

  /// The user id.
  final String userId;

  /// The name.
  final String name;

  /// The brand.
  final String? brand;

  /// The image url.
  final String? imageUrl;

  /// The image asset id.
  final String? imageAssetId;

  /// The source inventory item id.
  final String? sourceInventoryItemId;

  /// The source inventory amount to restore.
  final int? sourceInventoryAmountToRestore;

  /// The bundle source prepared meal id.
  final String? bundleSourcePreparedMealId;

  /// The bundle consumed portions.
  final num? bundleConsumedPortions;

  /// The bundle total portions.
  final int? bundleTotalPortions;

  /// The bundle components.
  @JsonKey(defaultValue: <CalorieEntryBundleComponent>[])
  final List<CalorieEntryBundleComponent> bundleComponents;

  /// Nutrients per 100 beyond the macros, when the food source had them.
  @NullableCalorieNutrientDetailsConverter()
  final CalorieNutrientDetails? nutrientDetails;

  /// Whether the user typed the calories and macros in by hand, without a
  /// food behind them. Its totals are what was typed; it has no real amount.
  ///
  /// Temporary compatibility, added in 3.4.1: the default covers entries
  /// saved before 3.3.0 until the private data migration has added the
  /// field; it goes from 3.7.0 on.
  @JsonKey(defaultValue: false)
  final bool isQuickEntry;

  /// The meal type.
  @JsonKey(defaultValue: MealType.snack, unknownEnumValue: MealType.snack)
  final MealType mealType;

  /// The consumed amount.
  @FlexibleDoubleConverter()
  final double consumedAmount;
  @JsonKey(
    defaultValue: ConsumedUnit.grams,
    unknownEnumValue: ConsumedUnit.grams,
  )
  /// The consumed unit.
  final ConsumedUnit consumedUnit;

  /// The per100 kcal.
  @FlexibleDoubleConverter()
  final double per100Kcal;

  /// The per100 protein.
  @FlexibleDoubleConverter()
  final double per100Protein;

  /// The per100 carbs.
  @FlexibleDoubleConverter()
  final double per100Carbs;

  /// The per100 fat.
  @FlexibleDoubleConverter()
  final double per100Fat;

  /// The total kcal.
  @FlexibleDoubleConverter()
  final double totalKcal;

  /// The total protein.
  @FlexibleDoubleConverter()
  final double totalProtein;

  /// The total carbs.
  @FlexibleDoubleConverter()
  final double totalCarbs;

  /// The total fat.
  @FlexibleDoubleConverter()
  final double totalFat;

  /// The logged at.
  @FlexibleDateTimeConverter()
  final DateTime loggedAt;

  /// The created at.
  @FlexibleDateTimeConverter()
  final DateTime createdAt;

  /// The updated at.
  @FlexibleDateTimeConverter()
  final DateTime updatedAt;

  /// To json.
  Map<String, dynamic> toJson() => _$CalorieEntryToJson(this);

  /// Whether valid.
  bool get isValid {
    if (id.trim().isEmpty || userId.trim().isEmpty || name.trim().isEmpty) {
      return false;
    }
    if (consumedAmount <= 0) {
      return false;
    }
    if (per100Kcal < 0 || per100Protein < 0 || per100Carbs < 0) {
      return false;
    }
    if (per100Fat < 0 || totalKcal < 0 || totalProtein < 0) {
      return false;
    }
    if (totalCarbs < 0 || totalFat < 0) {
      return false;
    }
    return true;
  }

  /// Whether the entry lists several foods: a prepared meal or a combined
  /// entry.
  bool get isBundle => bundleComponents.isNotEmpty;

  /// Whether the entry combines foods logged together, without a prepared
  /// meal.
  bool get isCombined {
    return isBundle && (bundleSourcePreparedMealId?.trim().isEmpty ?? true);
  }

  /// Whether deleting the combined entry can return stock of its foods.
  bool get canReturnCombinedToInventory {
    return isCombined &&
        bundleComponents.any((component) => component.canRestoreToInventory);
  }

  /// Whether restore to inventory.
  bool get canRestoreToInventory {
    return (sourceInventoryItemId?.trim().isNotEmpty ?? false) &&
        (sourceInventoryAmountToRestore ?? 0) > 0;
  }

  /// Whether return prepared meal to inventory.
  bool get canReturnPreparedMealToInventory {
    return (bundleSourcePreparedMealId?.trim().isNotEmpty ?? false) &&
        (bundleConsumedPortions ?? 0) > 0;
  }

  /// Copy with.
  CalorieEntry copyWith({
    String? id,
    String? userId,
    String? name,
    String? brand,
    String? imageUrl,
    Object? imageAssetId = _keepValue,
    Object? sourceInventoryItemId = _keepValue,
    Object? sourceInventoryAmountToRestore = _keepValue,
    Object? bundleSourcePreparedMealId = _keepValue,
    Object? bundleConsumedPortions = _keepValue,
    Object? bundleTotalPortions = _keepValue,
    List<CalorieEntryBundleComponent>? bundleComponents,
    MealType? mealType,
    double? consumedAmount,
    ConsumedUnit? consumedUnit,
    double? per100Kcal,
    double? per100Protein,
    double? per100Carbs,
    double? per100Fat,
    double? totalKcal,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    DateTime? loggedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalorieEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      imageAssetId: imageAssetId == _keepValue
          ? this.imageAssetId
          : imageAssetId as String?,
      sourceInventoryItemId: sourceInventoryItemId == _keepValue
          ? this.sourceInventoryItemId
          : sourceInventoryItemId as String?,
      sourceInventoryAmountToRestore:
          sourceInventoryAmountToRestore == _keepValue
          ? this.sourceInventoryAmountToRestore
          : sourceInventoryAmountToRestore as int?,
      bundleSourcePreparedMealId: bundleSourcePreparedMealId == _keepValue
          ? this.bundleSourcePreparedMealId
          : bundleSourcePreparedMealId as String?,
      bundleConsumedPortions: bundleConsumedPortions == _keepValue
          ? this.bundleConsumedPortions
          : bundleConsumedPortions as num?,
      bundleTotalPortions: bundleTotalPortions == _keepValue
          ? this.bundleTotalPortions
          : bundleTotalPortions as int?,
      bundleComponents: bundleComponents ?? this.bundleComponents,
      mealType: mealType ?? this.mealType,
      consumedAmount: consumedAmount ?? this.consumedAmount,
      consumedUnit: consumedUnit ?? this.consumedUnit,
      per100Kcal: per100Kcal ?? this.per100Kcal,
      per100Protein: per100Protein ?? this.per100Protein,
      per100Carbs: per100Carbs ?? this.per100Carbs,
      per100Fat: per100Fat ?? this.per100Fat,
      totalKcal: totalKcal ?? this.totalKcal,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      loggedAt: loggedAt ?? this.loggedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nutrientDetails: nutrientDetails,
      isQuickEntry: isQuickEntry,
    );
  }

  /// Recalculate totals.
  CalorieEntry recalculateTotals({DateTime? updatedAt}) {
    if (isBundle) {
      return copyWith(updatedAt: updatedAt ?? DateTime.now());
    }

    final factor = consumedAmount / 100;
    return copyWith(
      totalKcal: per100Kcal * factor,
      totalProtein: per100Protein * factor,
      totalCarbs: per100Carbs * factor,
      totalFat: per100Fat * factor,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

const Object _keepValue = Object();
