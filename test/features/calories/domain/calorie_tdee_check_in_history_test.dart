import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
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

CalorieGoalHistoryEntry _checkIn({
  required int week,
  required double calculatedTdeeKcal,
  bool isRejected = false,
}) {
  final windowStart = _goalStart.add(Duration(days: 7 * (week - 1)));
  final due = windowStart.add(const Duration(days: 7));
  return CalorieGoalHistoryEntry(
    dailyKcalGoal: 2000,
    calculatorProfile: null,
    effectiveDate: due,
    changedAt: due,
    source: CalorieGoalSource.weeklyCheckIn,
    weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: windowStart,
      windowEndDate: due.subtract(const Duration(days: 1)),
      trendWeightChangePerDay: -0.07,
      lowConfidence: false,
      calculatedTdeeKcal: calculatedTdeeKcal,
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
  final startTdee = CalorieGoalCalculator.calculate(_profile).tdeeKcal;

  test('starts with the calculator TDEE and adds one value per check-in', () {
    final history = CalorieTdeeHistory.fromSettings(
      _settings([
        _calculatorGoal(),
        _checkIn(week: 1, calculatedTdeeKcal: 2480),
        _checkIn(week: 2, calculatedTdeeKcal: 2530),
      ]),
    );

    expect(history.startTdeeKcal, startTdee);
    expect(history.checkIns.map((checkIn) => checkIn.tdeeKcal), [2480, 2530]);
    expect(history.checkIns.first.day, DateTime(2026, 8, 10));
  });

  test('keeps the previous TDEE for a declined check-in', () {
    final history = CalorieTdeeHistory.fromSettings(
      _settings([
        _calculatorGoal(),
        _checkIn(week: 1, calculatedTdeeKcal: 2480),
        _checkIn(week: 2, calculatedTdeeKcal: 2600, isRejected: true),
      ]),
    );

    final declined = history.checkIns.last;
    expect(declined.isRejected, isTrue);
    expect(declined.tdeeKcal, 2480);
    expect(declined.calculatedTdeeKcal, 2600);
  });

  test('leaves out the check-in that still waits for a decision', () {
    final history = CalorieTdeeHistory.fromSettings(
      _settings(
        [
          _calculatorGoal(),
          _checkIn(week: 1, calculatedTdeeKcal: 2480),
          _checkIn(week: 2, calculatedTdeeKcal: 2530),
        ],
        pending: PendingCalorieGoalWeeklyCheckIn(
          windowStartDate: DateTime(2026, 8, 10),
          windowEndDate: DateTime(2026, 8, 16),
          dueDate: DateTime(2026, 8, 17),
        ),
      ),
    );

    expect(history.checkIns.map((checkIn) => checkIn.tdeeKcal), [2480]);
  });

  test('starts over with a new calculator goal', () {
    final newGoal = DateTime(2026, 9);
    final history = CalorieTdeeHistory.fromSettings(
      _settings([
        _calculatorGoal(),
        _checkIn(week: 1, calculatedTdeeKcal: 2480),
        CalorieGoalHistoryEntry(
          dailyKcalGoal: 2100,
          calculatorProfile: _profile,
          effectiveDate: newGoal,
          changedAt: newGoal,
          source: CalorieGoalSource.calculator,
        ),
      ]),
    );

    expect(history.checkIns, isEmpty);
    expect(history.startTdeeKcal, startTdee);
  });
}
