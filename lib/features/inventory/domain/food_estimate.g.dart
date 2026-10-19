// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_estimate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodEstimateIngredient _$FoodEstimateIngredientFromJson(
  Map<String, dynamic> json,
) => FoodEstimateIngredient(
  name: json['name'] as String,
  grams: (json['grams'] as num).toDouble(),
  kcal: (json['kcal'] as num).toDouble(),
);

Map<String, dynamic> _$FoodEstimateIngredientToJson(
  FoodEstimateIngredient instance,
) => <String, dynamic>{
  'name': instance.name,
  'grams': instance.grams,
  'kcal': instance.kcal,
};

FoodEstimate _$FoodEstimateFromJson(Map<String, dynamic> json) => FoodEstimate(
  name: json['name'] as String,
  portionGrams: (json['portion_grams'] as num).toDouble(),
  kcalLean: (json['kcal_lean'] as num).toDouble(),
  kcalRich: (json['kcal_rich'] as num).toDouble(),
  per100: GlobalFoodNutrition.fromJson(json['per_100'] as Map<String, dynamic>),
  ingredients: (json['ingredients'] as List<dynamic>)
      .map((e) => FoodEstimateIngredient.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$FoodEstimateToJson(FoodEstimate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'portion_grams': instance.portionGrams,
      'kcal_lean': instance.kcalLean,
      'kcal_rich': instance.kcalRich,
      'per_100': instance.per100.toJson(),
      'ingredients': instance.ingredients.map((e) => e.toJson()).toList(),
    };

SavedFoodEstimate _$SavedFoodEstimateFromJson(Map<String, dynamic> json) =>
    SavedFoodEstimate(
      estimate: FoodEstimate.fromJson(json['estimate'] as Map<String, dynamic>),
      level: $enumDecode(_$FoodEstimateLevelEnumMap, json['level']),
      description: json['description'] as String,
    );

Map<String, dynamic> _$SavedFoodEstimateToJson(SavedFoodEstimate instance) =>
    <String, dynamic>{
      'estimate': instance.estimate.toJson(),
      'level': _$FoodEstimateLevelEnumMap[instance.level]!,
      'description': instance.description,
    };

const _$FoodEstimateLevelEnumMap = {
  FoodEstimateLevel.lean: 'lean',
  FoodEstimateLevel.normal: 'normal',
  FoodEstimateLevel.rich: 'rich',
};
