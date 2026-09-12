import 'dart:developer' show log;

import 'package:json_annotation/json_annotation.dart';
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
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CalorieWeekDayOverview {
  /// The calorie week day overview.
  const CalorieWeekDayOverview({
    required this.date,
    required this.totalKcal,
    required this.goalKcal,
    required this.entryCount,
    double? baseGoalKcal,
    this.activityBonusKcal = 0,
    this.todayActiveKcal = 0,
    this.expectedActivityKcal = 0,
    this.isActivityTrackingActive = false,
    this.isPauseDay = false,
  }) : baseGoalKcal = baseGoalKcal ?? goalKcal;

  /// Creates data from persisted JSON.
  factory CalorieWeekDayOverview.fromJson(Map<String, dynamic> json) =>
      _$CalorieWeekDayOverviewFromJson(json);

  /// Converts data to persisted JSON.
  Map<String, dynamic> toJson() => _$CalorieWeekDayOverviewToJson(this);

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

  /// Active energy tracked on this day.
  final int todayActiveKcal;

  /// Expected baseline active calories for this day.
  final double expectedActivityKcal;

  /// Whether activity tracking is active for this day.
  final bool isActivityTrackingActive;

  /// The entry count.
  final int entryCount;

  /// Whether this day is marked as a pause day.
  final bool isPauseDay;

  /// Whether entries.
  bool get hasEntries => entryCount > 0;

  /// Kcal counted by Burn Week/carryover math.
  double get countedTotalKcal => isPauseDay ? goalKcal : totalKcal;

  /// Base-goal kcal counted by Burn Week carryover math.
  double get countedBaseTotalKcal => isPauseDay ? baseGoalKcal : totalKcal;

  /// Whether within goal.
  bool get isWithinGoal => isPauseDay || (hasEntries && totalKcal <= goalKcal);

  /// Whether over goal.
  bool get isOverGoal => !isPauseDay && hasEntries && totalKcal > goalKcal;
}

/// Overview for the rolling 7-day diary strip ending at the visible window end.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
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

  /// Creates data from persisted JSON.
  factory CalorieWeekOverview.fromJson(Map<String, dynamic> json) =>
      _$CalorieWeekOverviewFromJson(json);

  /// Converts data to persisted JSON.
  Map<String, dynamic> toJson() => _$CalorieWeekOverviewToJson(this);

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
    final settings =
        goalState.asData?.value ?? const CalorieGoalSettings.empty();
    final resolvedGoalsFuture = ref.watch(
      resolvedCalorieGoalsForDaysProvider(
        ResolvedCalorieGoalDaysRequest.fromDays(
          visibleDays,
          forceDetailedActivity: true,
        ),
      ).future,
    );
    final today = visibleDays.last;
    final visibleWindowStart = visibleDays.first;
    // Bind the widest possible historical-goal dependency synchronously.
    // A later first-entry lookup can only move the actual start forward. This
    // keeps every Ref access before the first await, so an invalidated provider
    // generation can finish silently and Riverpod can discard its stale value.
    final widestBalanceStartDate = resolveCalorieBalanceCycleStartDate(
      settings: settings,
      day: today,
      fallbackStartDate: visibleWindowStart,
    );
    final widestCarryoverStartDate = resolveCalorieCarryoverStartDate(
      settings: settings,
      day: today,
      balanceStartDate: widestBalanceStartDate,
    );
    final widestHistoricalDays = buildCalorieCarryoverDateRange(
      startInclusive: widestCarryoverStartDate,
      endExclusive: visibleWindowStart,
    );
    final historicalGoalsFuture = widestHistoricalDays.isEmpty
        ? Future<Map<String, ResolvedCalorieGoalData>>.value(
            const <String, ResolvedCalorieGoalData>{},
          )
        : ref.watch(
            resolvedCalorieGoalsForDaysProvider(
              ResolvedCalorieGoalDaysRequest.fromDays(widestHistoricalDays),
            ).future,
          );

    final snapshot = await snapshotFuture;
    final resolvedGoalsByDay = await resolvedGoalsFuture;
    final overviews = snapshot.days
        .asMap()
        .entries
        .map(
          (entry) {
            final goal = resolvedGoalsByDay[diaryDayKey(entry.value.date)]!;
            return CalorieWeekDayOverview(
              date: entry.value.date,
              totalKcal: entry.value.totalKcal,
              goalKcal: goal.goalKcal,
              baseGoalKcal: goal.storedGoalKcal,
              activityBonusKcal: goal.activityDeltaKcal,
              todayActiveKcal: goal.todayActiveKcal,
              expectedActivityKcal: goal.expectedActivityKcal,
              isActivityTrackingActive: goal.isActivityTrackingActive,
              entryCount: entry.value.entryCount,
              isPauseDay: settings.isPauseDay(entry.value.date),
            );
          },
        )
        .toList(growable: false);
    final firstEntryDate = await repository.readFirstEntryDate();
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
    final historicalDays = buildCalorieCarryoverDateRange(
      startInclusive: carryoverStartDate,
      endExclusive: visibleWindowStart,
    );
    final historicalEntries = historicalDays.isEmpty
        ? const <CalorieEntry>[]
        : await _readEntriesInRangeSafely(
            repository: repository,
            startInclusive: carryoverStartDate,
            endExclusive: visibleWindowStart,
          );
    final historicalEntriesByDay = historicalEntries.groupByDiaryDayKey();
    final historicalGoalsByDay = await historicalGoalsFuture;
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
            todayActiveKcal: overview.todayActiveKcal,
            expectedActivityKcal: overview.expectedActivityKcal,
            isActivityTrackingActive: overview.isActivityTrackingActive,
            entryCount: overview.entryCount,
            isPauseDay: overview.isPauseDay,
          ),
        )
        .toList(growable: false);
    final cycleTotals = _calculateCycleTotals(
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
    final entries = await _readEntriesForDaySafely(repository, normalizedDay);
    final totalKcal = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalKcal,
    );
    final resolvedGoal = await resolvedGoalFuture;
    return CalorieWeekDayOverview(
      date: normalizedDay,
      totalKcal: totalKcal,
      goalKcal: resolvedGoal.goalKcal,
      baseGoalKcal: resolvedGoal.storedGoalKcal,
      activityBonusKcal: resolvedGoal.activityDeltaKcal,
      todayActiveKcal: resolvedGoal.todayActiveKcal,
      expectedActivityKcal: resolvedGoal.expectedActivityKcal,
      isActivityTrackingActive: resolvedGoal.isActivityTrackingActive,
      entryCount: entries.length,
      isPauseDay: settings.isPauseDay(normalizedDay),
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
  required CalorieGoalSettings settings,
  required List<CalorieWeekDayOverview> visibleOverviews,
}) {
  var totalConsumedKcal = 0.0;
  var totalGoalKcal = 0.0;
  var carryoverBeforeTodayKcal = 0.0;

  if (!cycleStartDate.isAfter(today)) {
    for (var index = 0; index < historicalCarryoverDays.length; index += 1) {
      final day = historicalCarryoverDays[index];
      final isPauseDay =
          index < historicalDays.length &&
          settings.isPauseDay(historicalDays[index]);
      final consumedKcal = isPauseDay ? day.goalKcal : day.consumedKcal;
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
