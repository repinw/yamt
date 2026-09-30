// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_calculator_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalorieCalculatorProfile _$CalorieCalculatorProfileFromJson(
  Map<String, dynamic> json,
) => CalorieCalculatorProfile(
  sex: $enumDecode(_$CalorieCalculatorSexEnumMap, json['sex']),
  weightKg: (json['weight_kg'] as num).toDouble(),
  heightCm: (json['height_cm'] as num).toDouble(),
  ageYears: (json['age_years'] as num).toInt(),
  activityLevel: (json['activity_level'] as num).toDouble(),
  goalMode: $enumDecode(_$CalorieGoalModeEnumMap, json['goal_mode']),
  goalSpeedKgPerWeek: (json['goal_speed_kg_per_week'] as num).toDouble(),
  birthDate: _$JsonConverterFromJson<DateTime, DateTime>(
    json['birth_date'],
    const DateTimeJsonConverter().fromJson,
  ),
  targetWeightKg: (json['target_weight_kg'] as num?)?.toDouble(),
  maintainUntil: _$JsonConverterFromJson<DateTime, DateTime>(
    json['maintain_until'],
    const DateTimeJsonConverter().fromJson,
  ),
  trainingWeekdays:
      (json['training_weekdays'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
  trainingDayKcalOffset:
      (json['training_day_kcal_offset'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$CalorieCalculatorProfileToJson(
  CalorieCalculatorProfile instance,
) => <String, dynamic>{
  'sex': _$CalorieCalculatorSexEnumMap[instance.sex]!,
  'weight_kg': instance.weightKg,
  'height_cm': instance.heightCm,
  'age_years': instance.ageYears,
  'birth_date': _$JsonConverterToJson<DateTime, DateTime>(
    instance.birthDate,
    const DateTimeJsonConverter().toJson,
  ),
  'activity_level': instance.activityLevel,
  'goal_mode': _$CalorieGoalModeEnumMap[instance.goalMode]!,
  'goal_speed_kg_per_week': instance.goalSpeedKgPerWeek,
  'target_weight_kg': instance.targetWeightKg,
  'maintain_until': _$JsonConverterToJson<DateTime, DateTime>(
    instance.maintainUntil,
    const DateTimeJsonConverter().toJson,
  ),
  'training_weekdays': instance.trainingWeekdays,
  'training_day_kcal_offset': instance.trainingDayKcalOffset,
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

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
