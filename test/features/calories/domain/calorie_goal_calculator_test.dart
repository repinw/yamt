import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';

void main() {
  test('calculates male BMR and TDEE with maintain mode', () {
    const profile = CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.male,
      weightKg: 80,
      heightCm: 180,
      ageYears: 30,
      activityLevel: 1.4,
      goalMode: CalorieGoalMode.maintain,
      goalSpeedKgPerWeek: 0.5,
    );

    final result = CalorieGoalCalculator.calculate(profile);

    expect(result.bmrKcal, 1780);
    expect(result.tdeeKcal, 2492);
    expect(result.dailyAdjustmentKcal, 0);
    expect(result.finalGoalKcal, 2492);
    expect(result.wasClampedToMinimum, isFalse);
  });

  test('calculates female BMR and applies calorie deficit for weight loss', () {
    const profile = CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.female,
      weightKg: 65,
      heightCm: 170,
      ageYears: 28,
      activityLevel: 1.5,
      goalMode: CalorieGoalMode.lose,
      goalSpeedKgPerWeek: 0.5,
    );

    final result = CalorieGoalCalculator.calculate(profile);

    expect(result.bmrKcal, 1411.5);
    expect(result.tdeeKcal, 2117.25);
    expect(result.dailyAdjustmentKcal, 500);
    expect(result.finalGoalKcal, 1617.25);
    expect(result.wasClampedToMinimum, isFalse);
  });

  test('adds calorie surplus for weight gain', () {
    const profile = CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.male,
      weightKg: 75,
      heightCm: 178,
      ageYears: 33,
      activityLevel: 1.6,
      goalMode: CalorieGoalMode.gain,
      goalSpeedKgPerWeek: 0.25,
    );

    final result = CalorieGoalCalculator.calculate(profile);

    expect(result.dailyAdjustmentKcal, 250);
    expect(result.finalGoalKcal, 2974);
    expect(result.wasClampedToMinimum, isFalse);
  });

  test('clamps aggressive weight loss to the safety minimum', () {
    const profile = CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.female,
      weightKg: 50,
      heightCm: 155,
      ageYears: 60,
      activityLevel: 1.2,
      goalMode: CalorieGoalMode.lose,
      goalSpeedKgPerWeek: 0.75,
    );

    final result = CalorieGoalCalculator.calculate(profile);

    expect(result.dailyAdjustmentKcal, 750);
    expect(result.finalGoalKcal, minimumCalorieGoalKcal);
    expect(result.wasClampedToMinimum, isTrue);
  });
}
