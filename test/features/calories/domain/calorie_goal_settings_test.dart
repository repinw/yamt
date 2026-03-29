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
    final settings = CalorieGoalSettings.single(
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
      effectiveDate: DateTime(2026, 2, 25, 11),
    );

    final decoded = CalorieGoalSettings.fromJson(settings.toJson());

    expect(decoded.dailyKcalGoal, 2300);
    expect(decoded.calculatorProfile?.sex, CalorieCalculatorSex.female);
    expect(decoded.calculatorProfile?.goalMode, CalorieGoalMode.lose);
    expect(decoded.updatedAt, DateTime(2026, 2, 25, 11));
    expect(decoded.goalHistory, hasLength(1));
    expect(decoded.goalHistory.single.effectiveDate, DateTime(2026, 2, 25));
  });

  test('resolves goal history by day and resets balance on latest change', () {
    final settings = const CalorieGoalSettings.empty()
        .applyGoalChange(
          changedAt: DateTime(2026, 2, 20, 8),
          dailyKcalGoal: 2400,
          calculatorProfile: null,
        )
        .applyGoalChange(
          changedAt: DateTime(2026, 2, 24, 9),
          dailyKcalGoal: 1800,
          calculatorProfile: null,
        );

    expect(settings.goalKcalForDay(DateTime(2026, 2, 23)), 2400);
    expect(settings.goalKcalForDay(DateTime(2026, 2, 24)), 1800);
    expect(
      settings.balanceStartForWindow(<DateTime>[
        DateTime(2026, 2, 21),
        DateTime(2026, 2, 22),
        DateTime(2026, 2, 23),
        DateTime(2026, 2, 24),
        DateTime(2026, 2, 25),
      ]),
      DateTime(2026, 2, 24),
    );
  });
}
