import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/domain/progress_tdee.dart';

void main() {
  final start = DateTime(2026, 9, 7);
  final today = addDiaryDays(start, 9);

  ProgressTdee tdeeFor({required List<double> values}) {
    return ProgressTdee.fromPoints(
      settings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: null,
        effectiveDate: start,
      ),
      period: ProgressPeriod(
        start: start,
        end: today,
        goalStarts: [(number: 1, day: start)],
      ),
      points: [
        for (final (index, kcal) in values.indexed)
          TdeeAnalyticsPoint(
            day: addDiaryDays(start, index),
            learnedBaseTdeeKcal: kcal,
            totalTdeeKcal: kcal + 100,
          ),
      ],
      today: today,
    );
  }

  test('shows one day per chart day and today last', () {
    final tdee = tdeeFor(values: [for (var i = 0; i < 10; i++) 2400.0 + i]);

    expect(tdee.days.first.day, start);
    expect(tdee.days.last.day, today);
    expect(tdee.currentTdeeKcal, 2409);
    expect(tdee.days.last.measuredKcal, 2509);
  });

  test('changes count from the estimates before today', () {
    // Today (day 9) carries the estimate of day 8.
    final tdee = tdeeFor(
      values: [for (var i = 0; i < 9; i++) 2400.0 + i, 2408],
    );

    expect(tdee.runStartDay, addDiaryDays(start, 7));
    expect(tdee.nextCheckInDay, addDiaryDays(start, 14));
    expect(tdee.changeSinceYesterdayKcal, 1);
    // The running week started on day 7; day 6 ended the week before.
    expect(tdee.changeThisWeekKcal, 2);
  });

  test('has no values before the first goal', () {
    final tdee = ProgressTdee.fromPoints(
      settings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: null,
        effectiveDate: today,
      ),
      period: ProgressPeriod(
        start: today,
        end: today,
        goalStarts: [(number: 1, day: today)],
      ),
      points: [TdeeAnalyticsPoint(day: today, learnedBaseTdeeKcal: 2400)],
      today: today,
    );

    expect(tdee.days, hasLength(progressMinChartDays));
    expect(tdee.days.first.tdeeKcal, isNull);
    expect(tdee.currentTdeeKcal, 2400);
    expect(tdee.changeSinceYesterdayKcal, isNull);
  });
}
