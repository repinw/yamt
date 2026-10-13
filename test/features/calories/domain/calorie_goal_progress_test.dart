import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_goal_progress.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

void main() {
  final goalStart = DateTime(2026, 4, 8);

  CalorieGoalSettings settingsWithCheckIns() {
    var settings = CalorieGoalSettings.single(
      dailyKcalGoal: 2400,
      calculatorProfile: null,
      effectiveDate: goalStart,
    );
    for (final week in [0, 1]) {
      final windowStart = addDiaryDays(goalStart, 7 * week);
      settings = settings.applyGoalChange(
        changedAt: addDiaryDays(windowStart, 7),
        dailyKcalGoal: 2400,
        calculatorProfile: null,
        source: CalorieGoalSource.weeklyCheckIn,
        weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
          windowStartDate: windowStart,
          windowEndDate: addDiaryDays(windowStart, 6),
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
      dailyTdeeKcalByDay: {diaryDayKey(addDiaryDays(goalStart, 6)): 2610},
      startDate: goalStart,
      endDate: addDiaryDays(goalStart, 20),
    );

    expect(points.map((point) => point.tdeeKcal), [2610, 2500]);
    expect(points.first.runEndDate, addDiaryDays(goalStart, 6));
  });
}
