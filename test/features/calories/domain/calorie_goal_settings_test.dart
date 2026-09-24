import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_lifecycle.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';

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
      activityTrackingStartDate: DateTime(2026, 2, 26, 14),
    );

    final decoded = CalorieGoalSettings.fromJson(settings.toJson());

    expect(decoded.dailyKcalGoal, 2300);
    expect(decoded.calorieMathVersion, currentCalorieMathVersion);
    expect(decoded.calculatorProfile?.sex, CalorieCalculatorSex.female);
    expect(decoded.calculatorProfile?.goalMode, CalorieGoalMode.lose);
    expect(decoded.updatedAt, DateTime(2026, 2, 25, 11));
    expect(decoded.goalHistory, hasLength(1));
    expect(decoded.goalHistory.single.effectiveDate, DateTime(2026, 2, 25));
    expect(decoded.goalHistory.single.changedAt, DateTime(2026, 2, 25, 11));
    expect(decoded.activityTrackingStartDate, DateTime(2026, 2, 26));
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

  test('weekly snapshot json round trip preserves learned tdee values', () {
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
            'measured_tdee_kcal': 2450,
            'calculated_tdee_kcal': 2450,
            'base_goal_kcal': 2100,
            'low_confidence': false,
          },
        },
      ],
      'skipped_intake_day_keys': const <Object>[],
    });
    final snapshot = decoded.goalHistory.single.weeklyCheckInSnapshot;

    expect(snapshot, isNotNull);
    expect(snapshot?.measuredTdeeKcal, 2450);
    expect(snapshot?.calculatedTdeeKcal, 2450);
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

  test(
    'spontaneous training day adds offset when training weekdays is empty',
    () {
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: DateTime(2026, 2, 24, 6),
            dailyKcalGoal: 2000,
            calculatorProfile: null,
          )
          .copyWith(
            trainingWeekdays: const <int>[],
            trainingDayKcalOffset: 250,
          );

      final day = DateTime(2026, 2, 24); // Tuesday
      expect(settings.goalKcalForDay(day), 2000);

      final toggled = settings.toggleTrainingDay(day);
      expect(toggled.isTrainingDay(day), isTrue);
      expect(toggled.goalKcalForDay(day), 2250);
    },
  );

  test('spontaneous training day falls back to default 200 kcal offset '
      'if offset is zero', () {
    final settings = const CalorieGoalSettings.empty()
        .applyGoalChange(
          changedAt: DateTime(2026, 2, 24, 6),
          dailyKcalGoal: 2000,
          calculatorProfile: null,
        )
        .copyWith(trainingWeekdays: const <int>[], trainingDayKcalOffset: 0);

    final day = DateTime(2026, 2, 24);
    expect(settings.goalKcalForDay(day), 2000);

    final toggled = settings.toggleTrainingDay(day);
    expect(toggled.isTrainingDay(day), isTrue);
    expect(toggled.goalKcalForDay(day), 2200);
  });

  test('training day cycling distributes offset across rest days when '
      'weekdays configured', () {
    // 3 training days: Mo (1), We (3), Fr (5). 4 rest days.
    // Base: 2000, Offset: 200.
    // Training day: 2000 + 200 = 2200.
    // Rest day: 2000 - (3 * 200 / 4) = 2000 - 150 = 1850.
    final settings = const CalorieGoalSettings.empty()
        .applyGoalChange(
          changedAt: DateTime(2026, 2, 23, 6), // Monday
          dailyKcalGoal: 2000,
          calculatorProfile: null,
        )
        .copyWith(
          trainingWeekdays: const <int>[
            DateTime.monday,
            DateTime.wednesday,
            DateTime.friday,
          ],
          trainingDayKcalOffset: 200,
        );

    final monday = DateTime(2026, 2, 23); // Monday
    final tuesday = DateTime(2026, 2, 24); // Tuesday

    expect(settings.isTrainingDay(monday), isTrue);
    expect(settings.goalKcalForDay(monday), 2200);

    expect(settings.isTrainingDay(tuesday), isFalse);
    expect(settings.goalKcalForDay(tuesday), 1850);
  });

  test('goal completion and ending keep the original history entry', () {
    final profile = const CalorieCalculatorProfile.defaults().copyWith(
      goalMode: CalorieGoalMode.lose,
      targetWeightKg: 75,
    );
    final initial = CalorieGoalSettings.single(
      dailyKcalGoal: 2000,
      calculatorProfile: profile,
      effectiveDate: DateTime(2026, 6),
    );

    final completed = initial
        .markActiveGoalReached(DateTime(2026, 6, 4, 12), weightKg: 75)
        .markGoalReachedPromptHandled(DateTime(2026, 6, 4, 12, 30))
        .markActiveGoalEnded(DateTime(2026, 6, 4, 13), weightKg: 74.8);

    expect(completed.goalHistory.single.reachedAt, DateTime(2026, 6, 4));
    expect(completed.goalHistory.single.endedAt, DateTime(2026, 6, 4));
    expect(completed.goalHistory.single.reachedWeightKg, 75);
    expect(completed.goalHistory.single.endedWeightKg, 74.8);
    expect(completed.goalHistory.single.reachedPromptHandledAt, isNotNull);

    final decoded = CalorieGoalSettings.fromJson(completed.toJson());
    expect(decoded.goalHistory.single.reachedAt, DateTime(2026, 6, 4));
    expect(decoded.goalHistory.single.endedAt, DateTime(2026, 6, 4));
    expect(decoded.goalHistory.single.reachedWeightKg, 75);
    expect(decoded.goalHistory.single.endedWeightKg, 74.8);
    expect(decoded.goalHistory.single.reachedPromptHandledAt, isNotNull);
  });

  test('marking a reached goal twice leaves the settings untouched', () {
    final initial = CalorieGoalSettings.single(
      dailyKcalGoal: 2000,
      calculatorProfile: const CalorieCalculatorProfile.defaults(),
      effectiveDate: DateTime(2026, 6),
    );
    final reached = initial.markActiveGoalReached(
      DateTime(2026, 6, 4),
      weightKg: 75,
    );

    expect(
      identical(
        reached.markActiveGoalReached(DateTime(2026, 6, 5), weightKg: 74),
        reached,
      ),
      isTrue,
    );
    expect(
      reached.markGoalReachedPromptHandled(DateTime(2026, 6, 5)),
      isNot(reached),
    );
  });

  test('learning anchor survives a later goal-cycle change', () {
    final first = const CalorieGoalSettings.empty().applyGoalChange(
      changedAt: DateTime(2026, 6),
      dailyKcalGoal: 2000,
      calculatorProfile: const CalorieCalculatorProfile.defaults(),
    );
    final changed = first.applyGoalChange(
      changedAt: DateTime(2026, 6, 4),
      dailyKcalGoal: 2400,
      calculatorProfile: const CalorieCalculatorProfile.defaults(),
    );

    expect(
      changed.learningAnchorEntryForDay(DateTime(2026, 6, 10))?.effectiveDate,
      DateTime(2026, 6),
    );
    expect(
      changed.cycleAnchorEntryForDay(DateTime(2026, 6, 10))?.effectiveDate,
      DateTime(2026, 6, 4),
    );
  });

  test(
    'preserveSameDayGoalEntries keeps the archived goal of the same day',
    () {
      final first = CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: const CalorieCalculatorProfile.defaults(),
        effectiveDate: DateTime(2026, 6),
      );

      final replaced = first.applyGoalChange(
        changedAt: DateTime(2026, 6, 1, 12),
        dailyKcalGoal: 2400,
        calculatorProfile: const CalorieCalculatorProfile.defaults(),
      );
      final archived = first.applyGoalChange(
        changedAt: DateTime(2026, 6, 1, 12),
        dailyKcalGoal: 2400,
        calculatorProfile: const CalorieCalculatorProfile.defaults(),
        preserveSameDayGoalEntries: true,
      );

      expect(replaced.goalHistory, hasLength(1));
      expect(archived.goalHistory, hasLength(2));
    },
  );
}
