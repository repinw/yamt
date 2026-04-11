import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';

void main() {
  test('empty settings have no goal', () {
    const settings = CalorieGoalSettings.empty();

    expect(settings.hasGoal, isFalse);
    expect(settings.dailyKcalGoal, isNull);
    expect(settings.updatedAt, isNull);
    expect(
      settings.normalizedEatingWindowStartMinuteOfDay,
      defaultEatingWindowStartMinuteOfDay,
    );
    expect(
      settings.normalizedEatingWindowEndMinuteOfDay,
      defaultEatingWindowEndMinuteOfDay,
    );
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
    expect(decoded.goalHistory.single.changedAt, DateTime(2026, 2, 25, 11));
    expect(decoded.normalizedEatingWindowStartMinuteOfDay, 360);
    expect(decoded.normalizedEatingWindowEndMinuteOfDay, 1320);
  });

  test('json conversion preserves a custom eating window', () {
    final settings = CalorieGoalSettings.single(
      dailyKcalGoal: 2300,
      calculatorProfile: null,
      effectiveDate: DateTime(2026, 2, 25, 11),
      eatingWindowStartMinuteOfDay: 8 * 60,
      eatingWindowEndMinuteOfDay: (20 * 60) + 30,
    );

    final decoded = CalorieGoalSettings.fromJson(settings.toJson());

    expect(decoded.normalizedEatingWindowStartMinuteOfDay, 8 * 60);
    expect(decoded.normalizedEatingWindowEndMinuteOfDay, (20 * 60) + 30);
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

  test(
    'replaceFutureHistory drops later goal changes from the same timeline',
    () {
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
          )
          .applyGoalChange(
            changedAt: DateTime(2026, 2, 22, 14),
            dailyKcalGoal: 2100,
            calculatorProfile: null,
            replaceFutureHistory: true,
          );

      expect(settings.dailyKcalGoal, 2100);
      expect(settings.goalHistory, hasLength(2));
      expect(settings.goalKcalForDay(DateTime(2026, 2, 21)), 2400);
      expect(settings.goalKcalForDay(DateTime(2026, 2, 23)), 2100);
      expect(settings.goalKcalForDay(DateTime(2026, 2, 25)), 2100);
    },
  );

  test('withoutLatestGoalEntry removes the active goal entry', () {
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
        )
        .withoutLatestGoalEntry();

    expect(settings.dailyKcalGoal, 2400);
    expect(settings.goalHistory, hasLength(1));
    expect(settings.goalKcalForDay(DateTime(2026, 2, 23)), 2400);
    expect(settings.goalKcalForDay(DateTime(2026, 2, 25)), 2400);
  });

  test('future goal start keeps earlier days goal-free', () {
    final settings = const CalorieGoalSettings.empty().applyGoalChange(
      changedAt: DateTime(2026, 2, 24, 6),
      dailyKcalGoal: 2100,
      calculatorProfile: null,
    );

    expect(settings.goalKcalForDay(DateTime(2026, 2, 23)), 0);
    expect(settings.goalKcalForDay(DateTime(2026, 2, 24)), 2100);
    expect(
      settings.balanceStartForWindow(<DateTime>[
        DateTime(2026, 2, 17),
        DateTime(2026, 2, 18),
        DateTime(2026, 2, 19),
        DateTime(2026, 2, 20),
        DateTime(2026, 2, 21),
        DateTime(2026, 2, 22),
        DateTime(2026, 2, 23),
      ]),
      DateTime(2026, 2, 24),
    );
  });

  test('applyEatingWindowChange keeps goal history unchanged', () {
    final settings =
        CalorieGoalSettings.single(
          dailyKcalGoal: 2000,
          calculatorProfile: null,
          effectiveDate: DateTime(2026, 2, 20, 8),
        ).applyEatingWindowChange(
          changedAt: DateTime(2026, 2, 21, 9),
          startMinuteOfDay: (7 * 60) + 30,
          endMinuteOfDay: 21 * 60,
        );

    expect(settings.goalHistory, hasLength(1));
    expect(settings.normalizedEatingWindowStartMinuteOfDay, (7 * 60) + 30);
    expect(settings.normalizedEatingWindowEndMinuteOfDay, 21 * 60);
  });
}
