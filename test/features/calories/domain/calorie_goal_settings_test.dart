import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';

void main() {
  test('empty settings have no goal', () {
    const settings = CalorieGoalSettings.empty();

    expect(settings.hasGoal, isFalse);
    expect(settings.dailyKcalGoal, isNull);
    expect(settings.updatedAt, isNull);
  });

  test('json conversion preserves goal values', () {
    final settings = CalorieGoalSettings(
      dailyKcalGoal: 2300,
      calculatorProfile: const CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.female,
        weightKg: 65,
        heightCm: 170,
        ageYears: 28,
        activityLevel: 1.5,
        goalMode: CalorieGoalMode.lose,
        goalSpeedKgPerWeek: 0.5,
      ),
      updatedAt: DateTime(2026, 2, 25, 11),
    );

    final decoded = CalorieGoalSettings.fromJson(settings.toJson());

    expect(decoded.dailyKcalGoal, 2300);
    expect(decoded.calculatorProfile?.sex, CalorieCalculatorSex.female);
    expect(decoded.calculatorProfile?.goalMode, CalorieGoalMode.lose);
    expect(decoded.updatedAt, DateTime(2026, 2, 25, 11));
  });
}
