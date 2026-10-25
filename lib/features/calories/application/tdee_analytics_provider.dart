import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/application/daily_tdee_series.dart';
import 'package:yamt/features/calories/application/tdee_analytics_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/calories/domain/tdee_cycle_resolver.dart';
import 'package:yamt/features/health/application/weight_series_provider.dart';

part 'tdee_analytics_provider.g.dart';

/// Immutable query parameter for TDEE analytics.
@immutable
class TdeeAnalyticsQuery {
  /// Creates an analytics query.
  const new({required this.cycleIds});

  /// Selected cycle IDs. `all` expands to every individual cycle.
  final Set<String> cycleIds;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TdeeAnalyticsQuery && setEquals(other.cycleIds, cycleIds);
  }

  @override
  int get hashCode => Object.hashAllUnordered(cycleIds);
}

/// Provides fully resolved TDEE analytics state for charts and insights.
@riverpod
Future<TdeeAnalyticsState> tdeeAnalytics(
  Ref ref,
  TdeeAnalyticsQuery query,
) async {
  final keepAliveLink = ref.keepAlive();
  try {
    // Recompute when diary entries change.
    ref.watch(calorieOverviewRevisionProvider);
    final settingsFuture = ref.watch(calorieGoalControllerProvider.future);
    final logRepo = ref.watch(calorieLogRepositoryProvider);
    final weightsFuture = ref.watch(weightSeriesProvider.future);

    final settings = await settingsFuture;
    final weights = await weightsFuture;
    if (!ref.mounted) {
      throw StateError('TdeeAnalytics provider was disposed.');
    }

    final availableCycles = TdeeCycleResolver.resolveGoalCycles(settings);
    final individualCycles = availableCycles
        .where((cycle) => !cycle.isAllGoals)
        .toList(growable: false);
    final selectedCycles = query.cycleIds.contains('all')
        ? individualCycles
        : individualCycles
              .where((cycle) => query.cycleIds.contains(cycle.id))
              .toList(growable: false);
    final effectiveSelectedCycles = selectedCycles.isEmpty
        ? <TdeeAnalyticsGoalCycle>[individualCycles.first]
        : selectedCycles;

    final now = ref.watch(clockProvider)();
    final window = TdeeAnalyticsService.resolveDateWindowForCycles(
      cycles: effectiveSelectedCycles,
      today: now,
    );

    // The daily TDEE runs from the first goal on, so every range shows the
    // same values for a day.
    final estimateStart =
        DailyTdeeSeries.startDay(settings, window.end) ?? window.start;
    final loadStart = estimateStart.isBefore(window.start)
        ? estimateStart
        : window.start;

    final entries = await logRepo.readEntriesInRange(
      startInclusive: loadStart,
      endExclusive: nextLocalDay(window.end),
    );
    if (!ref.mounted) {
      throw StateError('TdeeAnalytics provider was disposed.');
    }

    final entriesByDay = entries.groupByDiaryDayKey();
    final points = TdeeAnalyticsService.buildPoints(
      startDate: window.start,
      endDate: window.end,
      settings: settings,
      tdeeByDay: DailyTdeeSeries.estimate(
        startDate: estimateStart,
        endDate: window.end,
        today: normalizeLocalDay(now),
        settings: settings,
        entriesByDay: entriesByDay,
        weights: weights,
      ),
      weights: weights,
    );

    return TdeeAnalyticsState(points: points);
  } finally {
    keepAliveLink.close();
  }
}
