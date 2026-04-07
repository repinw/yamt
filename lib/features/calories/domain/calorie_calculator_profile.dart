import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/domain/calories_json_converters.dart';

part 'calorie_calculator_profile.g.dart';

@JsonEnum(valueField: 'jsonValue')
enum CalorieCalculatorSex {
  male('male'),
  female('female');

  const CalorieCalculatorSex(this.jsonValue);

  final String jsonValue;
}

@JsonEnum(valueField: 'jsonValue')
enum CalorieGoalMode {
  lose('lose'),
  maintain('maintain'),
  gain('gain');

  const CalorieGoalMode(this.jsonValue);

  final String jsonValue;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CalorieCalculatorProfile {
  const CalorieCalculatorProfile({
    required this.sex,
    required this.weightKg,
    required this.heightCm,
    required this.ageYears,
    required this.activityLevel,
    required this.goalMode,
    required this.goalSpeedKgPerWeek,
  });

  const CalorieCalculatorProfile.defaults()
    : sex = CalorieCalculatorSex.male,
      weightKg = 80,
      heightCm = 180,
      ageYears = 30,
      activityLevel = 1.2,
      goalMode = CalorieGoalMode.maintain,
      goalSpeedKgPerWeek = 0;

  @JsonKey(
    defaultValue: CalorieCalculatorSex.male,
    unknownEnumValue: CalorieCalculatorSex.male,
  )
  final CalorieCalculatorSex sex;
  @FlexibleDoubleConverter()
  final double weightKg;
  @FlexibleDoubleConverter()
  final double heightCm;
  final int ageYears;
  @FlexibleDoubleConverter()
  final double activityLevel;
  @JsonKey(
    defaultValue: CalorieGoalMode.maintain,
    unknownEnumValue: CalorieGoalMode.maintain,
  )
  final CalorieGoalMode goalMode;
  @FlexibleDoubleConverter()
  final double goalSpeedKgPerWeek;

  factory CalorieCalculatorProfile.fromJson(Map<String, dynamic> json) {
    return _$CalorieCalculatorProfileFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CalorieCalculatorProfileToJson(this);

  CalorieCalculatorProfile copyWith({
    CalorieCalculatorSex? sex,
    double? weightKg,
    double? heightCm,
    int? ageYears,
    double? activityLevel,
    CalorieGoalMode? goalMode,
    double? goalSpeedKgPerWeek,
  }) {
    return CalorieCalculatorProfile(
      sex: sex ?? this.sex,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      ageYears: ageYears ?? this.ageYears,
      activityLevel: activityLevel ?? this.activityLevel,
      goalMode: goalMode ?? this.goalMode,
      goalSpeedKgPerWeek: goalSpeedKgPerWeek ?? this.goalSpeedKgPerWeek,
    );
  }
}
