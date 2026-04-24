import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';

void main() {
  test(
    'calculates exact maintenance calories for a sedentary male profile',
    () {
      const profile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 84,
        heightCm: 173,
        ageYears: 31,
        activityLevel: 1.2,
        goalMode: CalorieGoalMode.maintain,
        goalSpeedKgPerWeek: 0,
      );

      final result = CalorieGoalCalculator.calculate(profile);

      expect(result.bmrKcal, 1771.25);
      expect(result.tdeeKcal, 2125.5);
      expect(result.expectedActivityKcal, 354.25);
      expect(result.dailyAdjustmentKcal, 0);
      expect(result.finalGoalKcal, 2125.5);
      expect(result.wasClampedToMinimum, isFalse);
    },
  );

  test('female counterpart produces a lower maintenance result', () {
    const profile = CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.female,
      weightKg: 84,
      heightCm: 173,
      ageYears: 31,
      activityLevel: 1.2,
      goalMode: CalorieGoalMode.maintain,
      goalSpeedKgPerWeek: 0,
    );

    final result = CalorieGoalCalculator.calculate(profile);

    expect(result.bmrKcal, 1605.25);
    expect(result.tdeeKcal, 1926.3);
    expect(result.expectedActivityKcal, closeTo(321.05, 0.000001));
    expect(result.dailyAdjustmentKcal, 0);
    expect(result.finalGoalKcal, 1926.3);
    expect(result.wasClampedToMinimum, isFalse);
  });

  test('calculates female BMR and applies calorie deficit for weight loss', () {
    const profile = CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.female,
      weightKg: 65,
      heightCm: 170,
      ageYears: 28,
      activityLevel: 1.55,
      goalMode: CalorieGoalMode.lose,
      goalSpeedKgPerWeek: 0.5,
    );

    final result = CalorieGoalCalculator.calculate(profile);

    expect(result.bmrKcal, 1411.5);
    expect(result.tdeeKcal, closeTo(2187.825, 0.000001));
    expect(result.expectedActivityKcal, closeTo(776.325, 0.000001));
    expect(result.dailyAdjustmentKcal, 500);
    expect(result.finalGoalKcal, closeTo(1687.825, 0.000001));
    expect(result.wasClampedToMinimum, isFalse);
  });

  test(
    'maintenance calories rise with each higher standard activity level',
    () {
      final results = <double>[
        for (final activityLevel in <double>[1.2, 1.375, 1.55, 1.725, 1.9])
          CalorieGoalCalculator.calculate(
            CalorieCalculatorProfile(
              sex: CalorieCalculatorSex.male,
              weightKg: 84,
              heightCm: 173,
              ageYears: 31,
              activityLevel: activityLevel,
              goalMode: CalorieGoalMode.maintain,
              goalSpeedKgPerWeek: 0,
            ),
          ).finalGoalKcal,
      ];

      for (var index = 1; index < results.length; index += 1) {
        expect(results[index], greaterThan(results[index - 1]));
      }

      expect(results.first, 2125.5);
      expect(results.last, 3365.375);
    },
  );

  test('adds calorie surplus for weight gain', () {
    const profile = CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.male,
      weightKg: 75,
      heightCm: 178,
      ageYears: 33,
      activityLevel: 1.55,
      goalMode: CalorieGoalMode.gain,
      goalSpeedKgPerWeek: 0.25,
    );

    final result = CalorieGoalCalculator.calculate(profile);

    expect(result.dailyAdjustmentKcal, 250);
    expect(result.expectedActivityKcal, 936.375);
    expect(result.finalGoalKcal, 2888.875);
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
