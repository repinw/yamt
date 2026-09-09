import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/domain/calories_json_converters.dart';

part 'calorie_calculator_profile.g.dart';

/// Defines calorie calculator sex.
@JsonEnum(valueField: 'jsonValue')
enum CalorieCalculatorSex {
  /// Male.
  male('male'),

  /// Female.
  female('female')
  ;

  const CalorieCalculatorSex(this.jsonValue);

  /// The json value.
  final String jsonValue;
}

/// Defines calorie goal mode.
@JsonEnum(valueField: 'jsonValue')
enum CalorieGoalMode {
  /// Lose.
  lose('lose'),

  /// Maintain.
  maintain('maintain'),

  /// Gain.
  gain('gain')
  ;

  const CalorieGoalMode(this.jsonValue);

  /// The json value.
  final String jsonValue;
}

/// Defines calorie calculator profile.
@JsonSerializable(fieldRename: FieldRename.snake)
class CalorieCalculatorProfile {
  /// The calorie calculator profile.
  const CalorieCalculatorProfile({
    required this.sex,
    required this.weightKg,
    required this.heightCm,
    required this.ageYears,
    required this.activityLevel,
    required this.goalMode,
    required this.goalSpeedKgPerWeek,
    this.targetWeightKg,
    this.trainingWeekdays = const <int>[
      DateTime.monday,
      DateTime.wednesday,
      DateTime.friday,
    ],
    this.trainingDayKcalOffset = 0.0,
  });

  /// Creates a [CalorieCalculatorProfile] for from json.
  factory CalorieCalculatorProfile.fromJson(Map<String, dynamic> json) {
    return _$CalorieCalculatorProfileFromJson(json);
  }

  /// Creates a [CalorieCalculatorProfile] for defaults.
  const CalorieCalculatorProfile.defaults()
    : sex = CalorieCalculatorSex.male,
      weightKg = 80,
      heightCm = 180,
      ageYears = 30,
      activityLevel = 1.2,
      goalMode = CalorieGoalMode.maintain,
      goalSpeedKgPerWeek = 0,
      targetWeightKg = null,
      trainingWeekdays = const <int>[
        DateTime.monday,
        DateTime.wednesday,
        DateTime.friday,
      ],
      trainingDayKcalOffset = 0.0;

  @JsonKey(
    defaultValue: CalorieCalculatorSex.male,
    unknownEnumValue: CalorieCalculatorSex.male,
  )
  /// The sex.
  final CalorieCalculatorSex sex;

  /// The weight kg.
  @FlexibleDoubleConverter()
  final double weightKg;

  /// The height cm.
  @FlexibleDoubleConverter()
  final double heightCm;

  /// The age years.
  final int ageYears;

  /// The activity level.
  @FlexibleDoubleConverter()
  final double activityLevel;
  @JsonKey(
    defaultValue: CalorieGoalMode.maintain,
    unknownEnumValue: CalorieGoalMode.maintain,
  )
  /// The goal mode.
  final CalorieGoalMode goalMode;

  /// The goal speed kg per week.
  @FlexibleDoubleConverter()
  final double goalSpeedKgPerWeek;

  /// Optional target weight in kg.
  @NullableFlexibleDoubleConverter()
  final double? targetWeightKg;

  /// Configured weekdays for training (1 = Monday, 7 = Sunday).
  final List<int> trainingWeekdays;

  /// Extra calories allocated to training days (calorie cycling).
  @FlexibleDoubleConverter()
  final double trainingDayKcalOffset;

  /// To json.
  Map<String, dynamic> toJson() => _$CalorieCalculatorProfileToJson(this);

  /// Copy with.
  CalorieCalculatorProfile copyWith({
    CalorieCalculatorSex? sex,
    double? weightKg,
    double? heightCm,
    int? ageYears,
    double? activityLevel,
    CalorieGoalMode? goalMode,
    double? goalSpeedKgPerWeek,
    double? targetWeightKg,
    List<int>? trainingWeekdays,
    double? trainingDayKcalOffset,
  }) {
    return CalorieCalculatorProfile(
      sex: sex ?? this.sex,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      ageYears: ageYears ?? this.ageYears,
      activityLevel: activityLevel ?? this.activityLevel,
      goalMode: goalMode ?? this.goalMode,
      goalSpeedKgPerWeek: goalSpeedKgPerWeek ?? this.goalSpeedKgPerWeek,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      trainingWeekdays: trainingWeekdays ?? this.trainingWeekdays,
      trainingDayKcalOffset:
          trainingDayKcalOffset ?? this.trainingDayKcalOffset,
    );
  }
}
