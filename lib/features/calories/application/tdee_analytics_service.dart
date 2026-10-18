import 'package:yamt/features/calories/application/daily_tdee_series.dart';
import 'package:yamt/features/calories/domain/calorie_carryover_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/daily_tdee_estimator.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';

/// Business service that builds TDEE analytics data.
abstract final class TdeeAnalyticsService {
  /// Resolves one continuous window spanning all selected goal cycles.
  static ({DateTime start, DateTime end}) resolveDateWindowForCycles({
    required List<TdeeAnalyticsGoalCycle> cycles,
    required DateTime today,
  }) {
    final normalizedToday = normalizeDiaryDay(today);
    if (cycles.isEmpty) {
      return (start: normalizedToday, end: normalizedToday);
    }
    var start = cycles.first.startDate;
    var end = cycles.first.endDate ?? normalizedToday;
    for (final cycle in cycles.skip(1)) {
      if (cycle.startDate.isBefore(start)) {
        start = cycle.startDate;
      }
      final candidateEnd = cycle.endDate ?? normalizedToday;
      if (candidateEnd.isAfter(end)) {
        end = candidateEnd;
      }
    }
    return (start: normalizeDiaryDay(start), end: normalizeDiaryDay(end));
  }

  /// Builds daily analytics points from loaded inputs.
  static List<TdeeAnalyticsPoint> buildPoints({
    required DateTime startDate,
    required DateTime endDate,
    required CalorieGoalSettings settings,
    required Map<String, DailyTdeeEstimate> tdeeByDay,
    required DailyWeightSeries weights,
  }) {
    final days = buildCalorieCarryoverDateRange(
      startInclusive: startDate,
      endExclusive: nextDiaryDay(endDate),
    );

    final points = <TdeeAnalyticsPoint>[];
    for (final day in days) {
      final key = diaryDayKey(day);
      final estimate = tdeeByDay[key];

      final baseTdee =
          estimate?.tdeeKcal ?? DailyTdeeSeries.startTdeeKcal(settings, day);
      final measuredTdee = estimate?.measuredTdeeKcal;

      points.add(
        TdeeAnalyticsPoint(
          day: day,
          learnedBaseTdeeKcal: baseTdee > 0 ? baseTdee : null,
          totalTdeeKcal: measuredTdee != null && measuredTdee > 0
              ? measuredTdee
              : null,
          scaleWeightKg: weights.rawByDay[key],
          trendWeightKg: weights.trendByDay[key],
          isHolding: estimate == null || estimate.isHolding,
        ),
      );
    }
    return List<TdeeAnalyticsPoint>.unmodifiable(points);
  }
}
