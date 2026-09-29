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
    expect(period.chartStart(_today), DateTime(2026, 9, 23));
  });

  test('covers all goals from the first start', () {
    final period = ProgressPeriod.of(
      settings: _settings,
      scope: ProgressScope.all,
      today: _today,
    );

    expect(period.start, DateTime(2026, 6));
    expect(period.goalStarts.map((start) => start.number), [1, 2]);
    expect(period.chartStart(_today), DateTime(2026, 6));
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
}
