import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';

const _profile = CalorieCalculatorProfile(
  sex: CalorieCalculatorSex.male,
  weightKg: 84,
  heightCm: 180,
  ageYears: 35,
  activityLevel: 1.4,
  goalMode: CalorieGoalMode.lose,
  goalSpeedKgPerWeek: 0.5,
  targetWeightKg: 78,
);

CalorieGoalHistoryEntry _goal(DateTime start) {
  return CalorieGoalHistoryEntry(
    dailyKcalGoal: 2000,
    calculatorProfile: _profile,
    effectiveDate: start,
    changedAt: start,
    source: CalorieGoalSource.calculator,
  );
}

final _today = DateTime(2026, 9, 29);

final _settings = CalorieGoalSettings(
  dailyKcalGoal: 2000,
  calculatorProfile: _profile,
  updatedAt: _today,
  goalHistory: [_goal(DateTime(2026, 6)), _goal(DateTime(2026, 9, 28))],
  pendingWeeklyCheckIn: null,
  skippedIntakeDayKeys: const <String>[],
  calorieMathVersion: currentCalorieMathVersion,
);

void main() {
  test('covers the current goal from its start', () {
    final period = ProgressPeriod.of(
      settings: _settings,
      scope: ProgressScope.goal,
      today: _today,
    );

    expect(period.start, DateTime(2026, 9, 28));
    expect(period.goalStarts, [(number: 2, day: DateTime(2026, 9, 28))]);
    // A goal that just started still gets a week of chart.
    expect(period.chartStart, DateTime(2026, 9, 23));
  });

  test('covers all goals from the first start', () {
    final period = ProgressPeriod.of(
      settings: _settings,
      scope: ProgressScope.all,
      today: _today,
    );

    expect(period.start, DateTime(2026, 6));
    expect(period.goalStarts.map((start) => start.number), [1, 2]);
    expect(period.chartStart, DateTime(2026, 6));
  });

  test('falls back to four weeks without a goal', () {
    final period = ProgressPeriod.of(
      settings: const CalorieGoalSettings.empty(),
      scope: ProgressScope.all,
      today: _today,
    );

    expect(period.start, DateTime(2026, 9));
    expect(period.goalStarts, isEmpty);
  });

  group('past goal scope', () {
    test('runs from its start to the day before the next goal', () {
      final period = ProgressPeriod.of(
        settings: _settings,
        scope: const ProgressPastGoalScope(1),
        today: _today,
      );

      expect(period.start, DateTime(2026, 6));
      expect(period.end, DateTime(2026, 9, 27));
      expect(period.goalStarts, [(number: 1, day: DateTime(2026, 6))]);
    });

    test('ends on the day it ended, before the next goal counts', () {
      final settings = CalorieGoalSettings(
        dailyKcalGoal: 2000,
        calculatorProfile: _profile,
        updatedAt: _today,
        goalHistory: [
          CalorieGoalHistoryEntry(
            dailyKcalGoal: 2000,
            calculatorProfile: _profile,
            effectiveDate: DateTime(2026, 6),
            changedAt: DateTime(2026, 6),
            source: CalorieGoalSource.calculator,
            endedAt: DateTime(2026, 9, 10, 18),
          ),
          CalorieGoalHistoryEntry(
            dailyKcalGoal: 2000,
            calculatorProfile: _profile,
            effectiveDate: DateTime(2026, 9, 10),
            changedAt: DateTime(2026, 9, 10),
            countingStartDate: DateTime(2026, 9, 14),
            source: CalorieGoalSource.calculator,
          ),
        ],
        pendingWeeklyCheckIn: null,
        skippedIntakeDayKeys: const <String>[],
        calorieMathVersion: currentCalorieMathVersion,
      );

      final period = ProgressPeriod.of(
        settings: settings,
        scope: const ProgressPastGoalScope(1),
        today: _today,
      );

      expect(period.start, DateTime(2026, 6));
      expect(period.end, DateTime(2026, 9, 10));
      expect(period.goalStarts, [(number: 1, day: DateTime(2026, 6))]);
    });

    test('ends today at the latest', () {
      final period = ProgressPeriod.of(
        settings: _settings,
        scope: const ProgressPastGoalScope(1),
        today: DateTime(2026, 9, 10),
      );

      expect(period.end, DateTime(2026, 9, 10));
    });

    test('lasts at least its first day', () {
      final settings = CalorieGoalSettings(
        dailyKcalGoal: 2000,
        calculatorProfile: _profile,
        updatedAt: _today,
        goalHistory: [_goal(DateTime(2026, 6)), _goal(DateTime(2026, 6))],
        pendingWeeklyCheckIn: null,
        skippedIntakeDayKeys: const <String>[],
        calorieMathVersion: currentCalorieMathVersion,
      );
      final period = ProgressPeriod.of(
        settings: settings,
        scope: const ProgressPastGoalScope(1),
        today: _today,
      );

      expect(period.end.isBefore(period.start), isFalse);
    });

    test('falls back to the current goal for an unknown number', () {
      for (final number in [0, 2, 9]) {
        final period = ProgressPeriod.of(
          settings: _settings,
          scope: ProgressPastGoalScope(number),
          today: _today,
        );

        expect(period.start, DateTime(2026, 9, 28), reason: '$number');
        expect(period.end, _today, reason: '$number');
      }
    });
  });

  test('the current and the all scope end today', () {
    for (final scope in [ProgressScope.goal, ProgressScope.all]) {
      expect(
        ProgressPeriod.of(settings: _settings, scope: scope, today: _today).end,
        _today,
      );
    }
  });

  group('ProgressScope', () {
    test('compares past goals by number', () {
      expect(const ProgressPastGoalScope(1), const ProgressPastGoalScope(1));
      expect(
        const ProgressPastGoalScope(1).hashCode,
        const ProgressPastGoalScope(1).hashCode,
      );
      expect(
        const ProgressPastGoalScope(1),
        isNot(const ProgressPastGoalScope(2)),
      );
      expect(const ProgressPastGoalScope(1), isNot(ProgressScope.goal));
    });

    test('finds the scope by its name', () {
      for (final scope in [
        ProgressScope.goal,
        ProgressScope.all,
        const ProgressPastGoalScope(3),
      ]) {
        expect(ProgressScope.byName(scope.name), scope);
      }
    });

    test('falls back to all goals for an unknown name', () {
      for (final name in [null, '', 'x', 'goal-', 'goal-x']) {
        expect(ProgressScope.byName(name), ProgressScope.all, reason: '$name');
      }
    });
  });
}
