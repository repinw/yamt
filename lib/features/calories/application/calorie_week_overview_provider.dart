import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/application/calorie_resolved_goal_provider.dart';
import 'package:yamt/features/calories/application/calorie_visible_window_controller.dart';
import 'package:yamt/features/calories/application/calorie_week_consumption_snapshot_provider.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_builder.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_log_loader.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/closed_day_repository.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

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
    final realToday = ref.watch(diaryTodayProvider);
    // Whoever saves the closed day bumps the overview revision.
    ref.watch(calorieOverviewRevisionProvider);
    final closedDayRepository = ref.watch(closedDayRepositoryProvider);

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
