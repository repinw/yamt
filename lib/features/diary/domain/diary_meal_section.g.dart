// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_meal_section.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiaryMealEntry _$DiaryMealEntryFromJson(Map<String, dynamic> json) =>
    DiaryMealEntry(
      id: json['id'] as String,
      mealType:
          $enumDecodeNullable(
            _$MealTypeEnumMap,
            json['meal_type'],
            unknownValue: MealType.breakfast,
          ) ??
          MealType.breakfast,
      name: json['name'] as String,
      totalKcal: (json['total_kcal'] as num).toDouble(),
      totalProtein: (json['total_protein'] as num).toDouble(),
      totalCarbs: (json['total_carbs'] as num).toDouble(),
      totalFat: (json['total_fat'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      imageAssetId: json['image_asset_id'] as String?,
      consumedAmount: (json['consumed_amount'] as num?)?.toDouble(),
      consumedUnit: $enumDecodeNullable(
        _$ConsumedUnitEnumMap,
        json['consumed_unit'],
        unknownValue: ConsumedUnit.grams,
      ),
      bundleConsumedPortions: json['bundle_consumed_portions'] as num?,
      bundleTotalPortions: (json['bundle_total_portions'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DiaryMealEntryToJson(DiaryMealEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'meal_type': _$MealTypeEnumMap[instance.mealType]!,
      'name': instance.name,
      'image_url': instance.imageUrl,
      'image_asset_id': instance.imageAssetId,
      'total_kcal': instance.totalKcal,
      'total_protein': instance.totalProtein,
      'total_carbs': instance.totalCarbs,
      'total_fat': instance.totalFat,
      'consumed_amount': instance.consumedAmount,
      'consumed_unit': _$ConsumedUnitEnumMap[instance.consumedUnit],
      'bundle_consumed_portions': instance.bundleConsumedPortions,
      'bundle_total_portions': instance.bundleTotalPortions,
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

DiaryMealSection _$DiaryMealSectionFromJson(Map<String, dynamic> json) =>
    DiaryMealSection(
      mealType:
          $enumDecodeNullable(
            _$MealTypeEnumMap,
            json['meal_type'],
            unknownValue: MealType.breakfast,
          ) ??
          MealType.breakfast,
      entries: (json['entries'] as List<dynamic>)
          .map((e) => DiaryMealEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalKcal: (json['total_kcal'] as num).toDouble(),
    );

Map<String, dynamic> _$DiaryMealSectionToJson(DiaryMealSection instance) =>
    <String, dynamic>{
      'meal_type': _$MealTypeEnumMap[instance.mealType]!,
      'entries': instance.entries.map((e) => e.toJson()).toList(),
      'total_kcal': instance.totalKcal,
    };
