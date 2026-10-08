// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_pot_weighing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PreparedMealPotWeighing _$PreparedMealPotWeighingFromJson(
  Map<String, dynamic> json,
) => PreparedMealPotWeighing(
  netWeight: (json['net_weight'] as num).toInt(),
  weighedAt: DateTime.parse(json['weighed_at'] as String),
  remainingPortions: json['remaining_portions'] as num,
);

Map<String, dynamic> _$PreparedMealPotWeighingToJson(
  PreparedMealPotWeighing instance,
) => <String, dynamic>{
  'net_weight': instance.netWeight,
  'weighed_at': instance.weighedAt.toIso8601String(),
  'remaining_portions': instance.remainingPortions,
};
