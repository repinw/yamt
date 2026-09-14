// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_calorie_goal_weekly_check_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PendingCalorieGoalWeeklyCheckIn _$PendingCalorieGoalWeeklyCheckInFromJson(
  Map<String, dynamic> json,
) => PendingCalorieGoalWeeklyCheckIn(
  windowStartDate: const FlexibleDateTimeConverter().fromJson(
    json['window_start_date'],
  ),
  windowEndDate: const FlexibleDateTimeConverter().fromJson(
    json['window_end_date'],
  ),
  dueDate: const FlexibleDateTimeConverter().fromJson(json['due_date']),
  dismissedAt: const NullableFlexibleDateTimeConverter().fromJson(
    json['dismissed_at'],
  ),
);

Map<String, dynamic> _$PendingCalorieGoalWeeklyCheckInToJson(
  PendingCalorieGoalWeeklyCheckIn instance,
) => <String, dynamic>{
  'window_start_date': const FlexibleDateTimeConverter().toJson(
    instance.windowStartDate,
  ),
  'window_end_date': const FlexibleDateTimeConverter().toJson(
    instance.windowEndDate,
  ),
  'due_date': const FlexibleDateTimeConverter().toJson(instance.dueDate),
  'dismissed_at': const NullableFlexibleDateTimeConverter().toJson(
    instance.dismissedAt,
  ),
};
