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
  }) : baseGoalKcal = baseGoalKcal ?? goalKcal;

  /// The date.
  final DateTime date;

  /// The total kcal.
  final double totalKcal;

  /// The goal kcal.
  final double goalKcal;

  /// The saved base goal kcal before daily activity adjustment.
  final double baseGoalKcal;

  /// The entry count.
  final int entryCount;

  /// Whether entries.
  bool get hasEntries => entryCount > 0;

  /// Whether within goal.
  bool get isWithinGoal => hasEntries && totalKcal <= goalKcal;

  /// Whether over goal.
  bool get isOverGoal => hasEntries && totalKcal > goalKcal;
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
  ref.watch(calorieOverviewRevisionProvider);
  final repository = ref.watch(calorieLogRepositoryProvider);
  final days = buildDiaryVisibleDays(anchorDay: visibleWindowEnd);

  final entriesByDay = await Future.wait(
    days.map((day) => _readEntriesForDaySafely(repository, day)),
  );

  final snapshots = <CalorieWeekConsumptionDaySnapshot>[];
  var totalConsumedKcal = 0.0;
  for (var index = 0; index < days.length; index += 1) {
    final entries = entriesByDay[index];
    final totalKcal = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalKcal,
    );
    totalConsumedKcal += totalKcal;
    snapshots.add(
      CalorieWeekConsumptionDaySnapshot(
        date: days[index],
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
  final snapshot = await ref.watch(
    calorieWeekConsumptionSnapshotForWindowProvider(visibleWindowEnd).future,
  );
  if (!ref.mounted) {
    throw StateError('Calorie week overview disposed.');
  }
  final repository = ref.watch(calorieLogRepositoryProvider);
  final goalState = ref.watch(calorieGoalControllerProvider);
  final settings = goalState.asData?.value ?? const CalorieGoalSettings.empty();
  final resolvedGoals = await Future.wait(
    snapshot.days.map(
      (day) => ref.watch(resolvedCalorieGoalForDayProvider(day.date).future),
    ),
  );
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
          goalKcal: resolvedGoals[entry.key].goalKcal,
          baseGoalKcal: resolvedGoals[entry.key].storedGoalKcal,
          entryCount: entry.value.entryCount,
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
  final historicalGoals = await Future.wait(
    historicalDays.map(
      (day) => ref.watch(resolvedCalorieGoalForDayProvider(day).future),
    ),
  );
  if (!ref.mounted) {
    throw StateError('Calorie week overview disposed.');
  }
  final historicalGoalKcals = historicalGoals
      .map((goal) => goal.goalKcal)
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
        ),
      )
      .toList(growable: false);
  final cycleTotals = _calculateCycleTotals(
    cycleStartDate: carryoverStartDate,
    today: today,
    historicalCarryoverDays: historicalCarryoverDays,
    visibleOverviews: adjustedOverviews,
  );
  final hasActiveGoalToday = settings.goalEntryForDay(today)?.hasGoal == true;
  final hasCountedGoalToday = settings.countingGoalEntryForDay(today) != null;
  final nextGoalStartDate = settings.nextGoalStartAfterDay(today);
  final goalStartsInFuture = !hasCountedGoalToday && nextGoalStartDate != null;
  final futureGoalKcal = hasActiveGoalToday
      ? settings.goalKcalForDay(today)
      : nextGoalStartDate == null
      ? null
      : settings.goalKcalForDay(nextGoalStartDate);
  final carryoverBeforeTodayKcal = CalorieBudgetCalculator.distributeCarryover(
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
}

/// Calorie week day overview for date.
@riverpod
Future<CalorieWeekDayOverview> calorieWeekDayOverviewForDate(
  Ref ref,
  DateTime day,
) async {
  ref.watch(calorieOverviewRevisionProvider);
  final normalizedDay = normalizeDiaryDay(day);
  final repository = ref.watch(calorieLogRepositoryProvider);
  final entries = await _readEntriesForDaySafely(repository, normalizedDay);
  final totalKcal = entries.fold<double>(
    0,
    (sum, entry) => sum + entry.totalKcal,
  );
  final resolvedGoal = await ref.watch(
    resolvedCalorieGoalForDayProvider(normalizedDay).future,
  );
  return CalorieWeekDayOverview(
    date: normalizedDay,
    totalKcal: totalKcal,
    goalKcal: resolvedGoal.goalKcal,
    baseGoalKcal: resolvedGoal.storedGoalKcal,
    entryCount: entries.length,
  );
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
  required List<CalorieWeekDayOverview> visibleOverviews,
}) {
  var totalConsumedKcal = 0.0;
  var totalGoalKcal = 0.0;
  var carryoverBeforeTodayKcal = 0.0;

  if (!cycleStartDate.isAfter(today)) {
    for (final day in historicalCarryoverDays) {
      totalConsumedKcal += day.consumedKcal;
      totalGoalKcal += day.goalKcal;
      carryoverBeforeTodayKcal += day.goalKcal - day.consumedKcal;
    }

    for (final day in visibleOverviews) {
      if (_isBeforeDay(day.date, cycleStartDate)) {
        continue;
      }
      totalConsumedKcal += day.totalKcal;
      totalGoalKcal += day.goalKcal;
      if (_isBeforeDay(day.date, today)) {
        carryoverBeforeTodayKcal += day.goalKcal - day.totalKcal;
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
