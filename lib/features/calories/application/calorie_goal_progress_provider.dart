import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/tdee_analytics_provider.dart';
import 'package:yamt/features/calories/domain/calorie_goal_progress.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_time_range.dart';
import 'package:yamt/features/calories/domain/tdee_cycle_resolver.dart';

part 'calorie_goal_progress_provider.g.dart';

/// Weight and learned TDEE of the goal that is active on [endDate], from its
/// start up to [endDate]. `null` without a goal on [endDate].
@riverpod
Future<CalorieGoalProgress?> calorieGoalProgress(
  Ref ref,
  DateTime endDate,
) async {
  final end = normalizeDiaryDay(endDate);
  final settings = await ref.watch(calorieGoalControllerProvider.future);
  if (!ref.mounted) {
    throw StateError('Calorie goal progress was disposed.');
  }
  final anchor = settings.cycleAnchorEntryForDay(end);
  if (anchor == null) {
    return null;
  }
  final startDate = normalizeDiaryDay(anchor.effectiveCountingStartDate);
  // The goal of [endDate], which a newer goal may have replaced since.
  final cycle = TdeeCycleResolver.resolveGoalCycles(settings)
      .where(
        (cycle) =>
            !cycle.isAllGoals &&
            normalizeDiaryDay(cycle.startDate) == startDate,
      )
      .firstOrNull;
  if (cycle == null) {
    return null;
  }
  final analytics = await ref.watch(
    tdeeAnalyticsProvider(
      TdeeAnalyticsQuery(
        cycleIds: {cycle.id},
        timeRange: TdeeAnalyticsTimeRange.all,
      ),
    ).future,
  );

  return CalorieGoalProgress(
    startDate: startDate,
    startWeightKg: cycle.startWeightKg,
    targetWeightKg: cycle.targetWeightKg,
    weights: [
      for (final point in analytics.points)
        if (!point.day.isBefore(startDate) && !point.day.isAfter(end))
          (
            day: point.day,
            scaleWeightKg: point.scaleWeightKg,
            trendWeightKg: point.trendWeightKg,
          ),
    ],
    tdeePoints: calorieGoalTdeePoints(
      settings: settings,
      startDate: startDate,
      endDate: end,
    ),
  );
}
