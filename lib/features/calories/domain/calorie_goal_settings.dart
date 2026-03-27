import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/domain/calories_json_converters.dart';

part 'calorie_goal_settings.g.dart';

const defaultDailyCalorieGoalKcal = 2500.0;

@JsonSerializable(fieldRename: FieldRename.snake)
class CalorieGoalSettings {
  const CalorieGoalSettings({
    required this.dailyKcalGoal,
    required this.updatedAt,
  });

  const CalorieGoalSettings.empty() : dailyKcalGoal = null, updatedAt = null;

  @NullableFlexibleDoubleConverter()
  final double? dailyKcalGoal;
  @NullableFlexibleDateTimeConverter()
  final DateTime? updatedAt;

  bool get hasGoal => dailyKcalGoal != null;

  factory CalorieGoalSettings.fromJson(Map<String, dynamic> json) {
    return _$CalorieGoalSettingsFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CalorieGoalSettingsToJson(this);

  CalorieGoalSettings copyWith({double? dailyKcalGoal, DateTime? updatedAt}) {
    return CalorieGoalSettings(
      dailyKcalGoal: dailyKcalGoal ?? this.dailyKcalGoal,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
