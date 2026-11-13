import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/health/application/weight_series_provider.dart';
import 'package:yamt/features/health/domain/recent_weight_trend.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/domain/progress_weight.dart';
import 'package:yamt/features/progress/domain/progress_weight_rate.dart';

part 'progress_weight_provider.g.dart';

/// Weight trend of the period of [scope] with its average rate, the goal
/// starts, and the forecast for the goal weight.
@riverpod
Future<ProgressWeight> progressWeight(Ref ref, ProgressScope scope) async {
  final today = normalizeLocalDay(ref.watch(clockProvider)());
  final settings = await ref.watch(calorieGoalControllerProvider.future);
  final period = ProgressPeriod.of(
    settings: settings,
    scope: scope,
    today: today,
  );
  final chartStart = period.chartStart;
  final series = await ref.watch(weightSeriesProvider.future);
  return ProgressWeight.fromTrend(
    trend: RecentWeightTrend.fromSeries(
      series,
      today: period.end,
      dayCount: localDaysBetween(chartStart, period.end) + 1,
    ),
    rate: ProgressWeightRate.of(series, start: period.start, end: period.end),
    goalStarts: [
      for (final start in period.goalStarts)
        if (start.day.isAfter(chartStart)) start,
    ],
    // A past goal gets no forecast.
    profile: scope is ProgressPastGoalScope ? null : settings.calculatorProfile,
    today: today,
  );
}
