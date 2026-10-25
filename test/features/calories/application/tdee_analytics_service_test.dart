import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/daily_tdee_series.dart';
import 'package:yamt/features/calories/application/tdee_analytics_service.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/quick_calorie_entry.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';

void main() {
  group('TdeeAnalyticsService', () {
    final today = DateTime(2025, 3, 10);

    test('multiple cycles form one continuous earliest-to-latest window', () {
      final window = TdeeAnalyticsService.resolveDateWindowForCycles(
        cycles: [
          TdeeAnalyticsGoalCycle(
            id: 'early',
            startDate: DateTime(2025),
            endDate: DateTime(2025, 1, 14),
          ),
          TdeeAnalyticsGoalCycle(
            id: 'late',
            startDate: DateTime(2025, 2),
            endDate: DateTime(2025, 2, 20),
          ),
        ],
        today: today,
      );

      expect(window.start, DateTime(2025));
      expect(window.end, DateTime(2025, 2, 20));
    });

    test('buildPoints keeps scale weight and adds trend weight', () {
      final weights = WeightTrendCalculator.fromDailyWeights({
        DateTime(2025, 3): 80,
        DateTime(2025, 3, 3): 82,
      });

      final points = TdeeAnalyticsService.buildPoints(
        startDate: DateTime(2025, 3),
        endDate: DateTime(2025, 3, 4),
        settings: CalorieGoalSettings.single(
          dailyKcalGoal: 2000,
          calculatorProfile: null,
          effectiveDate: DateTime(2025),
        ),
        tdeeByDay: const {},
        weights: weights,
      );

      expect(points.map((p) => p.scaleWeightKg), [80, null, 82, null]);
      expect(points[1].trendWeightKg, closeTo(80.1, 0.0001));
      expect(points[2].trendWeightKg, closeTo(80.29, 0.0001));
      expect(points[3].trendWeightKg, isNull);
    });

    test('estimateDailyTdee counts a pause day as a day without intake', () {
      final start = DateTime(2025, 3);
      final days = [
        for (var day = 0; day < 20; day++) addLocalDays(start, day),
      ];
      final pauseDay = days[15];
      final settings = CalorieGoalSettings.single(
        dailyKcalGoal: 2500,
        calculatorProfile: null,
        effectiveDate: DateTime(2025),
      ).setPauseDay(day: pauseDay, isPause: true);
      final entriesByDay = {
        for (final day in days)
          localDayKey(day): [
            buildQuickCalorieEntry(
              id: localDayKey(day),
              userId: 'user-1',
              name: 'Essen',
              mealType: MealType.lunch,
              loggedAt: day,
              now: day,
              // The pause day's binge must not count.
              kcal: day == pauseDay ? 9000 : 2500,
            ),
          ],
      };

      final estimates = DailyTdeeSeries.estimate(
        startDate: start,
        endDate: days.last,
        today: addLocalDays(days.last, 1),
        settings: settings,
        entriesByDay: entriesByDay,
        weights: WeightTrendCalculator.fromDailyWeights({
          for (final day in days) day: 80,
        }),
      );

      expect(estimates, hasLength(20));
      expect(estimates[localDayKey(days.last)]!.tdeeKcal, closeTo(2500, 1));
    });

    test('estimateDailyTdee keeps the value of yesterday for today', () {
      final start = DateTime(2025, 3);
      final today = addLocalDays(start, 3);

      final estimates = DailyTdeeSeries.estimate(
        startDate: start,
        endDate: today,
        today: today,
        settings: CalorieGoalSettings.single(
          dailyKcalGoal: 2500,
          calculatorProfile: null,
          effectiveDate: DateTime(2025),
        ),
        entriesByDay: {
          for (var day = 0; day <= 3; day++)
            localDayKey(addLocalDays(start, day)): [
              buildQuickCalorieEntry(
                id: '$day',
                userId: 'user-1',
                name: 'Essen',
                mealType: MealType.lunch,
                loggedAt: addLocalDays(start, day),
                now: addLocalDays(start, day),
                // Today's diary holds only breakfast so far.
                kcal: day == 3 ? 400 : 3000,
              ),
            ],
        },
        weights: WeightTrendCalculator.fromDailyWeights({start: 80}),
      );

      final yesterday = estimates[localDayKey(addLocalDays(start, 2))];
      final todayEstimate = estimates[localDayKey(today)];
      expect(todayEstimate?.tdeeKcal, yesterday?.tdeeKcal);
      expect(todayEstimate, isNotNull);
      expect(todayEstimate?.measuredTdeeKcal, isNull);
    });
  });
}
