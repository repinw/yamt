import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_resolved_goal_provider.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_balance_loaded_metrics.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_data.dart';
import 'package:yamt/features/diary/application/diary_entries_provider.dart';

part 'diary_balance_provider.g.dart';

/// Resolved card state for the diary balance card.
class DiaryBalanceCardData {
  const DiaryBalanceCardData._({
    this.loadedMetrics,
    this.scheduledRestartDate,
    this.practiceDay,
  });

  /// Creates loaded balance data.
  const DiaryBalanceCardData.loaded({
    required DiaryBalanceLoadedMetrics loadedMetrics,
  }) : this._(loadedMetrics: loadedMetrics);

  /// Creates scheduled restart balance data.
  const DiaryBalanceCardData.scheduledRestart({
    required DateTime scheduledRestartDate,
  }) : this._(scheduledRestartDate: scheduledRestartDate);

  /// Creates practice day balance data.
  const DiaryBalanceCardData.practiceDay({
    required DiaryBalancePracticeDayData practiceDay,
  }) : this._(practiceDay: practiceDay);

  /// Loaded daily and weekly metrics.
  final DiaryBalanceLoadedMetrics? loadedMetrics;

  /// Scheduled restart date, when shown instead of metrics.
  final DateTime? scheduledRestartDate;

  /// Practice day data, when shown before a future goal starts.
  final DiaryBalancePracticeDayData? practiceDay;
}

/// Practice day state for the diary balance card.
class DiaryBalancePracticeDayData {
  /// Creates practice day data.
  const DiaryBalancePracticeDayData({
    required this.startDate,
    required this.futureGoalKcal,
  });

  /// First official counting day.
  final DateTime startDate;

  /// Goal that will become active on [startDate].
  final double? futureGoalKcal;
}

/// Adapter source that hides Calories feature types from diary widgets.
class DiaryBalanceSource {
  const DiaryBalanceSource._({
    required CalorieWeekOverview weekOverview,
    required CalorieWeekDayOverview selectedDayOverview,
    required List<CalorieEntry> selectedDayEntries,
    required BurnWeekRunState runState,
  }) : _weekOverview = weekOverview,
       _selectedDayOverview = selectedDayOverview,
       _selectedDayEntries = selectedDayEntries,
       _runState = runState;

  /// Creates a balance source from cached dashboard data.
  factory DiaryBalanceSource.fromDashboardData(DiaryDayDashboardData data) {
    return DiaryBalanceSource._(
      weekOverview: data.weekOverview,
      selectedDayOverview: data.weekOverview.days.last,
      selectedDayEntries: data.selectedDayEntries,
      runState: data.runState,
    );
  }

  final CalorieWeekOverview _weekOverview;
  final CalorieWeekDayOverview _selectedDayOverview;
  final List<CalorieEntry> _selectedDayEntries;
  final BurnWeekRunState _runState;

  /// Week overview backing this source.
  CalorieWeekOverview get weekOverview => _weekOverview;

  /// Selected-day overview backing this source.
  CalorieWeekDayOverview get selectedDayOverview => _selectedDayOverview;

  /// Selected-day entries backing this source.
  List<CalorieEntry> get selectedDayEntries => _selectedDayEntries;

  /// Burn Week run state backing this source.
  BurnWeekRunState get runState => _runState;

  /// Resolves render-ready balance card data for [now].
  DiaryBalanceCardData resolve({required DateTime now}) {
    final selectedDay = _selectedDayOverview.date;
    final isLiveDay = isSameDiaryDay(selectedDay, now);
    final scheduledRestartDate = resolveDiaryBalanceScheduledRestartDate(
      runState: _runState,
      today: selectedDay,
      isLiveDay: isLiveDay,
    );
    if (scheduledRestartDate != null) {
      return DiaryBalanceCardData.scheduledRestart(
        scheduledRestartDate: scheduledRestartDate,
      );
    }

    final practiceStartDate = _weekOverview.nextGoalStartDate;
    if (shouldShowDiaryBalancePracticeDay(
      goalStartsInFuture: _weekOverview.goalStartsInFuture,
      startDate: practiceStartDate,
      selectedDay: selectedDay,
    )) {
      return DiaryBalanceCardData.practiceDay(
        practiceDay: DiaryBalancePracticeDayData(
          startDate: practiceStartDate!,
          futureGoalKcal: _weekOverview.futureGoalKcal,
        ),
      );
    }

    return DiaryBalanceCardData.loaded(
      loadedMetrics: resolveDiaryBalanceLoadedMetrics(
        weekOverview: _weekOverview,
        selectedDayOverview: _selectedDayOverview,
        selectedDayEntries: _selectedDayEntries,
        runState: _runState,
        isLiveDay: isLiveDay,
        now: now,
      ),
    );
  }
}

/// Provides source data for the diary balance card.
@riverpod
Future<DiaryBalanceSource> diaryBalanceSource(
  Ref ref,
  DateTime selectedDay,
) async {
  final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
  final weekOverviewFuture = ref.watch(
    calorieWeekOverviewForWindowProvider(normalizedSelectedDay).future,
  );
  final selectedDayEntriesFuture = ref.watch(
    diaryEntriesForDayProvider(normalizedSelectedDay).future,
  );
  final runStateFuture = ref.watch(burnWeekRunControllerProvider.future);
  final weekOverview = await weekOverviewFuture;
  final selectedDayEntries = await selectedDayEntriesFuture;
  final runState = await runStateFuture;

  return DiaryBalanceSource._(
    weekOverview: weekOverview,
    selectedDayOverview: weekOverview.days.last,
    selectedDayEntries: selectedDayEntries,
    runState: runState,
  );
}

/// Actions needed by diary balance presentation widgets.
@riverpod
DiaryBalanceActions diaryBalanceActions(Ref ref) {
  return DiaryBalanceActions(
    refreshBalance: (selectedDay) {
      if (!ref.mounted) {
        return;
      }
      final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
      final visibleDays = buildDiaryVisibleDays(
        anchorDay: normalizedSelectedDay,
      );
      ref
        ..invalidate(diaryBalanceSourceProvider(normalizedSelectedDay))
        ..invalidate(resolvedCalorieGoalForDayProvider(normalizedSelectedDay))
        ..invalidate(
          resolvedCalorieGoalsForDaysProvider(
            ResolvedCalorieGoalDaysRequest.fromDays(
              visibleDays,
              forceDetailedActivity: true,
            ),
          ),
        )
        ..invalidate(
          calorieWeekOverviewForWindowProvider(normalizedSelectedDay),
        )
        ..invalidate(diaryEntriesForDayProvider(normalizedSelectedDay));
    },
    unmarkHeartDay: (day) {
      return ref
          .read(burnWeekRunControllerProvider.notifier)
          .unmarkHeartDay(
            day,
          );
    },
  );
}

/// Operations that bridge diary balance UI to application state.
class DiaryBalanceActions {
  /// Creates diary balance actions.
  const DiaryBalanceActions({
    required void Function(DateTime selectedDay) refreshBalance,
    required Future<void> Function(DateTime day) unmarkHeartDay,
  }) : _refreshBalance = refreshBalance,
       _unmarkHeartDay = unmarkHeartDay;

  final void Function(DateTime selectedDay) _refreshBalance;
  final Future<void> Function(DateTime day) _unmarkHeartDay;

  /// Refreshes the balance source and the Calories adapters it reads.
  void refreshBalance(DateTime selectedDay) {
    _refreshBalance(selectedDay);
  }

  /// Removes a heart day mark from the Burn Week run.
  Future<void> unmarkHeartDay(DateTime day) {
    return _unmarkHeartDay(day);
  }
}

/// Whether the diary balance card should show the pre-start practice state.
bool shouldShowDiaryBalancePracticeDay({
  required bool goalStartsInFuture,
  required DateTime? startDate,
  required DateTime selectedDay,
}) {
  if (!goalStartsInFuture || startDate == null) {
    return false;
  }
  return normalizeDiaryDay(selectedDay).isBefore(normalizeDiaryDay(startDate));
}
