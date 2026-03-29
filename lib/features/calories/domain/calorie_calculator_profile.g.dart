// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_calculator_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalorieCalculatorProfile _$CalorieCalculatorProfileFromJson(
  Map<String, dynamic> json,
) => CalorieCalculatorProfile(
  sex:
      $enumDecodeNullable(
        _$CalorieCalculatorSexEnumMap,
        json['sex'],
        unknownValue: CalorieCalculatorSex.male,
      ) ??
      CalorieCalculatorSex.male,
  weightKg: const FlexibleDoubleConverter().fromJson(json['weight_kg']),
  heightCm: const FlexibleDoubleConverter().fromJson(json['height_cm']),
  ageYears: (json['age_years'] as num).toInt(),
  activityLevel: const FlexibleDoubleConverter().fromJson(
    json['activity_level'],
  ),
  goalMode:
      $enumDecodeNullable(
        _$CalorieGoalModeEnumMap,
        json['goal_mode'],
        unknownValue: CalorieGoalMode.maintain,
      ) ??
      CalorieGoalMode.maintain,
  goalSpeedKgPerWeek: const FlexibleDoubleConverter().fromJson(
    json['goal_speed_kg_per_week'],
  ),
);

Map<String, dynamic> _$CalorieCalculatorProfileToJson(
  CalorieCalculatorProfile instance,
) => <String, dynamic>{
  'sex': _$CalorieCalculatorSexEnumMap[instance.sex]!,
  'weight_kg': const FlexibleDoubleConverter().toJson(instance.weightKg),
  'height_cm': const FlexibleDoubleConverter().toJson(instance.heightCm),
  'age_years': instance.ageYears,
  'activity_level': const FlexibleDoubleConverter().toJson(
    instance.activityLevel,
  ),
  'goal_mode': _$CalorieGoalModeEnumMap[instance.goalMode]!,
  'goal_speed_kg_per_week': const FlexibleDoubleConverter().toJson(
    instance.goalSpeedKgPerWeek,
  ),
};

const _$CalorieCalculatorSexEnumMap = {
  CalorieCalculatorSex.male: 'male',
  CalorieCalculatorSex.female: 'female',
};

const _$CalorieGoalModeEnumMap = {
  CalorieGoalMode.lose: 'lose',
  CalorieGoalMode.maintain: 'maintain',
  CalorieGoalMode.gain: 'gain',
};
