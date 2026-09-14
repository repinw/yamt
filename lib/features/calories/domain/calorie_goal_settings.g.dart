// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalorieGoalSettings _$CalorieGoalSettingsFromJson(Map<String, dynamic> json) =>
    CalorieGoalSettings(
      dailyKcalGoal: const NullableFlexibleDoubleConverter().fromJson(
        json['daily_kcal_goal'],
      ),
      calculatorProfile: json['calculator_profile'] == null
          ? null
          : CalorieCalculatorProfile.fromJson(
              json['calculator_profile'] as Map<String, dynamic>,
            ),
      updatedAt: const NullableFlexibleDateTimeConverter().fromJson(
        json['updated_at'],
      ),
      goalHistory:
          (json['goal_history'] as List<dynamic>?)
              ?.map(
                (e) =>
                    CalorieGoalHistoryEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      pendingWeeklyCheckIn: json['pending_weekly_check_in'] == null
          ? null
          : PendingCalorieGoalWeeklyCheckIn.fromJson(
              json['pending_weekly_check_in'] as Map<String, dynamic>,
            ),
      skippedIntakeDayKeys:
          (json['skipped_intake_day_keys'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      calorieMathVersion: (json['calorie_math_version'] as num?)?.toInt() ?? 3,
      expectedActivityKcal: const NullableFlexibleDoubleConverter().fromJson(
        json['expected_activity_kcal'],
      ),
      activityTrackingStartDate: const NullableFlexibleDateTimeConverter()
          .fromJson(json['activity_tracking_start_date']),
      trainingWeekdays:
          (json['training_weekdays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[DateTime.monday, DateTime.wednesday, DateTime.friday],
      trainingDayKcalOffset: json['training_day_kcal_offset'] == null
          ? 0.0
          : const FlexibleDoubleConverter().fromJson(
              json['training_day_kcal_offset'],
            ),
      trainingDayOverrides:
          (json['training_day_overrides'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as bool),
          ) ??
          const <String, bool>{},
      pauseDayKeys:
          (json['pause_day_keys'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$CalorieGoalSettingsToJson(
  CalorieGoalSettings instance,
) => <String, dynamic>{
  'daily_kcal_goal': const NullableFlexibleDoubleConverter().toJson(
    instance.dailyKcalGoal,
  ),
  'calculator_profile': instance.calculatorProfile?.toJson(),
  'calorie_math_version': instance.calorieMathVersion,
  'expected_activity_kcal': const NullableFlexibleDoubleConverter().toJson(
    instance.expectedActivityKcal,
  ),
  'activity_tracking_start_date': const NullableFlexibleDateTimeConverter()
      .toJson(instance.activityTrackingStartDate),
  'updated_at': const NullableFlexibleDateTimeConverter().toJson(
    instance.updatedAt,
  ),
  'goal_history': instance.goalHistory.map((e) => e.toJson()).toList(),
  'pending_weekly_check_in': instance.pendingWeeklyCheckIn?.toJson(),
  'skipped_intake_day_keys': instance.skippedIntakeDayKeys,
  'training_weekdays': instance.trainingWeekdays,
  'training_day_kcal_offset': const FlexibleDoubleConverter().toJson(
    instance.trainingDayKcalOffset,
  ),
  'training_day_overrides': instance.trainingDayOverrides,
  'pause_day_keys': instance.pauseDayKeys,
};
