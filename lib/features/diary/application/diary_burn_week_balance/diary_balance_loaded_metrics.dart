import 'package:yamt/features/calories/application/burn_week_live_overview_logic.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_weekly_balance_metrics.dart';

/// Derived values needed to render the loaded Burn Week balance card.
class DiaryBalanceLoadedMetrics {
  /// Creates resolved loaded-card metrics.
  const DiaryBalanceLoadedMetrics({
    required this.selectedDay,
    required this.daily,
    required this.weekly,
    required this.state,
  });

  /// Date represented by the selected-day overview.
  final DateTime selectedDay;

  /// Derived values for the daily card.
  final DiaryDailyBalanceMetrics daily;

  /// Derived values for the weekly pacing card.
  final DiaryWeeklyBalanceMetrics weekly;

  /// Loaded card display state.
  final DiaryBalanceLoadedState state;
}

/// Loaded card display state that is not specific to daily or weekly metrics.
class DiaryBalanceLoadedState {
  /// Creates loaded-card display state.
  const DiaryBalanceLoadedState({
    required this.isHeartDay,
    required this.canRevertHeartDay,
    required this.showGameControls,
    required this.runWeekNumber,
  });

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
  required DateTime now,
}) {
  final currentWeekStartDate = resolveBurnWeekLiveWeekStartDate(
    currentDay: selectedDayOverview.date,
    balanceStartDate: weekOverview.balanceStartDate,
    storedWeekStartDayKey: runState.currentWeekStartDayKey,
  );
  final loadedState = _resolveDiaryBalanceLoadedState(
    weekOverview: weekOverview,
    selectedDayOverview: selectedDayOverview,
    runState: runState,
    isLiveDay: isLiveDay,
  );
  final bufferAdjustmentKcal = isLiveDay ? runState.heartCreditKcal : 0.0;
  final dailyMetrics = resolveDiaryDailyBalanceMetrics(
    flexibleGoalKcal: weekOverview.todayFlexibleGoalKcal,
    totalKcal: selectedDayOverview.totalKcal,
    goalKcal: selectedDayOverview.goalKcal,
    baseGoalKcal: selectedDayOverview.baseGoalKcal,
    activitySegmentKcal: selectedDayOverview.activityBonusKcal,
    bufferAdjustmentKcal: bufferAdjustmentKcal,
    heartCreditKcal: runState.heartCreditKcal,
    isHeartDay: loadedState.isHeartDay,
  );
  final weeklyMetrics = resolveDiaryWeeklyBalanceMetrics(
    weekOverview: weekOverview,
    selectedDayOverview: selectedDayOverview,
    selectedDayEntries: selectedDayEntries,
    currentWeekStartDate: currentWeekStartDate,
    runState: runState,
    now: now,
  );

  return DiaryBalanceLoadedMetrics(
    selectedDay: selectedDayOverview.date,
    daily: dailyMetrics,
    weekly: weeklyMetrics,
    state: loadedState,
  );
}

DiaryBalanceLoadedState _resolveDiaryBalanceLoadedState({
  required CalorieWeekOverview weekOverview,
  required CalorieWeekDayOverview selectedDayOverview,
  required BurnWeekRunState runState,
  required bool isLiveDay,
}) {
  final runWeekNumber = isLiveDay
      ? runState.runWeekNumber
      : _resolveSnapshotRunWeekNumber(
          currentDay: selectedDayOverview.date,
          balanceStartDate: weekOverview.balanceStartDate,
        );

  return DiaryBalanceLoadedState(
    isHeartDay: runState.isHeartDay(selectedDayOverview.date),
    canRevertHeartDay: runState.canUnmarkHeartDay(selectedDayOverview.date),
    showGameControls:
        isLiveDay &&
        !weekOverview.goalStartsInFuture &&
        !_isBurnWeekLearningWeek(runState.runWeekNumber),
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
