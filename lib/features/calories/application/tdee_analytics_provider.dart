import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/daily_learned_tdee_models.dart';
import 'package:yamt/features/calories/application/daily_learned_tdee_resolver.dart';
import 'package:yamt/features/calories/application/tdee_analytics_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_carryover_history.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_time_range.dart';
import 'package:yamt/features/calories/domain/tdee_cycle_resolver.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/daily_learned_tdee_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/presentation/controllers/health_connection_controller.dart';
import 'package:yamt/features/health/presentation/controllers/manual_health_weight_entries_controller.dart';

part 'tdee_analytics_provider.g.dart';

/// Immutable query parameter for TDEE analytics.
@immutable
class TdeeAnalyticsQuery {
  /// Creates an analytics query.
  const TdeeAnalyticsQuery({
    required this.cycleId,
    required this.timeRange,
  });

  /// Selected cycle ID or 'all'.
  final String cycleId;

  /// Selected time filter.
  final TdeeAnalyticsTimeRange timeRange;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TdeeAnalyticsQuery &&
        other.cycleId == cycleId &&
        other.timeRange == timeRange;
  }

  @override
  int get hashCode => Object.hash(cycleId, timeRange);
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
    final selectedCycle = availableCycles.firstWhere(
      (c) => c.id == query.cycleId,
      orElse: () => availableCycles.first,
    );

    final now = DateTime.now();
    final window = TdeeAnalyticsService.resolveDateWindow(
      cycle: selectedCycle,
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

    final healthSamples =
        healthStatus.accessState == HealthDataAccessState.ready
            ? await healthWeightService.loadWeightSamples(
                startInclusive: window.start,
                endExclusive: nextDiaryDay(window.end),
              )
            : const <HealthWeightSample>[];
    if (!ref.mounted) {
      throw StateError('TdeeAnalytics provider was disposed.');
    }

    final weightsByDay = _mergeWeights(
      healthSamples: healthSamples,
      manualEntries: manualEntries,
    );

    final points = TdeeAnalyticsService.buildPoints(
      startDate: window.start,
      endDate: window.end,
      settings: settings,
      learnedTdeeByDay: learnedTdeeMap,
      entriesByDay: entries.groupByDiaryDayKey(),
      weightsByDay: weightsByDay,
    );

    final summary = TdeeAnalyticsService.buildSummary(points);
    final anticipation = TdeeAnalyticsService.buildAnticipation(
      cycle: selectedCycle,
      points: points,
      today: now,
    );

    return TdeeAnalyticsState(
      selectedCycle: selectedCycle,
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

Map<String, double> _mergeWeights({
  required List<HealthWeightSample> healthSamples,
  required List<ManualHealthWeightEntry> manualEntries,
}) {
  final result = <String, double>{};
  final representative = DailyLearnedTdeeResolver.representativeWeightByDay(
    healthSamples,
  );
  result.addAll(representative);

  final manual = DailyLearnedTdeeResolver.manualWeightByDay(manualEntries);
  result.addAll(manual);

  return result;
}
