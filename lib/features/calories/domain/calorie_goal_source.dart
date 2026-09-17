import 'package:json_annotation/json_annotation.dart';

/// Defines calorie goal source.
@JsonEnum(valueField: 'jsonValue')
enum CalorieGoalSource {
  /// Manual.
  manual('manual'),

  /// Calculator.
  calculator('calculator'),

  /// Weekly check in.
  weeklyCheckIn('weekly_checkin');

  new(this.jsonValue);

  /// The json value.
  final String jsonValue;
}
