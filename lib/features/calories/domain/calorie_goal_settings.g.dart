// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalorieGoalWeeklyCheckInSnapshot _$CalorieGoalWeeklyCheckInSnapshotFromJson(
  Map<String, dynamic> json,
) => CalorieGoalWeeklyCheckInSnapshot(
  windowStartDate: const FlexibleDateTimeConverter().fromJson(
    json['window_start_date'],
  ),
  windowEndDate: const FlexibleDateTimeConverter().fromJson(
    json['window_end_date'],
  ),
  trendWeightChangePerDay: const FlexibleDoubleConverter().fromJson(
    json['trend_weight_change_per_day'],
  ),
  calculatedTrueTdeeKcal: const FlexibleDoubleConverter().fromJson(
    json['calculated_true_tdee_kcal'],
  ),
  averageActiveKcal: const FlexibleDoubleConverter().fromJson(
    json['average_active_kcal'],
  ),
  lowConfidence: json['low_confidence'] as bool,
);

Map<String, dynamic> _$CalorieGoalWeeklyCheckInSnapshotToJson(
  CalorieGoalWeeklyCheckInSnapshot instance,
) => <String, dynamic>{
  'window_start_date': const FlexibleDateTimeConverter().toJson(
    instance.windowStartDate,
  ),
  'window_end_date': const FlexibleDateTimeConverter().toJson(
    instance.windowEndDate,
  ),
  'trend_weight_change_per_day': const FlexibleDoubleConverter().toJson(
    instance.trendWeightChangePerDay,
  ),
  'calculated_true_tdee_kcal': const FlexibleDoubleConverter().toJson(
    instance.calculatedTrueTdeeKcal,
  ),
  'average_active_kcal': const FlexibleDoubleConverter().toJson(
    instance.averageActiveKcal,
  ),
  'low_confidence': instance.lowConfidence,
};

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
  source:
      $enumDecodeNullable(
        _$CalorieGoalSourceEnumMap,
        json['source'],
        unknownValue: CalorieGoalSource.manual,
      ) ??
      CalorieGoalSource.manual,
  weeklyCheckInSnapshot: json['weekly_check_in_snapshot'] == null
      ? null
      : CalorieGoalWeeklyCheckInSnapshot.fromJson(
          json['weekly_check_in_snapshot'] as Map<String, dynamic>,
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
  'source': _$CalorieGoalSourceEnumMap[instance.source]!,
  'weekly_check_in_snapshot': instance.weeklyCheckInSnapshot?.toJson(),
};

const _$CalorieGoalSourceEnumMap = {
  CalorieGoalSource.manual: 'manual',
  CalorieGoalSource.calculator: 'calculator',
  CalorieGoalSource.weeklyCheckIn: 'weekly_checkin',
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
  'pending_weekly_check_in': instance.pendingWeeklyCheckIn?.toJson(),
  'skipped_intake_day_keys': instance.skippedIntakeDayKeys,
};
