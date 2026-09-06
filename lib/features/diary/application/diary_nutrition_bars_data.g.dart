// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_nutrition_bars_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiaryNutritionBarsData _$DiaryNutritionBarsDataFromJson(
  Map<String, dynamic> json,
) => DiaryNutritionBarsData(
  carbs: (json['carbs'] as num).toDouble(),
  protein: (json['protein'] as num).toDouble(),
  fat: (json['fat'] as num).toDouble(),
  goals: DiaryMacroTargets.fromJson(json['goals'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DiaryNutritionBarsDataToJson(
  DiaryNutritionBarsData instance,
) => <String, dynamic>{
  'carbs': instance.carbs,
  'protein': instance.protein,
  'fat': instance.fat,
  'goals': instance.goals.toJson(),
};
