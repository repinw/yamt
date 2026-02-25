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
      updatedAt: const NullableFlexibleDateTimeConverter().fromJson(
        json['updated_at'],
      ),
    );

Map<String, dynamic> _$CalorieGoalSettingsToJson(
  CalorieGoalSettings instance,
) => <String, dynamic>{
  'daily_kcal_goal': const NullableFlexibleDoubleConverter().toJson(
    instance.dailyKcalGoal,
  ),
  'updated_at': const NullableFlexibleDateTimeConverter().toJson(
    instance.updatedAt,
  ),
};
