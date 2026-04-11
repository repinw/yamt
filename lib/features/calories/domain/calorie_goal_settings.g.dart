// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalorieGoalHistoryEntry _$CalorieGoalHistoryEntryFromJson(
  Map<String, dynamic> json,
) => CalorieGoalHistoryEntry(
  dailyKcalGoal: const NullableFlexibleDoubleConverter().fromJson(
    json['daily_kcal_goal'],
  ),
  calculatorProfile: json['calculator_profile'] == null
      ? null
      : CalorieCalculatorProfile.fromJson(
          json['calculator_profile'] as Map<String, dynamic>,
        ),
  effectiveDate: const FlexibleDateTimeConverter().fromJson(
    json['effective_date'],
  ),
  changedAt: const NullableFlexibleDateTimeConverter().fromJson(
    json['changed_at'],
  ),
);

Map<String, dynamic> _$CalorieGoalHistoryEntryToJson(
  CalorieGoalHistoryEntry instance,
) => <String, dynamic>{
  'daily_kcal_goal': const NullableFlexibleDoubleConverter().toJson(
    instance.dailyKcalGoal,
  ),
  'calculator_profile': instance.calculatorProfile?.toJson(),
  'effective_date': const FlexibleDateTimeConverter().toJson(
    instance.effectiveDate,
  ),
  'changed_at': const NullableFlexibleDateTimeConverter().toJson(
    instance.changedAt,
  ),
};

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
      eatingWindowStartMinuteOfDay:
          (json['eating_window_start_minute_of_day'] as num?)?.toInt() ?? 360,
      eatingWindowEndMinuteOfDay:
          (json['eating_window_end_minute_of_day'] as num?)?.toInt() ?? 1320,
    );

Map<String, dynamic> _$CalorieGoalSettingsToJson(
  CalorieGoalSettings instance,
) => <String, dynamic>{
  'daily_kcal_goal': const NullableFlexibleDoubleConverter().toJson(
    instance.dailyKcalGoal,
  ),
  'calculator_profile': instance.calculatorProfile?.toJson(),
  'updated_at': const NullableFlexibleDateTimeConverter().toJson(
    instance.updatedAt,
  ),
  'goal_history': instance.goalHistory.map((e) => e.toJson()).toList(),
  'eating_window_start_minute_of_day': instance.eatingWindowStartMinuteOfDay,
  'eating_window_end_minute_of_day': instance.eatingWindowEndMinuteOfDay,
};
