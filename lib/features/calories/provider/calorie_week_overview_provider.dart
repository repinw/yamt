import 'dart:developer' show log;
import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
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
  });

  /// The date.
  final DateTime date;

  /// The total kcal.
  final double totalKcal;

  /// The goal kcal.
  final double goalKcal;

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

  /// The goal starts in future.
  final bool goalStartsInFuture;

  /// The next goal start date.
  final DateTime? nextGoalStartDate;
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
  final repository = ref.watch(calorieLogRepositoryProvider);
  final goalState = ref.watch(calorieGoalControllerProvider);
  final settings = goalState.asData?.value ?? const CalorieGoalSettings.empty();
  final resolvedGoals = await Future.wait(
    snapshot.days.map(
      (day) => ref.watch(resolvedCalorieGoalForDayProvider(day.date).future),
    ),
  );
  final overviews = snapshot.days
      .asMap()
      .entries
      .map(
        (entry) => CalorieWeekDayOverview(
          date: entry.value.date,
          totalKcal: entry.value.totalKcal,
          goalKcal: resolvedGoals[entry.key].goalKcal,
          entryCount: entry.value.entryCount,
        ),
      )
      .toList(growable: false);
  final today = snapshot.days.last.date;
  final visibleWindowStart = snapshot.days.first.date;
  final balanceStartDate = resolveCalorieBalanceCycleStartDate(
    settings: settings,
    day: today,
    fallbackStartDate: visibleWindowStart,
  );
  final historicalEntries = await _readEntriesInRangeSafely(
    repository: repository,
    startInclusive: balanceStartDate,
    endExclusive: visibleWindowStart,
  );
  final historicalEntriesByDay = historicalEntries.groupByDiaryDayKey();
  final shouldLoadVisibleCycleStartEntries =
      _needsCycleStartDayEntries(
        settings: settings,
        cycleStartDate: balanceStartDate,
      ) &&
      !_isBeforeDay(balanceStartDate, visibleWindowStart) &&
      !balanceStartDate.isAfter(today);
  final visibleCycleStartEntries = shouldLoadVisibleCycleStartEntries
      ? await _readEntriesForDaySafely(repository, balanceStartDate)
      : const <CalorieEntry>[];
  final adjustedOverviews = overviews
      .map(
        (overview) => CalorieWeekDayOverview(
          date: overview.date,
          totalKcal: overview.totalKcal,
          goalKcal:
              resolveCalorieBalanceCycleDayAdjustment(
                settings: settings,
                cycleStartDate: balanceStartDate,
                day: overview.date,
                dayEntries: isSameDiaryDay(overview.date, balanceStartDate)
                    ? visibleCycleStartEntries
                    : const <CalorieEntry>[],
                dailyGoalKcal: overview.goalKcal,
              )?.adjustedGoalKcal ??
              overview.goalKcal,
          entryCount: overview.entryCount,
        ),
      )
      .toList(growable: false);
  final cycleTotals = _calculateCycleTotals(
    settings: settings,
    cycleStartDate: balanceStartDate,
    today: today,
    visibleWindowStart: visibleWindowStart,
    historicalEntriesByDay: historicalEntriesByDay,
    visibleOverviews: adjustedOverviews,
  );
  final hasActiveGoalToday = settings.goalEntryForDay(today)?.hasGoal == true;
  final nextGoalStartDate = settings.nextGoalStartAfterDay(today);
  final goalStartsInFuture = !hasActiveGoalToday && nextGoalStartDate != null;
  final carryoverBeforeTodayKcal = cycleTotals.carryoverBeforeTodayKcal;
  final todayFlexibleGoalKcal = math.max<double>(
    0,
    adjustedOverviews.last.goalKcal + carryoverBeforeTodayKcal,
  );
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
  required CalorieGoalSettings settings,
  required DateTime cycleStartDate,
  required DateTime today,
  required DateTime visibleWindowStart,
  required Map<String, List<CalorieEntry>> historicalEntriesByDay,
  required List<CalorieWeekDayOverview> visibleOverviews,
}) {
  var totalConsumedKcal = 0.0;
  var totalGoalKcal = 0.0;
  var carryoverBeforeTodayKcal = 0.0;

  if (!cycleStartDate.isAfter(today)) {
    for (
      var day = normalizeDiaryDay(cycleStartDate);
      day.isBefore(normalizeDiaryDay(visibleWindowStart));
      day = nextDiaryDay(day)
    ) {
      final dayEntries =
          historicalEntriesByDay[diaryDayKey(day)] ?? const <CalorieEntry>[];
      final dayConsumedKcal = dayEntries.fold<double>(
        0,
        (sum, entry) => sum + entry.totalKcal,
      );
      final dayGoalKcal =
          resolveCalorieBalanceCycleDayAdjustment(
            settings: settings,
            cycleStartDate: cycleStartDate,
            day: day,
            dayEntries: dayEntries,
            dailyGoalKcal: settings.goalKcalForDay(day),
          )?.adjustedGoalKcal ??
          settings.goalKcalForDay(day);
      totalConsumedKcal += dayConsumedKcal;
      totalGoalKcal += dayGoalKcal;
      carryoverBeforeTodayKcal += dayGoalKcal - dayConsumedKcal;
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

bool _needsCycleStartDayEntries({
  required CalorieGoalSettings settings,
  required DateTime cycleStartDate,
}) {
  final cycleStartEntry =
      settings.cycleAnchorEntryForDay(cycleStartDate) ??
      settings.goalEntryForDay(cycleStartDate);
  if (cycleStartEntry?.hasGoal != true) {
    return false;
  }

  final goalChangedAt = cycleStartEntry!.effectiveChangedAt.toLocal();
  if (!isSameDiaryDay(goalChangedAt, cycleStartDate)) {
    return false;
  }

  return goalChangedAt.isAfter(
    settings.eatingWindowStartForDay(cycleStartDate),
  );
}

bool _isBeforeDay(DateTime left, DateTime right) {
  return DateTime(
    left.year,
    left.month,
    left.day,
  ).isBefore(DateTime(right.year, right.month, right.day));
}
