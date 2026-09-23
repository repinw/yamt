import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/daily_learned_tdee_models.dart';
import 'package:yamt/features/calories/application/tdee_analytics_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_carryover_history.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_time_range.dart';
import 'package:yamt/features/calories/domain/tdee_cycle_resolver.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/daily_learned_tdee_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';
import 'package:yamt/features/health/presentation/controllers/health_connection_controller.dart';
import 'package:yamt/features/health/presentation/controllers/manual_health_weight_entries_controller.dart';

part 'tdee_analytics_provider.g.dart';

/// Immutable query parameter for TDEE analytics.
@immutable
class TdeeAnalyticsQuery {
  /// Creates an analytics query.
  const new({required this.cycleIds, required this.timeRange});

  /// Selected cycle IDs. `all` expands to every individual cycle.
  final Set<String> cycleIds;

  /// Selected time filter.
  final TdeeAnalyticsTimeRange timeRange;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TdeeAnalyticsQuery &&
        setEquals(other.cycleIds, cycleIds) &&
        other.timeRange == timeRange;
  }

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(cycleIds), timeRange);
}

/// Provides fully resolved TDEE analytics state for charts and insights.
@riverpod
Future<TdeeAnalyticsState> tdeeAnalytics(
  Ref ref,
  TdeeAnalyticsQuery query,
) async {
  final keepAliveLink = ref.keepAlive();
  try {
    final settingsFuture = ref.watch(calorieGoalControllerProvider.future);
    final logRepo = ref.watch(calorieLogRepositoryProvider);
    final healthStatusFuture = ref.watch(
      healthConnectionControllerProvider.future,
    );
    final manualEntriesFuture = ref.watch(
      manualHealthWeightEntriesControllerProvider.future,
    );
    final healthWeightService = ref.watch(healthWeightServiceProvider);

    final settings = await settingsFuture;
    final healthStatus = await healthStatusFuture;
    final manualEntries = await manualEntriesFuture;
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
      timeRange: query.timeRange,
      today: now,
    );

    final dayRequests = [
      for (final day in buildCalorieCarryoverDateRange(
        startInclusive: window.start,
        endExclusive: nextDiaryDay(window.end),
      ))
        DailyLearnedTdeeGoalDayRequest(
          day: day,
          storedGoalKcal: settings.goalKcalForDay(day),
        ),
    ];

    final learnedTdeeMap = await ref.watch(
      dailyLearnedTdeeGoalsForDaysProvider(
        DailyLearnedTdeeGoalDaysRequest(today: now, days: dayRequests),
      ).future,
    );
    if (!ref.mounted) {
      throw StateError('TdeeAnalytics provider was disposed.');
    }

    final entries = await logRepo.readEntriesInRange(
      startInclusive: window.start,
      endExclusive: nextDiaryDay(window.end),
    );
    if (!ref.mounted) {
      throw StateError('TdeeAnalytics provider was disposed.');
    }

    // Load earlier weights too, so the trend weight is settled at the start.
    final healthSamples =
        healthStatus.accessState == HealthDataAccessState.ready
        ? await healthWeightService.loadWeightSamples(
            startInclusive: addDiaryDays(
              window.start,
              -WeightTrendCalculator.warmUpDays,
            ),
            endExclusive: nextDiaryDay(window.end),
          )
        : const <HealthWeightSample>[];
    if (!ref.mounted) {
      throw StateError('TdeeAnalytics provider was disposed.');
    }

    final weights = WeightTrendCalculator.fromSources(
      manualEntries: manualEntries,
      healthSamples: healthSamples,
    );

    final points = TdeeAnalyticsService.buildPoints(
      startDate: window.start,
      endDate: window.end,
      settings: settings,
      learnedTdeeByDay: learnedTdeeMap,
      entriesByDay: entries.groupByDiaryDayKey(),
      weights: weights,
    );

    final summary = TdeeAnalyticsService.buildSummary(
      points: points,
      weights: weights,
    );
    final activeSelected = effectiveSelectedCycles
        .where((cycle) => cycle.isActive)
        .firstOrNull;
    final anticipation = activeSelected == null
        ? null
        : TdeeAnalyticsService.buildAnticipation(
            cycle: activeSelected,
            weights: weights,
            windowEnd: window.end,
          );

    return TdeeAnalyticsState(
      selectedCycles: effectiveSelectedCycles,
      availableCycles: availableCycles,
      timeRange: query.timeRange,
      points: points,
      summary: summary,
      anticipation: anticipation,
    );
  } finally {
    keepAliveLink.close();
  }
}
