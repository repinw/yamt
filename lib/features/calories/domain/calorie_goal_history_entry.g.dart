// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_history_entry.dart';

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
  expectedActivityKcal: const NullableFlexibleDoubleConverter().fromJson(
    json['expected_activity_kcal'],
  ),
  countingStartDate: const NullableFlexibleDateTimeConverter().fromJson(
    json['counting_start_date'],
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
  'expected_activity_kcal': const NullableFlexibleDoubleConverter().toJson(
    instance.expectedActivityKcal,
  ),
  'effective_date': const FlexibleDateTimeConverter().toJson(
    instance.effectiveDate,
  ),
  'changed_at': const NullableFlexibleDateTimeConverter().toJson(
    instance.changedAt,
  ),
  'counting_start_date': const NullableFlexibleDateTimeConverter().toJson(
    instance.countingStartDate,
  ),
  'source': _$CalorieGoalSourceEnumMap[instance.source]!,
  'weekly_check_in_snapshot': instance.weeklyCheckInSnapshot?.toJson(),
};

const _$CalorieGoalSourceEnumMap = {
  CalorieGoalSource.manual: 'manual',
  CalorieGoalSource.calculator: 'calculator',
  CalorieGoalSource.weeklyCheckIn: 'weekly_checkin',
};
