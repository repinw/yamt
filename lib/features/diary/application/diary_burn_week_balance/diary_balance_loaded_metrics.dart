import 'package:yamt/features/calories/application/burn_week_live_window_logic.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/diary_day_status.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_budget_details_data.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';

/// Derived values needed to render the loaded Burn Week balance card.
class DiaryBalanceLoadedMetrics {
  /// Creates resolved loaded-card metrics.
  const new({
    required this.selectedDay,
    required this.daily,
    required this.state,
    this.budgetDetails,
    this.previousDayCarryoverKcal,
    this.isPreviousDayClosed = false,
  });

  /// Date represented by the selected-day overview.
  final DateTime selectedDay;

  /// Derived values for the daily card.
  final DiaryDailyBalanceMetrics daily;

  /// Loaded card display state.
  final DiaryBalanceLoadedState state;

  /// Detailed budget and carryover breakdown for the selected day.
  final DiaryDailyBudgetDetailsData? budgetDetails;

  /// Carryover per day the selected day gets from closing the day before.
  /// Set only on tomorrow, while its run has earlier days.
  final double? previousDayCarryoverKcal;

  /// Whether the day before is closed, so the selected day counts like a
  /// started day instead of a plan.
  final bool isPreviousDayClosed;
}

/// Loaded card display state that is not specific to the daily metrics.
class DiaryBalanceLoadedState {
  /// Creates loaded-card display state.
  const new({
    required this.isPauseDay,
    required this.showGameControls,
    required this.runWeekNumber,
  });

  /// Whether the selected day is currently marked as a pause day.
  final bool isPauseDay;

  /// Whether Burn Week game controls should be visible.
  final bool showGameControls;

  /// Run week number to display for the selected day.
  final int runWeekNumber;
}

typedef _DiaryBalanceLoadedContext = ({
  CalorieWeekOverview weekOverview,
  CalorieWeekDayOverview selectedDayOverview,
  BurnWeekRunState runState,
  bool isLiveDay,
  DateTime now,
  DiaryMacroTargets carryoverMacroDelta,
});

/// Resolves all derived values for a loaded Burn Week balance card.
DiaryBalanceLoadedMetrics resolveDiaryBalanceLoadedMetrics({
  required CalorieWeekOverview weekOverview,
  required CalorieWeekDayOverview selectedDayOverview,
  required BurnWeekRunState runState,
  required bool isLiveDay,
  required DateTime now,
  required DiaryMacroTargets carryoverMacroDelta,
}) {
  final context = (
    weekOverview: weekOverview,
    selectedDayOverview: selectedDayOverview,
    runState: runState,
    isLiveDay: isLiveDay,
    now: now,
    carryoverMacroDelta: carryoverMacroDelta,
  );
  return _resolveDiaryBalanceLoadedMetrics(context);
}

DiaryBalanceLoadedMetrics _resolveDiaryBalanceLoadedMetrics(
  _DiaryBalanceLoadedContext context,
) {
  final weekStart = _resolveCurrentWeekStartDate(context);
  final state = _resolveLoadedState(context);
  final daily = _resolveDailyMetrics(context);
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
    state: state,
    budgetDetails: _resolveBudgetDetails(context, weekStart, state, daily),
    previousDayCarryoverKcal: context.weekOverview.previousDayCarryoverKcal,
    isPreviousDayClosed: context.weekOverview.isPreviousDayClosed,
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
) => resolveDiaryDailyBalanceMetrics(
  flexibleGoalKcal: context.weekOverview.todayFlexibleGoalKcal,
  totalKcal: context.selectedDayOverview.totalKcal,
  goalKcal: context.selectedDayOverview.goalKcal,
  baseGoalKcal: context.selectedDayOverview.goalKcal,
);

/// The days before a future day are not finished, so a future day has no
/// carryover to explain and no budget details, unless the day before it is
/// closed.
DiaryDailyBudgetDetailsData? _resolveBudgetDetails(
  _DiaryBalanceLoadedContext context,
  DateTime weekStart,
  DiaryBalanceLoadedState state,
  DiaryDailyBalanceMetrics daily,
) =>
    DiaryDayStatus.of(
      day: context.selectedDayOverview.date,
      today: context.now,
      isPreviousDayClosed: context.weekOverview.isPreviousDayClosed,
    ).isPlanned
    ? null
    : DiaryDailyBudgetDetailsData.from(
        weekOverview: context.weekOverview,
        selectedDayOverview: context.selectedDayOverview,
        metrics: daily,
        isPauseDay: state.isPauseDay,
        carryoverStartDate: weekStart,
        carryoverMacroDelta: context.carryoverMacroDelta,
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
    isPauseDay: selectedDayOverview.isPauseDay,
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
