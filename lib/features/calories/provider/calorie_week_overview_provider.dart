import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_week_consumption_snapshot_provider.dart';
import 'package:yamt/features/calories/application/calorie_week_cycle_totals.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_log_loader.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_carryover_history.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_resolved_goal_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_visible_window_controller.dart';

part 'calorie_week_overview_provider.g.dart';

/// Calorie week overview.
@riverpod
Future<CalorieWeekOverview> calorieWeekOverview(Ref ref) async {
  final visibleWindowEnd = ref.watch(calorieVisibleWindowControllerProvider);
  return await ref.watch(
    calorieWeekOverviewForWindowProvider(visibleWindowEnd).future,
  );
}

/// Calorie week overview for window.
@riverpod
Future<CalorieWeekOverview> calorieWeekOverviewForWindow(
  Ref ref,
  DateTime visibleWindowEnd,
) async {
  final keepAliveLink = ref.keepAlive();
  try {
    final visibleDays = buildDiaryVisibleDays(anchorDay: visibleWindowEnd);
    final snapshotFuture = ref.watch(
      calorieWeekConsumptionSnapshotForWindowProvider(visibleWindowEnd).future,
    );
    final repository = ref.watch(calorieLogRepositoryProvider);
    final goalState = ref.watch(calorieGoalControllerProvider);
    final resolvedGoalsFuture = ref.watch(
      resolvedCalorieGoalsForDaysProvider(
        ResolvedCalorieGoalDaysRequest.fromDays(visibleDays),
      ).future,
    );

    final snapshot = await snapshotFuture;
    if (!ref.mounted) {
      throw StateError('Calorie week overview disposed.');
    }
    final settings =
        goalState.asData?.value ?? const CalorieGoalSettings.empty();
    final resolvedGoalsByDay = await resolvedGoalsFuture;
    if (!ref.mounted) {
      throw StateError('Calorie week overview disposed.');
    }
    final overviews = snapshot.days
        .asMap()
        .entries
        .map((entry) {
          final goal = resolvedGoalsByDay[diaryDayKey(entry.value.date)]!;
          return CalorieWeekDayOverview(
            date: entry.value.date,
            totalKcal: entry.value.totalKcal,
            goalKcal: goal.goalKcal,
            baseGoalKcal: goal.storedGoalKcal,
            entryCount: entry.value.entryCount,
            isPauseDay: settings.isPauseDay(entry.value.date),
          );
        })
        .toList(growable: false);
    final today = snapshot.days.last.date;
    final visibleWindowStart = snapshot.days.first.date;
    final firstEntryDate = await repository.readFirstEntryDate();
    if (!ref.mounted) {
      throw StateError('Calorie week overview disposed.');
    }
    final balanceStartDate = resolveCalorieBalanceCycleStartDate(
      settings: settings,
      day: today,
      fallbackStartDate: visibleWindowStart,
      firstEntryDate: firstEntryDate,
    );
    final carryoverStartDate = resolveCalorieCarryoverStartDate(
      settings: settings,
      day: today,
      balanceStartDate: balanceStartDate,
    );
    final historicalEntries = await readEntriesInRangeSafely(
      repository: repository,
      startInclusive: carryoverStartDate,
      endExclusive: visibleWindowStart,
    );
    final historicalEntriesByDay = historicalEntries.groupByDiaryDayKey();
    if (!ref.mounted) {
      throw StateError('Calorie week overview disposed.');
    }
    final historicalDays = buildCalorieCarryoverDateRange(
      startInclusive: carryoverStartDate,
      endExclusive: visibleWindowStart,
    );
    final historicalGoalKcals = historicalDays
        .map((day) => settings.goalKcalForDay(normalizeDiaryDay(day)))
        .toList(growable: false);
    final historicalCarryoverDays = buildCalorieCarryoverDays(
      days: historicalDays,
      goalKcals: historicalGoalKcals,
      entriesByDay: historicalEntriesByDay,
    );
    final adjustedOverviews = overviews
        .map(
          (overview) => CalorieWeekDayOverview(
            date: overview.date,
            totalKcal: overview.totalKcal,
            goalKcal: overview.goalKcal,
            baseGoalKcal: overview.baseGoalKcal,
            entryCount: overview.entryCount,
            isPauseDay: overview.isPauseDay,
          ),
        )
        .toList(growable: false);
    final cycleTotals = calculateCalorieWeekCycleTotals(
      cycleStartDate: carryoverStartDate,
      today: today,
      historicalCarryoverDays: historicalCarryoverDays,
      historicalDays: historicalDays,
      settings: settings,
      visibleOverviews: adjustedOverviews,
    );
    final hasActiveGoalToday = settings.goalEntryForDay(today)?.hasGoal == true;
    final hasCountedGoalToday = settings.countingGoalEntryForDay(today) != null;
    final nextGoalStartDate = settings.nextGoalStartAfterDay(today);
    final goalStartsInFuture =
        !hasCountedGoalToday && nextGoalStartDate != null;
    final futureGoalKcal = hasActiveGoalToday
        ? settings.goalKcalForDay(today)
        : nextGoalStartDate == null
        ? null
        : settings.goalKcalForDay(nextGoalStartDate);
    final todayBaseGoalKcal = adjustedOverviews.last.baseGoalKcal > 0
        ? adjustedOverviews.last.baseGoalKcal
        : adjustedOverviews.last.goalKcal;
    final carryoverBeforeTodayKcal =
        CalorieBudgetCalculator.distributeCarryover(
          carryoverKcal: cycleTotals.carryoverBeforeTodayKcal,
          remainingDays: resolveRemainingCalorieGoalRunDays(
            settings: settings,
            day: today,
          ),
          baseGoalKcal: todayBaseGoalKcal,
        );
    final todayFlexibleGoalKcal =
        adjustedOverviews.last.goalKcal + carryoverBeforeTodayKcal;
    return CalorieWeekOverview(
      days: List<CalorieWeekDayOverview>.unmodifiable(adjustedOverviews),
      totalConsumedKcal: cycleTotals.totalConsumedKcal,
      totalGoalKcal: cycleTotals.totalGoalKcal,
      remainingKcal: cycleTotals.totalGoalKcal - cycleTotals.totalConsumedKcal,
      balanceStartDate: balanceStartDate,
      carryoverBeforeTodayKcal: carryoverBeforeTodayKcal,
      todayFlexibleGoalKcal: todayFlexibleGoalKcal,
      goalStartsInFuture: goalStartsInFuture,
      nextGoalStartDate: nextGoalStartDate,
      futureGoalKcal: futureGoalKcal,
    );
  } finally {
    keepAliveLink.close();
  }
}

/// Calorie week day overview for date.
@riverpod
Future<CalorieWeekDayOverview> calorieWeekDayOverviewForDate(
  Ref ref,
  DateTime day,
) async {
  final keepAliveLink = ref.keepAlive();
  try {
    // Trigger recompute when calorie logs mutate through overview revision.
    ref.watch(calorieOverviewRevisionProvider);
    final normalizedDay = normalizeDiaryDay(day);
    final repository = ref.watch(calorieLogRepositoryProvider);
    final goalState = ref.watch(calorieGoalControllerProvider);
    final settings =
        goalState.asData?.value ?? const CalorieGoalSettings.empty();
    final resolvedGoalFuture = ref.watch(
      resolvedCalorieGoalForDayProvider(normalizedDay).future,
    );
    final entries = await readEntriesForDaySafely(repository, normalizedDay);
    if (!ref.mounted) {
      throw StateError('Calorie week day overview disposed.');
    }
    final totalKcal = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalKcal,
    );
    final resolvedGoal = await resolvedGoalFuture;
    if (!ref.mounted) {
      throw StateError('Calorie week day overview disposed.');
    }
    return CalorieWeekDayOverview(
      date: normalizedDay,
      totalKcal: totalKcal,
      goalKcal: resolvedGoal.goalKcal,
      baseGoalKcal: resolvedGoal.storedGoalKcal,
      entryCount: entries.length,
      isPauseDay: settings.isPauseDay(normalizedDay),
    );
  } finally {
    keepAliveLink.close();
  }
}
