// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_calorie_goal_weekly_check_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PendingCalorieGoalWeeklyCheckIn _$PendingCalorieGoalWeeklyCheckInFromJson(
  Map<String, dynamic> json,
) => PendingCalorieGoalWeeklyCheckIn(
  windowStartDate: const DateTimeJsonConverter().fromJson(
    json['window_start_date'] as DateTime,
  ),
  windowEndDate: const DateTimeJsonConverter().fromJson(
    json['window_end_date'] as DateTime,
  ),
  dueDate: const DateTimeJsonConverter().fromJson(json['due_date'] as DateTime),
  dismissedAt: _$JsonConverterFromJson<DateTime, DateTime>(
    json['dismissed_at'],
    const DateTimeJsonConverter().fromJson,
  ),
);

Map<String, dynamic> _$PendingCalorieGoalWeeklyCheckInToJson(
  PendingCalorieGoalWeeklyCheckIn instance,
) => <String, dynamic>{
  'window_start_date': const DateTimeJsonConverter().toJson(
    instance.windowStartDate,
  ),
  'window_end_date': const DateTimeJsonConverter().toJson(
    instance.windowEndDate,
  ),
  'due_date': const DateTimeJsonConverter().toJson(instance.dueDate),
  'dismissed_at': _$JsonConverterToJson<DateTime, DateTime>(
    instance.dismissedAt,
    const DateTimeJsonConverter().toJson,
  ),
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
