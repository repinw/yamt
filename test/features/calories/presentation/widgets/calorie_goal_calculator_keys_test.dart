import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_keys.dart';

void main() {
  test('dynamic calorie calculator keys generate stable values', () {
    expect(
      CalorieGoalCalculatorSheetKeys.activityLevelOption('high'),
      const Key('calorie_calculator_activity_level_option_high'),
    );
  });
}
