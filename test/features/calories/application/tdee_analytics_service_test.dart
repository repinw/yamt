import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/tdee_analytics_service.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_time_range.dart';

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

    test('buildSummary calculates averages and deltas accurately', () {
      final points = [
        TdeeAnalyticsPoint(
          day: DateTime(2025, 3),
          learnedBaseTdeeKcal: 2400,
          scaleWeightKg: 80,
        ),
        TdeeAnalyticsPoint(
          day: DateTime(2025, 3, 2),
          learnedBaseTdeeKcal: 2420,
          scaleWeightKg: 79.8,
        ),
        TdeeAnalyticsPoint(
          day: DateTime(2025, 3, 3),
          learnedBaseTdeeKcal: 2440,
          scaleWeightKg: 79.5,
        ),
        TdeeAnalyticsPoint(
          day: DateTime(2025, 3, 4),
          learnedBaseTdeeKcal: 2450,
          scaleWeightKg: 79.2,
        ),
      ];

      final summary = TdeeAnalyticsService.buildSummary(points);

      expect(summary.averageTdeeKcal, closeTo(2427.5, 0.1));
      expect(summary.tdeeDifferenceKcal, 50.0);
      expect(summary.threeDayDeltaKcal, 50.0);
      expect(summary.currentWeightKg, 79.2);
      expect(summary.weightChangeKg, closeTo(-0.8, 0.001));
    });
  });
}
