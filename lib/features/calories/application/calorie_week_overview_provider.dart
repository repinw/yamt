import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/application/calorie_budget_settings_provider.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/application/calorie_resolved_goal_provider.dart';
import 'package:yamt/features/calories/application/calorie_week_consumption_snapshot_provider.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_builder.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_log_loader.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/closed_day_repository.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';

part 'calorie_week_overview_provider.g.dart';

/// Calorie week overview for window.
@riverpod
Future<CalorieWeekOverview> calorieWeekOverviewForWindow(
  Ref ref,
  DateTime visibleWindowEnd,
) async {
  final keepAliveLink = ref.keepAlive();
  try {
    final visibleDays = buildRollingLocalDays(anchorDay: visibleWindowEnd);
    final snapshotFuture = ref.watch(
      calorieWeekConsumptionSnapshotForWindowProvider(visibleWindowEnd).future,
    );
    final repository = ref.watch(calorieLogRepositoryProvider);
    // Started with the others to save a server round trip; an error still
    // surfaces at its await below.
    final firstEntryDateFuture = repository.readFirstEntryDate()..ignore();
    final settingsFuture = ref.watch(calorieBudgetSettingsProvider.future);
    final resolvedGoalsFuture = ref.watch(
      resolvedCalorieGoalsForDaysProvider(
        ResolvedCalorieGoalDaysRequest.fromDays(visibleDays),
      ).future,
    );
    final realToday = ref.watch(diaryTodayProvider);
    // Whoever saves the closed day bumps the overview revision.
    ref.watch(calorieOverviewRevisionProvider);
    final closedDayRepository = ref.watch(closedDayRepositoryProvider);

    final snapshot = await snapshotFuture;
    if (!ref.mounted) {
      throw StateError('Calorie week overview disposed.');
    }
    final settings = await settingsFuture;
    if (!ref.mounted) {
      throw StateError('Calorie week overview disposed.');
    }
    final resolvedGoalsByDay = await resolvedGoalsFuture;
    if (!ref.mounted) {
      throw StateError('Calorie week overview disposed.');
    }
    final overviews = snapshot.days
        .asMap()
        .entries
        .map((entry) {
          final goal = resolvedGoalsByDay[localDayKey(entry.value.date)]!;
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
    final firstEntryDate = await firstEntryDateFuture;
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
    final historicalEntries = await readEntriesInRangeOrEmpty(
      repository: repository,
      startInclusive: carryoverStartDate,
      endExclusive: visibleWindowStart,
    );
    if (!ref.mounted) {
      throw StateError('Calorie week overview disposed.');
    }
    return buildCalorieWeekOverview(
      settings: settings,
      overviews: overviews,
      realToday: realToday,
      balanceStartDate: balanceStartDate,
      carryoverStartDate: carryoverStartDate,
      historicalEntries: historicalEntries,
      readClosedDay: closedDayRepository.readClosedDay,
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
    final normalizedDay = normalizeLocalDay(day);
    final repository = ref.watch(calorieLogRepositoryProvider);
    final settingsFuture = ref.watch(calorieBudgetSettingsProvider.future);
    final resolvedGoalFuture = ref.watch(
      resolvedCalorieGoalForDayProvider(normalizedDay).future,
    );
    final settings = await settingsFuture;
    if (!ref.mounted) {
      throw StateError('Calorie week day overview disposed.');
    }
    final entries = await repository.readEntriesForDay(normalizedDay);
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
