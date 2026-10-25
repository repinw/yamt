import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calorie_goal_progress.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';

void main() {
  final goalStart = DateTime(2026, 4, 8);

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

  test('shows the daily TDEE at each run end over the saved value', () {
    final points = calorieGoalTdeePoints(
      settings: settingsWithCheckIns(),
      dailyTdeeKcalByDay: {localDayKey(addLocalDays(goalStart, 6)): 2610},
      startDate: goalStart,
      endDate: addLocalDays(goalStart, 20),
    );

    expect(points.map((point) => point.tdeeKcal), [2610, 2500]);
    expect(points.first.runEndDate, addLocalDays(goalStart, 6));
  });

  test('the weight of a day is its trend, else its weigh-in', () {
    final progress = CalorieGoalProgress(
      startDate: goalStart,
      startWeightKg: null,
      targetWeightKg: null,
      weights: [
        (day: goalStart, scaleWeightKg: 80.4, trendWeightKg: 80.1),
        (
          day: addLocalDays(goalStart, 1),
          scaleWeightKg: 79.9,
          trendWeightKg: null,
        ),
      ],
      tdeePoints: const [],
    );

    expect(progress.weightKgOn(goalStart), 80.1);
    expect(progress.weightKgOn(addLocalDays(goalStart, 1)), 79.9);
    expect(progress.weightKgOn(addLocalDays(goalStart, 2)), isNull);
  });
}
