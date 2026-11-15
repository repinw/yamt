// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_estimate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeEstimate _$RecipeEstimateFromJson(Map<String, dynamic> json) =>
    RecipeEstimate(
      kcal: (json['kcal'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      portions: (json['portions'] as num).toInt(),
      linesKey: json['lines_key'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lines: (json['lines'] as List<dynamic>?)
          ?.map((e) => RecipeLineNutrition.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RecipeEstimateToJson(RecipeEstimate instance) =>
    <String, dynamic>{
      'kcal': instance.kcal,
      'protein': instance.protein,
      'carbs': instance.carbs,
      'fat': instance.fat,
      'portions': instance.portions,
      'lines_key': instance.linesKey,
      'created_at': instance.createdAt.toIso8601String(),
      'lines': ?instance.lines?.map((e) => e.toJson()).toList(),
    };

RecipeLineNutrition _$RecipeLineNutritionFromJson(Map<String, dynamic> json) =>
    RecipeLineNutrition(
      kcal: (json['kcal'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
    );

Map<String, dynamic> _$RecipeLineNutritionToJson(
  RecipeLineNutrition instance,
) => <String, dynamic>{
  'kcal': instance.kcal,
  'protein': instance.protein,
  'carbs': instance.carbs,
  'fat': instance.fat,
};

RecipeLineWeight _$RecipeLineWeightFromJson(Map<String, dynamic> json) =>
    RecipeLineWeight(
      amount: (json['amount'] as num).toInt(),
      unit: $enumDecode(_$RecipeLineWeightUnitEnumMap, json['unit']),
      source: $enumDecode(_$RecipeLineWeightSourceEnumMap, json['source']),
    );

Map<String, dynamic> _$RecipeLineWeightToJson(RecipeLineWeight instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'unit': _$RecipeLineWeightUnitEnumMap[instance.unit]!,
      'source': _$RecipeLineWeightSourceEnumMap[instance.source]!,
    };

const _$RecipeLineWeightUnitEnumMap = {
  RecipeLineWeightUnit.gram: 'g',
  RecipeLineWeightUnit.milliliter: 'ml',
};

const _$RecipeLineWeightSourceEnumMap = {
  RecipeLineWeightSource.ai: 'ai',
  RecipeLineWeightSource.user: 'user',
};
