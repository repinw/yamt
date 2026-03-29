import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calories_json_converters.dart';

part 'calorie_goal_settings.g.dart';

const defaultDailyCalorieGoalKcal = 2500.0;

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CalorieGoalSettings {
  const CalorieGoalSettings({
    required this.dailyKcalGoal,
    required this.calculatorProfile,
    required this.updatedAt,
  });

  const CalorieGoalSettings.empty()
    : dailyKcalGoal = null,
      calculatorProfile = null,
      updatedAt = null;

  @NullableFlexibleDoubleConverter()
  final double? dailyKcalGoal;
  final CalorieCalculatorProfile? calculatorProfile;
  @NullableFlexibleDateTimeConverter()
  final DateTime? updatedAt;

  bool get hasGoal => dailyKcalGoal != null;
  bool get hasCalculatorProfile => calculatorProfile != null;

  factory CalorieGoalSettings.fromJson(Map<String, dynamic> json) {
    return _$CalorieGoalSettingsFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CalorieGoalSettingsToJson(this);

  CalorieGoalSettings copyWith({
    double? dailyKcalGoal,
    CalorieCalculatorProfile? calculatorProfile,
    DateTime? updatedAt,
  }) {
    return CalorieGoalSettings(
      dailyKcalGoal: dailyKcalGoal ?? this.dailyKcalGoal,
      calculatorProfile: calculatorProfile ?? this.calculatorProfile,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
