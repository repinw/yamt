import 'dart:math' as math;

import 'package:yamt/features/calories/domain/burn_week_mock_logic.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/burn_week_live_overview_logic.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';

/// Derived values needed to render the loaded Burn Week balance card.
class DiaryBalanceLoadedMetrics {
  /// Creates resolved loaded-card metrics.
  const DiaryBalanceLoadedMetrics({
    required this.selectedDay,
    required this.currentWeekStartDate,
    required this.metrics,
    required this.bufferAdjustmentKcal,
    required this.realEatenKcal,
    required this.eatenKcal,
    required this.realDayLeftKcal,
    required this.heartAdjustmentKcal,
    required this.dayLeftKcal,
    required this.isHeartDay,
    required this.canRevertHeartDay,
    required this.showGameControls,
    required this.runWeekNumber,
  });

  /// Date represented by the selected-day overview.
  final DateTime selectedDay;

  /// Start date for the currently displayed Burn Week run week.
  final DateTime currentWeekStartDate;

  /// Burn Week bar metrics.
  final BurnWeekMockMetrics metrics;

  /// Calorie adjustment from active heart credit.
  final double bufferAdjustmentKcal;

  /// Real logged kcal before virtual heart credit is applied.
  final double realEatenKcal;

  /// Displayed eaten calories after buffer adjustment.
  final double eatenKcal;

  /// Real selected-day calories left before heart adjustment.
  final double realDayLeftKcal;

  /// Displayed heart adjustment for calories left.
  final double heartAdjustmentKcal;

  /// Displayed calories left after heart adjustment.
  final double dayLeftKcal;

  /// Whether the selected day is currently marked as a heart day.
  final bool isHeartDay;

  /// Whether the selected heart day can be reverted.
  final bool canRevertHeartDay;

  /// Whether Burn Week game controls should be visible.
  final bool showGameControls;

  /// Run week number to display for the selected day.
  final int runWeekNumber;
}

/// Resolves all derived values for a loaded Burn Week balance card.
DiaryBalanceLoadedMetrics resolveDiaryBalanceLoadedMetrics({
  required CalorieWeekOverview weekOverview,
  required CalorieWeekDayOverview selectedDayOverview,
  required List<CalorieEntry> selectedDayEntries,
  required BurnWeekRunState runState,
  required bool isLiveDay,
}) {
  final currentWeekStartDate = resolveBurnWeekLiveWeekStartDate(
    currentDay: selectedDayOverview.date,
    balanceStartDate: weekOverview.balanceStartDate,
    storedWeekStartDayKey: runState.currentWeekStartDayKey,
  );
  final metrics = _resolveBurnWeekMetrics(
    weekOverview: weekOverview,
    selectedDayOverview: selectedDayOverview,
    selectedDayEntries: selectedDayEntries,
    currentWeekStartDate: currentWeekStartDate,
    runState: runState,
  );
  final realDayLeftKcal =
      weekOverview.todayFlexibleGoalKcal - selectedDayOverview.totalKcal;
  final bufferAdjustmentKcal = isLiveDay ? runState.heartCreditKcal : 0.0;
  final realEatenKcal = selectedDayOverview.totalKcal;
  final eatenKcal = math.max<double>(
    0,
    realEatenKcal + bufferAdjustmentKcal,
  );
  final heartAdjustmentKcal = -runState.heartCreditKcal;
  final isHeartDay = runState.isHeartDay(selectedDayOverview.date);
  final canRevertHeartDay = runState.canUnmarkHeartDay(
    selectedDayOverview.date,
  );
  final dayLeftKcal = isHeartDay ? 0.0 : realDayLeftKcal + heartAdjustmentKcal;
  final showGameControls =
      isLiveDay &&
      !weekOverview.goalStartsInFuture &&
      !_isBurnWeekLearningWeek(runState.runWeekNumber);
  final runWeekNumber = isLiveDay
      ? runState.runWeekNumber
      : _resolveSnapshotRunWeekNumber(
          currentDay: selectedDayOverview.date,
          balanceStartDate: weekOverview.balanceStartDate,
        );

  return DiaryBalanceLoadedMetrics(
    selectedDay: selectedDayOverview.date,
    currentWeekStartDate: currentWeekStartDate,
    metrics: metrics,
    bufferAdjustmentKcal: bufferAdjustmentKcal,
    realEatenKcal: realEatenKcal,
    eatenKcal: eatenKcal,
    realDayLeftKcal: realDayLeftKcal,
    heartAdjustmentKcal: heartAdjustmentKcal,
    dayLeftKcal: dayLeftKcal,
    isHeartDay: isHeartDay,
    canRevertHeartDay: canRevertHeartDay,
    showGameControls: showGameControls,
    runWeekNumber: runWeekNumber,
  );
}

/// Resolves a scheduled Burn Week restart date for the selected day.
DateTime? resolveDiaryBalanceScheduledRestartDate({
  required BurnWeekRunState runState,
  required DateTime today,
  required bool isLiveDay,
}) {
  if (!isLiveDay) {
    return null;
  }
  final storedWeekStartDate = tryParseBurnWeekDayKey(
    runState.currentWeekStartDayKey,
  );
  if (storedWeekStartDate == null || !storedWeekStartDate.isAfter(today)) {
    return null;
  }
  return storedWeekStartDate;
}

BurnWeekMockMetrics _resolveBurnWeekMetrics({
  required CalorieWeekOverview weekOverview,
  required CalorieWeekDayOverview selectedDayOverview,
  required List<CalorieEntry> selectedDayEntries,
  required DateTime currentWeekStartDate,
  required BurnWeekRunState runState,
}) {
  final weekCarryoverBeforeTodayKcal = resolveBurnWeekCarryoverBeforeTodayKcal(
    weekOverview: weekOverview,
    currentWeekStartDate: currentWeekStartDate,
    today: selectedDayOverview.date,
  );
  final previousWeekOverflowKcal = resolveBurnWeekPreviousOverflowKcal(
    cycleCarryoverBeforeTodayKcal: weekOverview.carryoverBeforeTodayKcal,
    currentWeekCarryoverBeforeTodayKcal: weekCarryoverBeforeTodayKcal,
    runWeekNumber: runState.runWeekNumber,
  );
  final difficulty = resolveBurnWeekMockDifficulty(runState.starCount);
  final plannedLaterTodayKcal =
      isSameDiaryDay(selectedDayOverview.date, DateTime.now())
      ? resolveBurnWeekPlannedLaterTodayKcal(
          todayEntries: selectedDayEntries,
          now: DateTime.now(),
        )
      : 0.0;

  return resolveBurnWeekLiveMetrics(
    now: _referenceNowForDay(selectedDayOverview.date),
    weekOverview: weekOverview,
    todayOverview: selectedDayOverview,
    currentWeekStartDate: currentWeekStartDate,
    previousWeekOverflowKcal: previousWeekOverflowKcal,
    heartCreditKcal: runState.heartCreditKcal,
    plannedLaterTodayKcal: plannedLaterTodayKcal,
    safeZoneMultiplier: difficulty.safeZoneMultiplier,
  );
}

DateTime _referenceNowForDay(DateTime day) {
  final today = normalizeDiaryDay(DateTime.now());
  final normalizedSelectedDay = normalizeDiaryDay(day);
  if (normalizedSelectedDay.isBefore(today)) {
    return DateTime(day.year, day.month, day.day, 23, 59, 59);
  }
  if (normalizedSelectedDay.isAfter(today)) {
    return normalizeDiaryDay(day);
  }

  return DateTime.now();
}

int _resolveSnapshotRunWeekNumber({
  required DateTime currentDay,
  required DateTime balanceStartDate,
}) {
  final elapsedDays = resolveBurnWeekLiveElapsedDays(
    currentDay: currentDay,
    balanceStartDate: balanceStartDate,
  );
  return (elapsedDays ~/ burnWeekDaysPerWeek) + 1;
}

bool _isBurnWeekLearningWeek(int runWeekNumber) {
  return runWeekNumber <= burnWeekLearningRunWeekNumber;
}
