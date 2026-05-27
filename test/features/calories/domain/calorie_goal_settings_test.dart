import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';

void main() {
  test('empty settings have no goal', () {
    const settings = CalorieGoalSettings.empty();

    expect(settings.hasGoal, isFalse);
    expect(settings.dailyKcalGoal, isNull);
    expect(settings.updatedAt, isNull);
    expect(settings.calorieMathVersion, currentCalorieMathVersion);
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
      expectedActivityKcal: 420,
      activityTrackingStartDate: DateTime(2026, 2, 26, 14),
    );

    final decoded = CalorieGoalSettings.fromJson(settings.toJson());

    expect(decoded.dailyKcalGoal, 2300);
    expect(decoded.calorieMathVersion, currentCalorieMathVersion);
    expect(decoded.expectedActivityKcal, 420);
    expect(decoded.calculatorProfile?.sex, CalorieCalculatorSex.female);
    expect(decoded.calculatorProfile?.goalMode, CalorieGoalMode.lose);
    expect(decoded.updatedAt, DateTime(2026, 2, 25, 11));
    expect(decoded.goalHistory, hasLength(1));
    expect(decoded.goalHistory.single.effectiveDate, DateTime(2026, 2, 25));
    expect(decoded.goalHistory.single.changedAt, DateTime(2026, 2, 25, 11));
    expect(decoded.goalHistory.single.expectedActivityKcal, 420);
    expect(decoded.expectedActivityKcalForDay(DateTime(2026, 2, 26)), 420);
    expect(decoded.activityTrackingStartDate, DateTime(2026, 2, 26));
    expect(
      decoded.isActivityTrackingActiveForDay(DateTime(2026, 2, 25)),
      false,
    );
    expect(decoded.isActivityTrackingActiveForDay(DateTime(2026, 2, 26)), true);
  });

  test('json without math version decodes as current clean shape', () {
    final decoded = CalorieGoalSettings.fromJson({
      'daily_kcal_goal': 2100,
      'updated_at': DateTime(2026, 2, 25, 11),
      'goal_history': const <Object>[],
      'skipped_intake_day_keys': const <Object>[],
    });

    expect(decoded.calorieMathVersion, currentCalorieMathVersion);
  });

  test('legacy weekly snapshot json preserves learned tdee fallback', () {
    final decoded = CalorieGoalSettings.fromJson({
      'daily_kcal_goal': 2100,
      'updated_at': '2026-03-01T08:00:00.000',
      'goal_history': [
        {
          'daily_kcal_goal': 2100,
          'effective_date': '2026-02-23T00:00:00.000',
          'changed_at': '2026-03-01T08:00:00.000',
          'source': 'weekly_checkin',
          'weekly_check_in_snapshot': {
            'window_start_date': '2026-02-16T00:00:00.000',
            'window_end_date': '2026-02-22T00:00:00.000',
            'trend_weight_change_per_day': -0.1,
            'calculated_true_tdee_kcal': 2450,
            'average_active_kcal': 350,
            'new_goal_kcal': 2100,
            'low_confidence': false,
          },
        },
      ],
      'skipped_intake_day_keys': const <Object>[],
    });
    final snapshot = decoded.goalHistory.single.weeklyCheckInSnapshot;

    expect(snapshot, isNotNull);
    expect(snapshot?.measuredTotalTdeeKcal, 2450);
    expect(snapshot?.measuredBaseTdeeKcal, 2450);
    expect(snapshot?.calculatedBaseTdeeKcal, 2450);
    expect(snapshot?.averageCreditedActivityKcal, 350);
    expect(snapshot?.baseGoalKcal, 2100);
  });

  test('detects only future-start practice days', () {
    final today = DateTime(2026, 4, 24);
    final tomorrow = DateTime(2026, 4, 25);
    const emptySettings = CalorieGoalSettings.empty();
    final futureStartSettings = CalorieGoalSettings.single(
      dailyKcalGoal: 2100,
      calculatorProfile: null,
      effectiveDate: today,
      countingStartDate: tomorrow,
      source: CalorieGoalSource.calculator,
    );
    final futureEffectiveStartSettings = CalorieGoalSettings.single(
      dailyKcalGoal: 2100,
      calculatorProfile: null,
      effectiveDate: tomorrow,
      countingStartDate: tomorrow,
      source: CalorieGoalSource.calculator,
    );
    final partialStartSettings = CalorieGoalSettings.single(
      dailyKcalGoal: 2100,
      calculatorProfile: null,
      effectiveDate: DateTime(2026, 4, 24, 18),
      source: CalorieGoalSource.calculator,
    );
    final weeklyCheckInSettings = CalorieGoalSettings.single(
      dailyKcalGoal: 2100,
      calculatorProfile: null,
      effectiveDate: DateTime(2026, 4, 24, 18),
      source: CalorieGoalSource.weeklyCheckIn,
    );
    final noGoalSettings = CalorieGoalSettings.single(
      dailyKcalGoal: null,
      calculatorProfile: null,
      effectiveDate: today,
      countingStartDate: tomorrow,
      source: CalorieGoalSource.calculator,
    );

    expect(emptySettings.isGoalPracticeDay(today), isFalse);
    expect(noGoalSettings.isGoalPracticeDay(today), isFalse);
    expect(futureStartSettings.isGoalPracticeDay(today), isTrue);
    expect(futureStartSettings.isGoalPracticeDay(tomorrow), isFalse);
    expect(futureEffectiveStartSettings.isGoalPracticeDay(today), isTrue);
    expect(futureEffectiveStartSettings.isGoalPracticeDay(tomorrow), isFalse);
    expect(partialStartSettings.isGoalPracticeDay(today), isFalse);
    expect(partialStartSettings.isGoalPracticeDay(tomorrow), isFalse);
    expect(weeklyCheckInSettings.isGoalPracticeDay(today), isFalse);
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
          expectedActivityKcal: 300,
        )
        .applyGoalChange(
          changedAt: DateTime(2026, 2, 24, 9),
          dailyKcalGoal: 1800,
          calculatorProfile: null,
          expectedActivityKcal: 450,
        )
        .withoutLatestGoalEntry();

    expect(settings.dailyKcalGoal, 2400);
    expect(settings.expectedActivityKcal, 300);
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
}
