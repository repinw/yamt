import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/application/calorie_resolved_goal_provider.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_provider.dart';
import 'package:yamt/features/calories/application/day_budget.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_balance_loaded_metrics.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_data.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_mappers.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';

part 'diary_balance_provider.g.dart';

/// Resolved card state for the diary balance card.
class DiaryBalanceCardData {
  const new _({this.loadedMetrics, this.scheduledRestart, this.practiceDay});

  /// Creates loaded balance data.
  const new loaded({required DiaryBalanceLoadedMetrics loadedMetrics})
    : this._(loadedMetrics: loadedMetrics);

  /// Creates scheduled restart balance data.
  const new scheduledRestart({
    required DiaryBalanceNotCountingDayData scheduledRestart,
  }) : this._(scheduledRestart: scheduledRestart);

  /// Creates practice day balance data.
  const new practiceDay({required DiaryBalanceNotCountingDayData practiceDay})
    : this._(practiceDay: practiceDay);

  /// Loaded daily metrics.
  final DiaryBalanceLoadedMetrics? loadedMetrics;

  /// A day after the run ended, before the restart on its start date.
  final DiaryBalanceNotCountingDayData? scheduledRestart;

  /// Practice day data, when shown before a future goal starts.
  final DiaryBalanceNotCountingDayData? practiceDay;
}

/// A day that can be tracked but does not count yet: a practice day before
/// a future goal starts, or a day before a scheduled restart.
///
/// It renders like a normal day against [daily], without carryover, so the
/// user keeps tracking while nothing counts.
class DiaryBalanceNotCountingDayData {
  /// Creates the data of a day that does not count yet.
  const new({required this.day, required this.startDate, required this.daily});

  /// Day of the card.
  final DateTime day;

  /// First day that counts.
  final DateTime startDate;

  /// Daily metrics measured against the goal of the day, without carryover.
  final DiaryDailyBalanceMetrics daily;
}

/// Adapter source that hides Calories feature types from diary widgets.
class DiaryBalanceSource {
  const new _({
    required this._weekOverview,
    required this._selectedDayOverview,
    required this._runState,
    required this._carryoverMacroDelta,
    required this._countedPlans,
  });

  /// Creates a balance source from cached dashboard data.
  factory fromDashboardData(DiaryDayDashboardData data) {
    return DiaryBalanceSource._(
      weekOverview: data.weekOverview,
      selectedDayOverview: data.weekOverview.days.last,
      runState: data.runState,
      carryoverMacroDelta: data.carryoverMacroDelta,
      countedPlans: data.countsPlans
          ? data.plannedEntries
          : const <CalorieEntry>[],
    );
  }

  final CalorieWeekOverview _weekOverview;
  final CalorieWeekDayOverview _selectedDayOverview;
  final BurnWeekRunState _runState;
  final DiaryMacroTargets _carryoverMacroDelta;
  final List<CalorieEntry> _countedPlans;

  /// Week overview backing this source.
  CalorieWeekOverview get weekOverview => _weekOverview;

  /// Selected-day overview backing this source.
  CalorieWeekDayOverview get selectedDayOverview => _selectedDayOverview;

  /// Burn Week run state backing this source.
  BurnWeekRunState get runState => _runState;

  /// Resolves render-ready balance card data for [now].
  DiaryBalanceCardData resolve({required DateTime now}) {
    final selectedDay = _selectedDayOverview.date;
    final selectedDayOverview = addDiaryPlansToDay(
      _selectedDayOverview,
      _countedPlans,
    );
    final isLiveDay = isSameLocalDay(selectedDay, now);
    final scheduledRestartDate = resolveDiaryBalanceScheduledRestartDate(
      runState: _runState,
      today: selectedDay,
      isLiveDay: isLiveDay,
    );
    // Both days are tracked against the goal of the day, without carryover.
    DiaryBalanceNotCountingDayData notCounting(DateTime startDate) {
      final goalKcal = dayGoalKcal(_weekOverview);
      return DiaryBalanceNotCountingDayData(
        day: selectedDay,
        startDate: startDate,
        daily: resolveDiaryDailyBalanceMetrics(
          flexibleGoalKcal: goalKcal,
          totalKcal: selectedDayOverview.totalKcal,
          goalKcal: goalKcal,
          baseGoalKcal: goalKcal,
        ),
      );
    }

    if (scheduledRestartDate != null) {
      return DiaryBalanceCardData.scheduledRestart(
        scheduledRestart: notCounting(scheduledRestartDate),
      );
    }

    final practiceStartDate = _weekOverview.nextGoalStartDate;
    if (isPracticeDay(week: _weekOverview, day: selectedDay)) {
      return DiaryBalanceCardData.practiceDay(
        practiceDay: notCounting(practiceStartDate!),
      );
    }

    return DiaryBalanceCardData.loaded(
      loadedMetrics: resolveDiaryBalanceLoadedMetrics(
        weekOverview: _weekOverview,
        selectedDayOverview: selectedDayOverview,
        runState: _runState,
        isLiveDay: isLiveDay,
        now: now,
        carryoverMacroDelta: _carryoverMacroDelta,
      ),
    );
  }
}

/// Actions needed by diary balance presentation widgets.
@riverpod
DiaryBalanceActions diaryBalanceActions(Ref ref) {
  return DiaryBalanceActions(
    refreshBalance: (selectedDay) {
      if (!ref.mounted) {
        return;
      }
      final normalizedSelectedDay = normalizeLocalDay(selectedDay);
      final visibleDays = buildRollingLocalDays(
        anchorDay: normalizedSelectedDay,
      );
      ref
        ..invalidate(resolvedCalorieGoalForDayProvider(normalizedSelectedDay))
        ..invalidate(
          resolvedCalorieGoalsForDaysProvider(
            ResolvedCalorieGoalDaysRequest.fromDays(visibleDays),
          ),
        )
        ..invalidate(
          calorieWeekOverviewForWindowProvider(normalizedSelectedDay),
        );
    },
  );
}

/// Operations that bridge diary balance UI to application state.
class DiaryBalanceActions {
  /// Creates diary balance actions.
  const new({required this._refreshBalance});

  final void Function(DateTime selectedDay) _refreshBalance;

  /// Refreshes the balance source and the Calories adapters it reads.
  void refreshBalance(DateTime selectedDay) {
    _refreshBalance(selectedDay);
  }
}
