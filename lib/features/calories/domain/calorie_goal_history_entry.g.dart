// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_history_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalorieGoalHistoryEntry _$CalorieGoalHistoryEntryFromJson(
  Map<String, dynamic> json,
) => CalorieGoalHistoryEntry(
  dailyKcalGoal: (json['daily_kcal_goal'] as num?)?.toDouble(),
  calculatorProfile: json['calculator_profile'] == null
      ? null
      : CalorieCalculatorProfile.fromJson(
          json['calculator_profile'] as Map<String, dynamic>,
        ),
  effectiveDate: const DateTimeJsonConverter().fromJson(
    json['effective_date'] as DateTime,
  ),
  changedAt: _$JsonConverterFromJson<DateTime, DateTime>(
    json['changed_at'],
    const DateTimeJsonConverter().fromJson,
  ),
  source: $enumDecode(_$CalorieGoalSourceEnumMap, json['source']),
  countingStartDate: _$JsonConverterFromJson<DateTime, DateTime>(
    json['counting_start_date'],
    const DateTimeJsonConverter().fromJson,
  ),
  weeklyCheckInSnapshot: json['weekly_check_in_snapshot'] == null
      ? null
      : CalorieGoalWeeklyCheckInSnapshot.fromJson(
          json['weekly_check_in_snapshot'] as Map<String, dynamic>,
        ),
  reachedAt: _$JsonConverterFromJson<DateTime, DateTime>(
    json['reached_at'],
    const DateTimeJsonConverter().fromJson,
  ),
  reachedWeightKg: (json['reached_weight_kg'] as num?)?.toDouble(),
  reachedPromptHandledAt: _$JsonConverterFromJson<DateTime, DateTime>(
    json['reached_prompt_handled_at'],
    const DateTimeJsonConverter().fromJson,
  ),
  endedAt: _$JsonConverterFromJson<DateTime, DateTime>(
    json['ended_at'],
    const DateTimeJsonConverter().fromJson,
  ),
  endedWeightKg: (json['ended_weight_kg'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CalorieGoalHistoryEntryToJson(
  CalorieGoalHistoryEntry instance,
) => <String, dynamic>{
  'daily_kcal_goal': instance.dailyKcalGoal,
  'calculator_profile': instance.calculatorProfile?.toJson(),
  'effective_date': const DateTimeJsonConverter().toJson(
    instance.effectiveDate,
  ),
  'changed_at': _$JsonConverterToJson<DateTime, DateTime>(
    instance.changedAt,
    const DateTimeJsonConverter().toJson,
  ),
  'counting_start_date': _$JsonConverterToJson<DateTime, DateTime>(
    instance.countingStartDate,
    const DateTimeJsonConverter().toJson,
  ),
  'source': _$CalorieGoalSourceEnumMap[instance.source]!,
  'weekly_check_in_snapshot': instance.weeklyCheckInSnapshot?.toJson(),
  'reached_at': _$JsonConverterToJson<DateTime, DateTime>(
    instance.reachedAt,
    const DateTimeJsonConverter().toJson,
  ),
  'reached_weight_kg': instance.reachedWeightKg,
  'reached_prompt_handled_at': _$JsonConverterToJson<DateTime, DateTime>(
    instance.reachedPromptHandledAt,
    const DateTimeJsonConverter().toJson,
  ),
  'ended_at': _$JsonConverterToJson<DateTime, DateTime>(
    instance.endedAt,
    const DateTimeJsonConverter().toJson,
  ),
  'ended_weight_kg': instance.endedWeightKg,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$CalorieGoalSourceEnumMap = {
  CalorieGoalSource.manual: 'manual',
  CalorieGoalSource.calculator: 'calculator',
  CalorieGoalSource.weeklyCheckIn: 'weekly_checkin',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
