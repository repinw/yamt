import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/tdee_analytics_service.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_time_range.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';

void main() {
  group('TdeeAnalyticsService', () {
    final today = DateTime(2025, 3, 10);
    final cycleStart = DateTime(2025);

    test('resolveDateWindow clamps correctly for 7 days', () {
      final cycle = TdeeAnalyticsGoalCycle(
        id: '1',
        title: 'Active',
        startDate: cycleStart,
      );

      final window = TdeeAnalyticsService.resolveDateWindow(
        cycle: cycle,
        timeRange: TdeeAnalyticsTimeRange.days7,
        today: today,
      );

      expect(window.end, today);
      expect(window.start, DateTime(2025, 3, 4));
    });

    test('resolveDateWindow handles all time for cycle', () {
      final cycle = TdeeAnalyticsGoalCycle(
        id: '1',
        title: 'Active',
        startDate: cycleStart,
      );

      final window = TdeeAnalyticsService.resolveDateWindow(
        cycle: cycle,
        timeRange: TdeeAnalyticsTimeRange.all,
        today: today,
      );

      expect(window.start, cycleStart);
      expect(window.end, today);
    });

    test('multiple cycles form one continuous earliest-to-latest window', () {
      final window = TdeeAnalyticsService.resolveDateWindowForCycles(
        cycles: [
          TdeeAnalyticsGoalCycle(
            id: 'early',
            title: 'Early',
            startDate: DateTime(2025),
            endDate: DateTime(2025, 1, 14),
          ),
          TdeeAnalyticsGoalCycle(
            id: 'late',
            title: 'Late',
            startDate: DateTime(2025, 2),
            endDate: DateTime(2025, 2, 20),
          ),
        ],
        timeRange: TdeeAnalyticsTimeRange.all,
        today: today,
      );

      expect(window.start, DateTime(2025));
      expect(window.end, DateTime(2025, 2, 20));
    });

    test('buildSummary uses trend weight for weight numbers', () {
      final weights = WeightTrendCalculator.fromDailyWeights({
        DateTime(2025, 3): 80,
        DateTime(2025, 3, 2): 79.8,
        DateTime(2025, 3, 3): 79.5,
        DateTime(2025, 3, 4): 79.2,
      });
      final points = [
        for (final (index, kcal) in [2400.0, 2420.0, 2440.0, 2450.0].indexed)
          TdeeAnalyticsPoint(
            day: DateTime(2025, 3, index + 1),
            learnedBaseTdeeKcal: kcal,
            scaleWeightKg:
                weights.rawByDay[diaryDayKey(DateTime(2025, 3, index + 1))],
            trendWeightKg: weights.trendFor(DateTime(2025, 3, index + 1)),
          ),
      ];

      final summary = TdeeAnalyticsService.buildSummary(
        points: points,
        weights: weights,
      );

      expect(summary.averageTdeeKcal, closeTo(2427.5, 0.1));
      expect(summary.tdeeDifferenceKcal, 50.0);
      expect(summary.threeDayDeltaKcal, 50.0);
      // Trend: 80 → 79.98 → 79.932 → 79.8588.
      expect(summary.currentWeightKg, closeTo(79.8588, 0.0001));
      expect(summary.weightChangeKg, closeTo(-0.1412, 0.0001));
      expect(summary.weeklyRateKg, lessThan(0));
    });

    test('buildSummary has no weight change for a single weigh-in', () {
      final weights = WeightTrendCalculator.fromDailyWeights({
        DateTime(2025, 3): 80,
      });
      final summary = TdeeAnalyticsService.buildSummary(
        points: [
          TdeeAnalyticsPoint(
            day: DateTime(2025, 3),
            scaleWeightKg: 80,
            trendWeightKg: 80,
          ),
        ],
        weights: weights,
      );

      expect(summary.currentWeightKg, 80);
      expect(summary.weightChangeKg, isNull);
      expect(summary.weeklyRateKg, isNull);
    });

    test('weekly rate ignores trend days before the window', () {
      // Rising before the window, falling inside it.
      final weights = WeightTrendCalculator.fromDailyWeights({
        for (var day = 0; day < 30; day++)
          addDiaryDays(DateTime(2025, 2), day): 78 + 0.1 * day,
        for (var day = 1; day <= 5; day++)
          addDiaryDays(DateTime(2025, 3, 3), day): 80.9 - 0.3 * day,
      });
      final points = [
        for (var day = 0; day <= 5; day++)
          TdeeAnalyticsPoint(
            day: addDiaryDays(DateTime(2025, 3, 3), day),
            trendWeightKg: weights.trendFor(
              addDiaryDays(DateTime(2025, 3, 3), day),
            ),
          ),
      ];

      final summary = TdeeAnalyticsService.buildSummary(
        points: points,
        weights: weights,
      );

      expect(summary.weightChangeKg, lessThan(0));
      expect(summary.weeklyRateKg, lessThan(0));
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
        learnedTdeeByDay: const {},
        entriesByDay: const {},
        weights: weights,
      );

      expect(points.map((p) => p.scaleWeightKg), [80, null, 82, null]);
      expect(points[1].trendWeightKg, closeTo(80.1, 0.0001));
      expect(points[2].trendWeightKg, closeTo(80.29, 0.0001));
      expect(points[3].trendWeightKg, isNull);
    });

    test('anticipation follows the trend and ignores one spike', () {
      final start = DateTime(2025, 1, 20);
      final weights = WeightTrendCalculator.fromDailyWeights({
        for (var day = 0; day < 40; day++)
          addDiaryDays(start, day): 90 - 0.1 * day,
        // Water spike on the last weigh-in.
        addDiaryDays(start, 40): 88,
      });
      final cycle = TdeeAnalyticsGoalCycle(
        id: 'lose',
        title: 'Lose',
        startDate: start,
        goalMode: CalorieGoalMode.lose,
        targetWeightKg: 80,
      );

      final projection = TdeeAnalyticsService.buildAnticipation(
        cycle: cycle,
        weights: weights,
        windowStart: start,
        windowEnd: addDiaryDays(start, 40),
      );

      expect(projection, isNotNull);
      expect(projection!.isMovingAway, isFalse);
      expect(projection.trendSpeedKgPerWeek, closeTo(-0.7, 0.1));
      // The 2 kg spike moves the trend by only about 0.1 kg.
      final trendBeforeSpike = weights.trendFor(addDiaryDays(start, 39))!;
      expect(projection.currentWeightKg - trendBeforeSpike, closeTo(0.1, 0.05));
    });
  });
}
