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
};
