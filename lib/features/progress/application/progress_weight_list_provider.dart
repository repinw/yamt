import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/application/manual_health_weight_entries_controller.dart';
import 'package:yamt/features/health/application/recent_weight_trend_provider.dart';
import 'package:yamt/features/health/application/weight_series_provider.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/domain/progress_weight_list.dart';

part 'progress_weight_list_provider.g.dart';

/// Every weighing of [range] with the trend, the goal starts, and the goal
/// weight.
@riverpod
Future<ProgressWeightList> progressWeightList(
  Ref ref,
  ProgressWeightRange range,
) async {
  final today = normalizeDiaryDay(ref.watch(clockProvider)());
  final settings = await ref.watch(calorieGoalControllerProvider.future);
  final allGoals = ProgressPeriod.of(
    settings: settings,
    scope: ProgressScope.all,
    today: today,
  );
  final period = switch (range) {
    ProgressWeightRange.goal => ProgressPeriod.of(
      settings: settings,
      scope: ProgressScope.goal,
      today: today,
    ),
    ProgressWeightRange.fourWeeks => ProgressPeriod(
      start: addDiaryDays(today, -progressFallbackDays),
      end: today,
      goalStarts: allGoals.goalStarts,
    ),
    ProgressWeightRange.all => allGoals,
  };
  final chartStart = period.chartStart;
  // A goal that starts later still lists the weights of the last days.
  final startsLater = period.start.isAfter(today);
  final (trend, manualEntries, healthSamples) = await (
    ref.watch(
      recentWeightTrendProvider(
        dayCount: diaryDaysBetween(chartStart, today) + 1,
      ).future,
    ),
    ref.watch(manualHealthWeightEntriesControllerProvider.future),
    ref.watch(healthWeightSamplesProvider.future),
  ).wait;
  return ProgressWeightList.fromSources(
    start: startsLater ? chartStart : period.start,
    startsAtGoal:
        range == ProgressWeightRange.goal &&
        period.goalStarts.isNotEmpty &&
        !startsLater,
    trend: trend,
    goalStarts: [
      for (final start in period.goalStarts)
        if (start.day.isAfter(chartStart)) start,
    ],
    settings: settings,
    manualEntries: manualEntries,
    healthSamples: healthSamples,
    today: today,
  );
}
