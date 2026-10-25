import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_tdee_offsets.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/domain/daily_tdee_estimator.dart';

void main() {
  final goalStart = DateTime(2026, 4, 8);
  final today = addLocalDays(goalStart, 16);

  CalorieGoalSettings settingsWithCheckIns() {
    var settings = CalorieGoalSettings.single(
      dailyKcalGoal: 2400,
      calculatorProfile: null,
      effectiveDate: goalStart,
    );
    for (final week in [0, 1]) {
      final windowStart = addLocalDays(goalStart, 7 * week);
      settings = settings.applyGoalChange(
        changedAt: addLocalDays(windowStart, 7),
        dailyKcalGoal: 2400,
        calculatorProfile: null,
        source: CalorieGoalSource.weeklyCheckIn,
        weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
          windowStartDate: windowStart,
          windowEndDate: addLocalDays(windowStart, 6),
          trendWeightChangePerDay: 0,
          calculatedTdeeKcal: 2500,
          lowConfidence: false,
        ),
      );
    }
    return settings;
  }

  Map<String, DailyTdeeEstimate> tdee(Map<int, double> kcalByOffset) => {
    for (final MapEntry(:key, :value) in kcalByOffset.entries)
      localDayKey(addLocalDays(goalStart, key)): DailyTdeeEstimate(
        tdeeKcal: value,
        measuredTdeeKcal: null,
        trendKgPerDay: 0,
        isHolding: false,
      ),
  };

  test('moves each day by the TDEE known when it starts', () {
    final offsets = goalTdeeOffsets(
      settings: settingsWithCheckIns(),
      startDate: addLocalDays(goalStart, 14),
      today: today,
      tdeeByDay: tdee({13: 2500, 14: 2520, 15: 2540, 16: 2550}),
    );

    expect(offsets, {
      for (final (day, kcal) in [
        (14, 0.0),
        (15, 20.0),
        (16, 40.0),
        (17, 40.0),
        (18, 40.0),
        (19, 40.0),
        (20, 40.0),
      ])
        localDayKey(addLocalDays(goalStart, day)): kcal,
    });
  });

  test('keeps the offsets of finished weeks', () {
    final settings = settingsWithCheckIns();
    final moved = settings.withGoalOffsets(
      goalTdeeOffsets(
        settings: settings,
        startDate: goalStart,
        today: today,
        tdeeByDay: tdee({
          6: 2480,
          7: 2510,
          13: 2500,
          14: 2520,
          15: 2540,
          16: 2550,
        }),
      ),
    );

    // The first week rests on a goal without check-in or profile.
    expect(
      moved.goalKcalForDay(addLocalDays(goalStart, 3)),
      settings.goalKcalForDay(addLocalDays(goalStart, 3)),
    );
    // The second week keeps what it showed: the TDEE of the day before
    // minus the 2500 of its check-in.
    expect(moved.goalKcalForDay(addLocalDays(goalStart, 7)), 2380);
    expect(moved.goalKcalForDay(addLocalDays(goalStart, 8)), 2410);
    expect(moved.goalKcalForDay(addLocalDays(goalStart, 15)), 2420);
  });

  test('starts from the calculator TDEE before the first check-in', () {
    const profile = CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.female,
      weightKg: 70,
      heightCm: 170,
      ageYears: 30,
      activityLevel: 1.375,
      goalMode: CalorieGoalMode.maintain,
      goalSpeedKgPerWeek: 0,
    );
    final calculatorTdee = CalorieGoalCalculator.calculate(profile).tdeeKcal;

    final offsets = goalTdeeOffsets(
      startDate: goalStart,
      settings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: profile,
        effectiveDate: goalStart,
      ),
      today: addLocalDays(goalStart, 2),
      tdeeByDay: tdee({1: calculatorTdee + 30}),
    );

    expect(offsets[localDayKey(addLocalDays(goalStart, 2))], closeTo(30, 1e-9));
    expect(offsets, hasLength(5));
  });

  test('leaves a goal without check-in or profile alone', () {
    final offsets = goalTdeeOffsets(
      startDate: goalStart,
      settings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: null,
        effectiveDate: goalStart,
      ),
      today: addLocalDays(goalStart, 2),
      tdeeByDay: tdee({2: 2600}),
    );

    expect(offsets, isEmpty);
  });

  test('rests a goal set later on the TDEE of the day before', () {
    const profile = CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.female,
      weightKg: 70,
      heightCm: 170,
      ageYears: 30,
      activityLevel: 1.375,
      goalMode: CalorieGoalMode.lose,
      goalSpeedKgPerWeek: 0.5,
    );
    final settings =
        CalorieGoalSettings.single(
          dailyKcalGoal: 2000,
          calculatorProfile: profile,
          effectiveDate: goalStart,
        ).applyGoalChange(
          changedAt: addLocalDays(goalStart, 3),
          dailyKcalGoal: 2100,
          calculatorProfile: profile,
          source: CalorieGoalSource.calculator,
        );

    final offsets = goalTdeeOffsets(
      settings: settings,
      startDate: goalStart,
      today: addLocalDays(goalStart, 5),
      tdeeByDay: tdee({2: 2600, 3: 2620, 4: 2650}),
    );

    expect(offsets[localDayKey(addLocalDays(goalStart, 5))], 50);
  });

  test('never moves a goal under the minimum budget', () {
    final offsets = goalTdeeOffsets(
      settings: settingsWithCheckIns(),
      startDate: addLocalDays(goalStart, 14),
      today: today,
      tdeeByDay: tdee({15: 1000}),
    );

    // 2400 + (1000 - 2500) would be 900; the floor keeps 1200.
    expect(offsets[localDayKey(today)], -1200);
  });
}
