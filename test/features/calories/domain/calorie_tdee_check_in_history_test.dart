import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/domain/calorie_tdee_check_in_history.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';

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

final _goalStart = DateTime(2026, 8, 3);

CalorieGoalHistoryEntry _calculatorGoal() {
  return CalorieGoalHistoryEntry(
    dailyKcalGoal: 2000,
    calculatorProfile: _profile,
    effectiveDate: _goalStart,
    changedAt: _goalStart,
    source: CalorieGoalSource.calculator,
  );
}

CalorieGoalHistoryEntry _checkIn({required int week, bool isRejected = false}) {
  final windowStart = addLocalDays(_goalStart, 7 * (week - 1));
  final due = addLocalDays(windowStart, 7);
  return CalorieGoalHistoryEntry(
    dailyKcalGoal: 2000,
    calculatorProfile: null,
    effectiveDate: due,
    changedAt: due,
    source: CalorieGoalSource.weeklyCheckIn,
    weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: windowStart,
      windowEndDate: addLocalDays(due, -1),
      trendWeightChangePerDay: -0.07,
      lowConfidence: false,
      calculatedTdeeKcal: 2480,
      isRejected: isRejected,
    ),
  );
}

CalorieGoalSettings _settings(
  List<CalorieGoalHistoryEntry> history, {
  PendingCalorieGoalWeeklyCheckIn? pending,
}) {
  return CalorieGoalSettings(
    dailyKcalGoal: 2000,
    calculatorProfile: _profile,
    updatedAt: _goalStart,
    goalHistory: history,
    pendingWeeklyCheckIn: pending,
    skippedIntakeDayKeys: const <String>[],
    calorieMathVersion: currentCalorieMathVersion,
  );
}

void main() {
  test('lists the day of each confirmed check-in', () {
    final goals = CalorieTdeeHistory.perGoal(
      _settings([
        _calculatorGoal(),
        _checkIn(week: 1),
        _checkIn(week: 2, isRejected: true),
      ]),
    );

    expect(goals.single.startDay, _goalStart);
    expect(goals.single.checkInDays, [
      DateTime(2026, 8, 10),
      DateTime(2026, 8, 17),
    ]);
  });

  test('leaves out the check-in that still waits for a decision', () {
    final goals = CalorieTdeeHistory.perGoal(
      _settings(
        [_calculatorGoal(), _checkIn(week: 1), _checkIn(week: 2)],
        pending: PendingCalorieGoalWeeklyCheckIn(
          windowStartDate: DateTime(2026, 8, 10),
          windowEndDate: DateTime(2026, 8, 16),
          dueDate: DateTime(2026, 8, 17),
        ),
      ),
    );

    expect(goals.single.checkInDays, [DateTime(2026, 8, 10)]);
  });

  test('splits the history per goal with the start day of each', () {
    final newGoal = DateTime(2026, 9);
    final goals = CalorieTdeeHistory.perGoal(
      _settings([
        _calculatorGoal(),
        _checkIn(week: 1),
        CalorieGoalHistoryEntry(
          dailyKcalGoal: 2100,
          calculatorProfile: _profile,
          effectiveDate: newGoal,
          changedAt: newGoal,
          source: CalorieGoalSource.calculator,
        ),
      ]),
    );

    expect(goals.map((goal) => goal.startDay), [_goalStart, newGoal]);
    expect(goals.first.checkInDays, [DateTime(2026, 8, 10)]);
    expect(goals.last.checkInDays, isEmpty);
  });
}
