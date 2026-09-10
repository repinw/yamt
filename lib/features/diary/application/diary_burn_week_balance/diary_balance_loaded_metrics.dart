import 'package:yamt/features/calories/application/burn_week_live_overview_logic.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_budget_details_data.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_weekly_balance_metrics.dart';

/// Derived values needed to render the loaded Burn Week balance card.
class DiaryBalanceLoadedMetrics {
  /// Creates resolved loaded-card metrics.
  const DiaryBalanceLoadedMetrics({
    required this.selectedDay,
    required this.daily,
    required this.weekly,
    required this.state,
    this.budgetDetails,
  });

  /// Date represented by the selected-day overview.
  final DateTime selectedDay;

  /// Derived values for the daily card.
  final DiaryDailyBalanceMetrics daily;

  /// Derived values for the weekly pacing card.
  final DiaryWeeklyBalanceMetrics weekly;

  /// Loaded card display state.
  final DiaryBalanceLoadedState state;

  /// Detailed budget and carryover breakdown for the selected day.
  final DiaryDailyBudgetDetailsData? budgetDetails;
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

typedef _DiaryBalanceLoadedContext = ({
  CalorieWeekOverview weekOverview,
  CalorieWeekDayOverview selectedDayOverview,
  List<CalorieEntry> selectedDayEntries,
  BurnWeekRunState runState,
  bool isLiveDay,
  DateTime now,
});

/// Resolves all derived values for a loaded Burn Week balance card.
DiaryBalanceLoadedMetrics resolveDiaryBalanceLoadedMetrics({
  required CalorieWeekOverview weekOverview,
  required CalorieWeekDayOverview selectedDayOverview,
  required List<CalorieEntry> selectedDayEntries,
  required BurnWeekRunState runState,
  required bool isLiveDay,
  required DateTime now,
}) {
  final context = (
    weekOverview: weekOverview,
    selectedDayOverview: selectedDayOverview,
    selectedDayEntries: selectedDayEntries,
    runState: runState,
    isLiveDay: isLiveDay,
    now: now,
  );
  return _resolveDiaryBalanceLoadedMetrics(context);
}

DiaryBalanceLoadedMetrics _resolveDiaryBalanceLoadedMetrics(
  _DiaryBalanceLoadedContext context,
) {
  final weekStart = _resolveCurrentWeekStartDate(context);
  final state = _resolveLoadedState(context);
  final daily = _resolveDailyMetrics(context, state);
  return _buildDiaryBalanceLoadedMetrics(context, weekStart, state, daily);
}

DiaryBalanceLoadedMetrics _buildDiaryBalanceLoadedMetrics(
  _DiaryBalanceLoadedContext context,
  DateTime weekStart,
  DiaryBalanceLoadedState state,
  DiaryDailyBalanceMetrics daily,
) {
  return DiaryBalanceLoadedMetrics(
    selectedDay: context.selectedDayOverview.date,
    daily: daily,
    weekly: _resolveWeeklyMetrics(context, weekStart),
    state: state,
    budgetDetails: _resolveBudgetDetails(context, weekStart, state, daily),
  );
}

DateTime _resolveCurrentWeekStartDate(_DiaryBalanceLoadedContext context) =>
    resolveBurnWeekLiveWeekStartDate(
      currentDay: context.selectedDayOverview.date,
      balanceStartDate: context.weekOverview.balanceStartDate,
      storedWeekStartDayKey: context.runState.currentWeekStartDayKey,
    );

DiaryDailyBalanceMetrics _resolveDailyMetrics(
  _DiaryBalanceLoadedContext context,
  DiaryBalanceLoadedState state,
) => resolveDiaryDailyBalanceMetrics(
  flexibleGoalKcal: context.weekOverview.todayFlexibleGoalKcal,
  totalKcal: context.selectedDayOverview.totalKcal,
  goalKcal: context.selectedDayOverview.goalKcal,
  baseGoalKcal: context.selectedDayOverview.baseGoalKcal,
  activitySegmentKcal: 0,
  bufferAdjustmentKcal: context.isLiveDay
      ? context.runState.heartCreditKcal
      : 0,
  heartCreditKcal: context.runState.heartCreditKcal,
  isHeartDay: state.isHeartDay,
);

DiaryWeeklyBalanceMetrics _resolveWeeklyMetrics(
  _DiaryBalanceLoadedContext context,
  DateTime weekStart,
) => resolveDiaryWeeklyBalanceMetrics(
  weekOverview: context.weekOverview,
  selectedDayOverview: context.selectedDayOverview,
  selectedDayEntries: context.selectedDayEntries,
  currentWeekStartDate: weekStart,
  runState: context.runState,
  now: context.now,
);

DiaryDailyBudgetDetailsData _resolveBudgetDetails(
  _DiaryBalanceLoadedContext context,
  DateTime weekStart,
  DiaryBalanceLoadedState state,
  DiaryDailyBalanceMetrics daily,
) => DiaryDailyBudgetDetailsData.from(
  weekOverview: context.weekOverview,
  selectedDayOverview: context.selectedDayOverview,
  metrics: daily,
  isHeartDay: state.isHeartDay,
  carryoverStartDate: weekStart,
);

DiaryBalanceLoadedState _resolveLoadedState(
  _DiaryBalanceLoadedContext context,
) => _resolveDiaryBalanceLoadedState(
  weekOverview: context.weekOverview,
  selectedDayOverview: context.selectedDayOverview,
  runState: context.runState,
  isLiveDay: context.isLiveDay,
);

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
