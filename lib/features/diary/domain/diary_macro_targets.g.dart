// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_macro_targets.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiaryMacroTargets _$DiaryMacroTargetsFromJson(Map<String, dynamic> json) =>
    DiaryMacroTargets(
      carbs: (json['carbs'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
    );

Map<String, dynamic> _$DiaryMacroTargetsToJson(DiaryMacroTargets instance) =>
    <String, dynamic>{
      'carbs': instance.carbs,
      'protein': instance.protein,
      'fat': instance.fat,
    };
