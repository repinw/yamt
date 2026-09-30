// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_weekly_check_in_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalorieGoalWeeklyCheckInSnapshot _$CalorieGoalWeeklyCheckInSnapshotFromJson(
  Map<String, dynamic> json,
) => CalorieGoalWeeklyCheckInSnapshot(
  windowStartDate: const DateTimeJsonConverter().fromJson(
    json['window_start_date'] as DateTime,
  ),
  windowEndDate: const DateTimeJsonConverter().fromJson(
    json['window_end_date'] as DateTime,
  ),
  trendWeightChangePerDay: (json['trend_weight_change_per_day'] as num)
      .toDouble(),
  lowConfidence: json['low_confidence'] as bool,
  measuredTdeeKcal: (json['measured_tdee_kcal'] as num).toDouble(),
  calculatedTdeeKcal: (json['calculated_tdee_kcal'] as num).toDouble(),
  baseGoalKcal: (json['base_goal_kcal'] as num).toDouble(),
  isRejected: json['is_rejected'] as bool,
  inputHash: json['input_hash'] as String?,
  invalidatedAt: _$JsonConverterFromJson<DateTime, DateTime>(
    json['invalidated_at'],
    const DateTimeJsonConverter().fromJson,
  ),
  macroWeightKg: (json['macro_weight_kg'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CalorieGoalWeeklyCheckInSnapshotToJson(
  CalorieGoalWeeklyCheckInSnapshot instance,
) => <String, dynamic>{
  'window_start_date': const DateTimeJsonConverter().toJson(
    instance.windowStartDate,
  ),
  'window_end_date': const DateTimeJsonConverter().toJson(
    instance.windowEndDate,
  ),
  'trend_weight_change_per_day': instance.trendWeightChangePerDay,
  'measured_tdee_kcal': instance.measuredTdeeKcal,
  'calculated_tdee_kcal': instance.calculatedTdeeKcal,
  'base_goal_kcal': instance.baseGoalKcal,
  'low_confidence': instance.lowConfidence,
  'input_hash': ?instance.inputHash,
  'invalidated_at': ?_$JsonConverterToJson<DateTime, DateTime>(
    instance.invalidatedAt,
    const DateTimeJsonConverter().toJson,
  ),
  'is_rejected': instance.isRejected,
  'macro_weight_kg': instance.macroWeightKg,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
