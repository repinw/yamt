// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalorieGoalSettings _$CalorieGoalSettingsFromJson(Map<String, dynamic> json) =>
    CalorieGoalSettings(
      dailyKcalGoal: (json['daily_kcal_goal'] as num?)?.toDouble(),
      calculatorProfile: json['calculator_profile'] == null
          ? null
          : CalorieCalculatorProfile.fromJson(
              json['calculator_profile'] as Map<String, dynamic>,
            ),
      updatedAt: _$JsonConverterFromJson<DateTime, DateTime>(
        json['updated_at'],
        const DateTimeJsonConverter().fromJson,
      ),
      goalHistory: (json['goal_history'] as List<dynamic>)
          .map(
            (e) => CalorieGoalHistoryEntry.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      pendingWeeklyCheckIn: json['pending_weekly_check_in'] == null
          ? null
          : PendingCalorieGoalWeeklyCheckIn.fromJson(
              json['pending_weekly_check_in'] as Map<String, dynamic>,
            ),
      skippedIntakeDayKeys: (json['skipped_intake_day_keys'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      calorieMathVersion: (json['calorie_math_version'] as num).toInt(),
      trainingWeekdays:
          (json['training_weekdays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      trainingDayKcalOffset:
          (json['training_day_kcal_offset'] as num?)?.toDouble() ?? 0.0,
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
  'daily_kcal_goal': instance.dailyKcalGoal,
  'calculator_profile': instance.calculatorProfile?.toJson(),
  'calorie_math_version': instance.calorieMathVersion,
  'updated_at': _$JsonConverterToJson<DateTime, DateTime>(
    instance.updatedAt,
    const DateTimeJsonConverter().toJson,
  ),
  'goal_history': instance.goalHistory.map((e) => e.toJson()).toList(),
  'pending_weekly_check_in': instance.pendingWeeklyCheckIn?.toJson(),
  'skipped_intake_day_keys': instance.skippedIntakeDayKeys,
  'training_weekdays': instance.trainingWeekdays,
  'training_day_kcal_offset': instance.trainingDayKcalOffset,
  'training_day_overrides': instance.trainingDayOverrides,
  'pause_day_keys': instance.pauseDayKeys,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
