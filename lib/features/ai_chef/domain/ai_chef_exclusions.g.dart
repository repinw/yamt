// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chef_exclusions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AiChefExclusions _$AiChefExclusionsFromJson(Map<String, dynamic> json) =>
    _AiChefExclusions(
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AiChefExclusionsToJson(_AiChefExclusions instance) =>
    <String, dynamic>{'ingredients': instance.ingredients};
