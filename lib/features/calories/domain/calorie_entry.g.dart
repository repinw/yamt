// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalorieEntry _$CalorieEntryFromJson(Map<String, dynamic> json) => CalorieEntry(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  name: json['name'] as String,
  mealType: $enumDecode(_$MealTypeEnumMap, json['meal_type']),
  consumedAmount: (json['consumed_amount'] as num).toDouble(),
  consumedUnit: $enumDecode(_$ConsumedUnitEnumMap, json['consumed_unit']),
  per100Kcal: (json['per100_kcal'] as num).toDouble(),
  per100Protein: (json['per100_protein'] as num).toDouble(),
  per100Carbs: (json['per100_carbs'] as num).toDouble(),
  per100Fat: (json['per100_fat'] as num).toDouble(),
  totalKcal: (json['total_kcal'] as num).toDouble(),
  totalProtein: (json['total_protein'] as num).toDouble(),
  totalCarbs: (json['total_carbs'] as num).toDouble(),
  totalFat: (json['total_fat'] as num).toDouble(),
  loggedAt: const DateTimeJsonConverter().fromJson(
    json['logged_at'] as DateTime,
  ),
  createdAt: const DateTimeJsonConverter().fromJson(
    json['created_at'] as DateTime,
  ),
  updatedAt: const DateTimeJsonConverter().fromJson(
    json['updated_at'] as DateTime,
  ),
  isQuickEntry: json['is_quick_entry'] as bool,
  brand: json['brand'] as String?,
  imageUrl: json['image_url'] as String?,
  imageAssetId: json['image_asset_id'] as String?,
  sourceInventoryItemId: json['source_inventory_item_id'] as String?,
  sourceInventoryAmountToRestore:
      (json['source_inventory_amount_to_restore'] as num?)?.toInt(),
  bundleSourcePreparedMealId: json['bundle_source_prepared_meal_id'] as String?,
  bundleConsumedPortions: json['bundle_consumed_portions'] as num?,
  bundleTotalPortions: (json['bundle_total_portions'] as num?)?.toInt(),
  bundleComponents:
      (json['bundle_components'] as List<dynamic>?)
          ?.map(
            (e) =>
                CalorieEntryBundleComponent.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <CalorieEntryBundleComponent>[],
  nutrientDetails: const NullableCalorieNutrientDetailsConverter().fromJson(
    json['nutrient_details'],
  ),
);

Map<String, dynamic> _$CalorieEntryToJson(
  CalorieEntry instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'name': instance.name,
  'brand': instance.brand,
  'image_url': instance.imageUrl,
  'image_asset_id': instance.imageAssetId,
  'source_inventory_item_id': instance.sourceInventoryItemId,
  'source_inventory_amount_to_restore': instance.sourceInventoryAmountToRestore,
  'bundle_source_prepared_meal_id': instance.bundleSourcePreparedMealId,
  'bundle_consumed_portions': instance.bundleConsumedPortions,
  'bundle_total_portions': instance.bundleTotalPortions,
  'bundle_components': instance.bundleComponents
      .map((e) => e.toJson())
      .toList(),
  'nutrient_details': const NullableCalorieNutrientDetailsConverter().toJson(
    instance.nutrientDetails,
  ),
  'is_quick_entry': instance.isQuickEntry,
  'meal_type': _$MealTypeEnumMap[instance.mealType]!,
  'consumed_amount': instance.consumedAmount,
  'consumed_unit': _$ConsumedUnitEnumMap[instance.consumedUnit]!,
  'per100_kcal': instance.per100Kcal,
  'per100_protein': instance.per100Protein,
  'per100_carbs': instance.per100Carbs,
  'per100_fat': instance.per100Fat,
  'total_kcal': instance.totalKcal,
  'total_protein': instance.totalProtein,
  'total_carbs': instance.totalCarbs,
  'total_fat': instance.totalFat,
  'logged_at': const DateTimeJsonConverter().toJson(instance.loggedAt),
  'created_at': const DateTimeJsonConverter().toJson(instance.createdAt),
  'updated_at': const DateTimeJsonConverter().toJson(instance.updatedAt),
};

const _$MealTypeEnumMap = {
  MealType.breakfast: 'breakfast',
  MealType.lunch: 'lunch',
  MealType.dinner: 'dinner',
  MealType.snack: 'snack',
};

const _$ConsumedUnitEnumMap = {
  ConsumedUnit.grams: 'g',
  ConsumedUnit.milliliters: 'ml',
};
