// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalorieEntry _$CalorieEntryFromJson(Map<String, dynamic> json) => CalorieEntry(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  name: json['name'] as String,
  mealType:
      $enumDecodeNullable(
        _$MealTypeEnumMap,
        json['meal_type'],
        unknownValue: MealType.snack,
      ) ??
      MealType.snack,
  consumedAmount: const FlexibleDoubleConverter().fromJson(
    json['consumed_amount'],
  ),
  consumedUnit:
      $enumDecodeNullable(
        _$ConsumedUnitEnumMap,
        json['consumed_unit'],
        unknownValue: ConsumedUnit.grams,
      ) ??
      ConsumedUnit.grams,
  per100Kcal: const FlexibleDoubleConverter().fromJson(json['per100_kcal']),
  per100Protein: const FlexibleDoubleConverter().fromJson(
    json['per100_protein'],
  ),
  per100Carbs: const FlexibleDoubleConverter().fromJson(json['per100_carbs']),
  per100Fat: const FlexibleDoubleConverter().fromJson(json['per100_fat']),
  totalKcal: const FlexibleDoubleConverter().fromJson(json['total_kcal']),
  totalProtein: const FlexibleDoubleConverter().fromJson(json['total_protein']),
  totalCarbs: const FlexibleDoubleConverter().fromJson(json['total_carbs']),
  totalFat: const FlexibleDoubleConverter().fromJson(json['total_fat']),
  loggedAt: const FlexibleDateTimeConverter().fromJson(json['logged_at']),
  createdAt: const FlexibleDateTimeConverter().fromJson(json['created_at']),
  updatedAt: const FlexibleDateTimeConverter().fromJson(json['updated_at']),
  brand: json['brand'] as String?,
  imageUrl: json['image_url'] as String?,
);

Map<String, dynamic> _$CalorieEntryToJson(
  CalorieEntry instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'name': instance.name,
  'brand': instance.brand,
  'image_url': instance.imageUrl,
  'meal_type': _$MealTypeEnumMap[instance.mealType]!,
  'consumed_amount': const FlexibleDoubleConverter().toJson(
    instance.consumedAmount,
  ),
  'consumed_unit': _$ConsumedUnitEnumMap[instance.consumedUnit]!,
  'per100_kcal': const FlexibleDoubleConverter().toJson(instance.per100Kcal),
  'per100_protein': const FlexibleDoubleConverter().toJson(
    instance.per100Protein,
  ),
  'per100_carbs': const FlexibleDoubleConverter().toJson(instance.per100Carbs),
  'per100_fat': const FlexibleDoubleConverter().toJson(instance.per100Fat),
  'total_kcal': const FlexibleDoubleConverter().toJson(instance.totalKcal),
  'total_protein': const FlexibleDoubleConverter().toJson(
    instance.totalProtein,
  ),
  'total_carbs': const FlexibleDoubleConverter().toJson(instance.totalCarbs),
  'total_fat': const FlexibleDoubleConverter().toJson(instance.totalFat),
  'logged_at': const FlexibleDateTimeConverter().toJson(instance.loggedAt),
  'created_at': const FlexibleDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const FlexibleDateTimeConverter().toJson(instance.updatedAt),
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
