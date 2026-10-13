import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/daily_tdee_estimator.dart';

const _estimate = DailyTdeeEstimate(
  tdeeKcal: 2500,
  measuredTdeeKcal: 2520,
  trendKgPerDay: -0.05,
  isHolding: false,
);

void main() {
  test('takes the daily TDEE at the window end', () {
    final result = CalorieWeeklyCheckInCalculator.fromDailyTdee(
      atWindowEnd: _estimate,
      previousTdeeKcal: 2480,
      averageIntakeKcal: 2100,
      previousGoalKcal: 2000,
      goalMode: CalorieGoalMode.lose,
      goalSpeedKgPerWeek: 0.5,
    );

    expect(result.calculatedTdeeKcal, 2500);
    // The window average plus the trend energy: 2100 + 0.05 x 7700.
    expect(result.measuredTdeeKcal, closeTo(2485, 0.01));
    expect(result.previousTdeeKcal, 2480);
    expect(result.trendWeightChangePerDay, -0.05);
    expect(result.averageIntakeKcal, 2100);
    // 2500 - 0.5 kg x 7700 / 7.
    expect(result.newGoalKcal, closeTo(1950, 0.01));
  });

  test('keeps the TDEE as the goal while maintaining', () {
    final result = CalorieWeeklyCheckInCalculator.fromDailyTdee(
      atWindowEnd: _estimate,
      previousTdeeKcal: 2500,
      averageIntakeKcal: 2500,
      previousGoalKcal: 2450,
      goalMode: CalorieGoalMode.maintain,
      goalSpeedKgPerWeek: 0.5,
    );

    expect(result.newGoalKcal, 2500);
  });

  test('moves the goal at most 200 kcal per check-in', () {
    final result = CalorieWeeklyCheckInCalculator.fromDailyTdee(
      atWindowEnd: _estimate,
      previousTdeeKcal: 2500,
      averageIntakeKcal: 2500,
      previousGoalKcal: 1500,
      goalMode: CalorieGoalMode.maintain,
      goalSpeedKgPerWeek: 0,
    );

    expect(result.newGoalKcal, 1700);
  });

  test('never sets a dynamic goal under the minimum', () {
    final result = CalorieWeeklyCheckInCalculator.fromDailyTdee(
      atWindowEnd: const DailyTdeeEstimate(
        tdeeKcal: 1300,
        measuredTdeeKcal: null,
        trendKgPerDay: 0,
        isHolding: false,
      ),
      previousTdeeKcal: 1300,
      averageIntakeKcal: 1300,
      previousGoalKcal: 1000,
      goalMode: CalorieGoalMode.lose,
      goalSpeedKgPerWeek: 0.5,
    );

    expect(result.measuredTdeeKcal, 1300);
    expect(result.dynamicGoalTodayKcal, minimumResolvedDailyCalorieGoalKcal);
  });

  test('calculates manual rerun goal from learned TDEE', () {
    expect(
      CalorieWeeklyCheckInCalculator.calculateGoalFromLearnedTdee(
        learnedTdeeKcal: 2500,
        goalSpeedKgPerWeek: 0.5,
        isLosing: true,
        isGaining: false,
      ),
      closeTo(1950, 0.01),
    );
    expect(
      CalorieWeeklyCheckInCalculator.calculateGoalFromLearnedTdee(
        learnedTdeeKcal: 2500,
        goalSpeedKgPerWeek: 0.25,
        isLosing: false,
        isGaining: true,
      ),
      closeTo(2775, 0.01),
    );
    expect(
      CalorieWeeklyCheckInCalculator.calculateGoalFromLearnedTdee(
        learnedTdeeKcal: 2500,
        goalSpeedKgPerWeek: 0,
        isLosing: false,
        isGaining: false,
      ),
      2500,
    );
  });
}
