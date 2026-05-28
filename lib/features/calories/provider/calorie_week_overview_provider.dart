import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_carryover_history.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_resolved_goal_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_visible_window_controller.dart';

part 'calorie_week_overview_provider.g.dart';

const _weekOverviewLogName = 'CalorieWeekOverviewProvider';

/// Defines calorie week consumption day snapshot.
class CalorieWeekConsumptionDaySnapshot {
  /// The calorie week consumption day snapshot.
  const CalorieWeekConsumptionDaySnapshot({
    required this.date,
    required this.totalKcal,
    required this.entryCount,
  });

  /// The date.
  final DateTime date;

  /// The total kcal.
  final double totalKcal;

  /// The entry count.
  final int entryCount;
}

/// Defines calorie week consumption snapshot.
class CalorieWeekConsumptionSnapshot {
  /// The calorie week consumption snapshot.
  const CalorieWeekConsumptionSnapshot({
    required this.days,
    required this.totalConsumedKcal,
  });

  /// The days.
  final List<CalorieWeekConsumptionDaySnapshot> days;

  /// The total consumed kcal.
  final double totalConsumedKcal;
}

/// Aggregate data for one visible day in the diary week strip.
class CalorieWeekDayOverview {
  /// The calorie week day overview.
  const CalorieWeekDayOverview({
    required this.date,
    required this.totalKcal,
    required this.goalKcal,
    required this.entryCount,
    double? baseGoalKcal,
    this.activityBonusKcal = 0,
    this.isHeartDay = false,
  }) : baseGoalKcal = baseGoalKcal ?? goalKcal;

  /// The date.
  final DateTime date;

  /// The total kcal.
  final double totalKcal;

  /// The goal kcal.
  final double goalKcal;

  /// The saved base goal kcal before daily activity adjustment.
  final double baseGoalKcal;

  /// Eatable activity kcal counted toward the day.
  final double activityBonusKcal;

  /// The entry count.
  final int entryCount;

  /// Whether this day is protected by a spent heart.
  final bool isHeartDay;

  /// Whether entries.
  bool get hasEntries => entryCount > 0;

  /// Kcal counted by Burn Week/carryover math.
  double get countedTotalKcal => isHeartDay ? goalKcal : totalKcal;

  /// Base-goal kcal counted by Burn Week carryover math.
  double get countedBaseTotalKcal => isHeartDay ? baseGoalKcal : totalKcal;

  /// Whether within goal.
  bool get isWithinGoal => isHeartDay || (hasEntries && totalKcal <= goalKcal);

  /// Whether over goal.
  bool get isOverGoal => !isHeartDay && hasEntries && totalKcal > goalKcal;
}

/// Overview for the rolling 7-day diary strip ending at the visible window end.
class CalorieWeekOverview {
  /// The calorie week overview.
  const CalorieWeekOverview({
    required this.days,
    required this.totalConsumedKcal,
    required this.totalGoalKcal,
    required this.remainingKcal,
    required this.balanceStartDate,
    required this.carryoverBeforeTodayKcal,
    required this.todayFlexibleGoalKcal,
    required this.goalStartsInFuture,
    required this.nextGoalStartDate,
    required this.futureGoalKcal,
  });

  /// The days.
  final List<CalorieWeekDayOverview> days;

  /// The total consumed kcal.
  final double totalConsumedKcal;

  /// The total goal kcal.
  final double totalGoalKcal;

  /// The remaining kcal.
  final double remainingKcal;

  /// The balance start date.
  final DateTime balanceStartDate;

  /// The carryover before today kcal.
  final double carryoverBeforeTodayKcal;

  /// The today flexible goal kcal.
  final double todayFlexibleGoalKcal;

  /// Whether official Burn Week and weekly check-in counting starts later.
  final bool goalStartsInFuture;

  /// The next official counting start date.
  final DateTime? nextGoalStartDate;

  /// The active goal kcal shown before official counting starts.
  final double? futureGoalKcal;
}

/// Calorie week consumption snapshot.
@riverpod
Future<CalorieWeekConsumptionSnapshot> calorieWeekConsumptionSnapshot(
  Ref ref,
) async {
  final visibleWindowEnd = ref.watch(calorieVisibleWindowControllerProvider);
  return ref.watch(
    calorieWeekConsumptionSnapshotForWindowProvider(visibleWindowEnd).future,
  );
}

/// Calorie week consumption snapshot for window.
@riverpod
Future<CalorieWeekConsumptionSnapshot> calorieWeekConsumptionSnapshotForWindow(
  Ref ref,
  DateTime visibleWindowEnd,
) async {
  // Trigger recompute when calorie logs mutate through overview revision.
  ref.watch(calorieOverviewRevisionProvider);
  final repository = ref.watch(calorieLogRepositoryProvider);
  final days = buildDiaryVisibleDays(anchorDay: visibleWindowEnd);
  final entriesByDay = await _readVisibleEntriesByDaySafely(
    repository: repository,
    days: days,
  );

  final snapshots = <CalorieWeekConsumptionDaySnapshot>[];
  var totalConsumedKcal = 0.0;
  for (var index = 0; index < days.length; index += 1) {
    final day = days[index];
    final entries = entriesByDay[diaryDayKey(day)] ?? const <CalorieEntry>[];
    final totalKcal = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalKcal,
    );
    totalConsumedKcal += totalKcal;
    snapshots.add(
      CalorieWeekConsumptionDaySnapshot(
        date: day,
        totalKcal: totalKcal,
        entryCount: entries.length,
      ),
    );
  }

  return CalorieWeekConsumptionSnapshot(
    days: List<CalorieWeekConsumptionDaySnapshot>.unmodifiable(snapshots),
    totalConsumedKcal: totalConsumedKcal,
  );
}

Future<Map<String, List<CalorieEntry>>> _readVisibleEntriesByDaySafely({
  required CalorieLogRepositoryContract repository,
  required List<DateTime> days,
}) async {
  if (days.isEmpty) {
    return const <String, List<CalorieEntry>>{};
  }

  try {
    final entries = await repository.readEntriesInRange(
      startInclusive: days.first,
      endExclusive: nextDiaryDay(days.last),
    );
    return entries.groupByDiaryDayKey();
  } on Object catch (error, stackTrace) {
    log(
      'Failed to load calorie visible range for week overview.',
      name: _weekOverviewLogName,
      error: error,
      stackTrace: stackTrace,
    );
  }

  final dayEntries = await Future.wait(
    days.map((day) => _readEntriesForDaySafely(repository, day)),
  );
  return <String, List<CalorieEntry>>{
    for (var index = 0; index < days.length; index += 1)
      diaryDayKey(days[index]): dayEntries[index],
  };
}

/// Calorie week overview.
@riverpod
Future<CalorieWeekOverview> calorieWeekOverview(Ref ref) async {
  final visibleWindowEnd = ref.watch(calorieVisibleWindowControllerProvider);
  return ref.watch(
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
    final runState = ref.watch(burnWeekRunControllerProvider).asData?.value;
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
        .map(
          (entry) => CalorieWeekDayOverview(
            date: entry.value.date,
            totalKcal: entry.value.totalKcal,
            goalKcal:
                resolvedGoalsByDay[diaryDayKey(entry.value.date)]!.goalKcal,
            baseGoalKcal: resolvedGoalsByDay[diaryDayKey(entry.value.date)]!
                .storedGoalKcal,
            activityBonusKcal:
                resolvedGoalsByDay[diaryDayKey(entry.value.date)]!
                    .activityDeltaKcal,
            entryCount: entry.value.entryCount,
            isHeartDay: runState?.isHeartDay(entry.value.date) ?? false,
          ),
        )
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
    final historicalEntries = await _readEntriesInRangeSafely(
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
    final historicalGoalsByDay = historicalDays.isEmpty
        ? const <String, ResolvedCalorieGoalData>{}
        : await ref.read(
            resolvedCalorieGoalsForDaysProvider(
              ResolvedCalorieGoalDaysRequest.fromDays(historicalDays),
            ).future,
          );
    if (!ref.mounted) {
      throw StateError('Calorie week overview disposed.');
    }
    final historicalGoalKcals = historicalDays
        .map((day) => historicalGoalsByDay[diaryDayKey(day)]!.goalKcal)
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
            activityBonusKcal: overview.activityBonusKcal,
            entryCount: overview.entryCount,
            isHeartDay: overview.isHeartDay,
          ),
        )
        .toList(growable: false);
    final cycleTotals = _calculateCycleTotals(
      cycleStartDate: carryoverStartDate,
      today: today,
      historicalCarryoverDays: historicalCarryoverDays,
      historicalDays: historicalDays,
      heartDayKeys: runState?.heartDayKeys.toSet() ?? const <String>{},
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
    final carryoverBeforeTodayKcal =
        CalorieBudgetCalculator.distributeCarryover(
          carryoverKcal: cycleTotals.carryoverBeforeTodayKcal,
          remainingDays: resolveRemainingCalorieGoalRunDays(
            settings: settings,
            day: today,
          ),
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
    final runState = ref.watch(burnWeekRunControllerProvider).asData?.value;
    final resolvedGoalFuture = ref.watch(
      resolvedCalorieGoalForDayProvider(normalizedDay).future,
    );
    final entries = await _readEntriesForDaySafely(repository, normalizedDay);
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
      activityBonusKcal: resolvedGoal.activityDeltaKcal,
      entryCount: entries.length,
      isHeartDay: runState?.isHeartDay(normalizedDay) ?? false,
    );
  } finally {
    keepAliveLink.close();
  }
}

Future<List<CalorieEntry>> _readEntriesForDaySafely(
  CalorieLogRepositoryContract repository,
  DateTime day,
) async {
  try {
    return await repository.readEntriesForDay(day);
  } on Object catch (error, stackTrace) {
    log(
      'Failed to load calorie entries for week overview on $day.',
      name: _weekOverviewLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return const <CalorieEntry>[];
  }
}

Future<List<CalorieEntry>> _readEntriesInRangeSafely({
  required CalorieLogRepositoryContract repository,
  required DateTime startInclusive,
  required DateTime endExclusive,
}) async {
  if (!startInclusive.isBefore(endExclusive)) {
    return const <CalorieEntry>[];
  }

  try {
    return await repository.readEntriesInRange(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
  } on Object catch (error, stackTrace) {
    log(
      'Failed to load calorie history range for week overview.',
      name: _weekOverviewLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return const <CalorieEntry>[];
  }
}

({
  double totalConsumedKcal,
  double totalGoalKcal,
  double carryoverBeforeTodayKcal,
})
_calculateCycleTotals({
  required DateTime cycleStartDate,
  required DateTime today,
  required List<CalorieCarryoverDay> historicalCarryoverDays,
  required List<DateTime> historicalDays,
  required Set<String> heartDayKeys,
  required List<CalorieWeekDayOverview> visibleOverviews,
}) {
  var totalConsumedKcal = 0.0;
  var totalGoalKcal = 0.0;
  var carryoverBeforeTodayKcal = 0.0;

  if (!cycleStartDate.isAfter(today)) {
    for (var index = 0; index < historicalCarryoverDays.length; index += 1) {
      final day = historicalCarryoverDays[index];
      final isHeartDay =
          index < historicalDays.length &&
          heartDayKeys.contains(diaryDayKey(historicalDays[index]));
      final consumedKcal = isHeartDay ? day.goalKcal : day.consumedKcal;
      totalConsumedKcal += consumedKcal;
      totalGoalKcal += day.goalKcal;
      carryoverBeforeTodayKcal += day.goalKcal - consumedKcal;
    }

    for (final day in visibleOverviews) {
      if (_isBeforeDay(day.date, cycleStartDate)) {
        continue;
      }
      totalConsumedKcal += day.countedTotalKcal;
      totalGoalKcal += day.goalKcal;
      if (_isBeforeDay(day.date, today)) {
        carryoverBeforeTodayKcal += day.goalKcal - day.countedTotalKcal;
      }
    }
  }

  return (
    totalConsumedKcal: totalConsumedKcal,
    totalGoalKcal: totalGoalKcal,
    carryoverBeforeTodayKcal: carryoverBeforeTodayKcal,
  );
}

bool _isBeforeDay(DateTime left, DateTime right) {
  return DateTime(
    left.year,
    left.month,
    left.day,
  ).isBefore(DateTime(right.year, right.month, right.day));
}
