import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/application/recent_weight_trend_provider.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/domain/progress_weight.dart';

part 'progress_weight_provider.g.dart';

/// Weight trend of the period of [scope] with the goal starts and the
/// forecast for the goal weight.
@riverpod
Future<ProgressWeight> progressWeight(Ref ref, ProgressScope scope) async {
  final today = normalizeDiaryDay(ref.watch(clockProvider)());
  final settings = await ref.watch(calorieGoalControllerProvider.future);
  final period = ProgressPeriod.of(
    settings: settings,
    scope: scope,
    today: today,
  );
  final chartStart = period.chartStart(today);
  final dayCount = today.difference(chartStart).inDays + 1;
  final trend = await ref.watch(
    recentWeightTrendProvider(dayCount: dayCount).future,
  );
  return ProgressWeight.fromTrend(
    trend: trend,
    goalStarts: [
      for (final start in period.goalStarts)
        if (start.day.isAfter(chartStart)) start,
    ],
    profile: settings.calculatorProfile,
    today: today,
  );
}
