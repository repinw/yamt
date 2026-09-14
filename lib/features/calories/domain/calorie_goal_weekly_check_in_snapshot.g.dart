// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_weekly_check_in_snapshot.dart';

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
  lowConfidence: json['low_confidence'] as bool,
  measuredTdeeKcal: json['measured_tdee_kcal'] == null
      ? 0
      : const FlexibleDoubleConverter().fromJson(json['measured_tdee_kcal']),
  calculatedTdeeKcal: json['calculated_tdee_kcal'] == null
      ? 0
      : const FlexibleDoubleConverter().fromJson(json['calculated_tdee_kcal']),
  baseGoalKcal: json['base_goal_kcal'] == null
      ? 0
      : const FlexibleDoubleConverter().fromJson(json['base_goal_kcal']),
  inputHash: json['input_hash'] as String?,
  invalidatedAt: const NullableFlexibleDateTimeConverter().fromJson(
    json['invalidated_at'],
  ),
  isRejected: json['is_rejected'] as bool? ?? false,
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
  'measured_tdee_kcal': const FlexibleDoubleConverter().toJson(
    instance.measuredTdeeKcal,
  ),
  'calculated_tdee_kcal': const FlexibleDoubleConverter().toJson(
    instance.calculatedTdeeKcal,
  ),
  'base_goal_kcal': const FlexibleDoubleConverter().toJson(
    instance.baseGoalKcal,
  ),
  'low_confidence': instance.lowConfidence,
  'input_hash': ?instance.inputHash,
  'invalidated_at': ?const NullableFlexibleDateTimeConverter().toJson(
    instance.invalidatedAt,
  ),
  'is_rejected': instance.isRejected,
};
