import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';
import 'package:yamt/features/onboarding/domain/intro_activity_option.dart';

void main() {
  test('offers four everyday levels mapped to rising activity factors', () {
    final factors = [
      for (final option in IntroActivityOption.values)
        option.calorieOption.palValue,
    ];

    expect(factors, [1.2, 1.375, 1.55, 1.725]);
  });

  test('finds the option for every level it offers', () {
    for (final option in IntroActivityOption.values) {
      expect(
        IntroActivityOption.fromCalorieOption(option.calorieOption),
        option,
      );
    }
  });

  test('maps the extreme level to the closest offered option', () {
    expect(
      IntroActivityOption.fromCalorieOption(CalorieActivityLevelOption.extreme),
      IntroActivityOption.hardLabour,
    );
  });
}
