import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/burn_week_run_controller.dart';
import 'package:yamt/features/calories/application/calorie_resolved_goal_provider.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_provider.dart';
import 'package:yamt/features/calories/application/daily_nutrition_target_resolver_service.dart';
import 'package:yamt/features/calories/application/day_budget.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_balance_loaded_metrics.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_data.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_mappers.dart';
import 'package:yamt/features/diary/application/diary_entries_provider.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';

part 'diary_balance_provider.g.dart';

/// Resolved card state for the diary balance card.
class DiaryBalanceCardData {
  const new _({
    this.loadedMetrics,
    this.scheduledRestartDate,
    this.practiceDay,
  });

  /// Creates loaded balance data.
  const new loaded({required DiaryBalanceLoadedMetrics loadedMetrics})
    : this._(loadedMetrics: loadedMetrics);

  /// Creates scheduled restart balance data.
  const new scheduledRestart({required DateTime scheduledRestartDate})
    : this._(scheduledRestartDate: scheduledRestartDate);

  /// Creates practice day balance data.
  const new practiceDay({required DiaryBalancePracticeDayData practiceDay})
    : this._(practiceDay: practiceDay);

  /// Loaded daily metrics.
  final DiaryBalanceLoadedMetrics? loadedMetrics;

  /// Scheduled restart date, when shown instead of metrics.
  final DateTime? scheduledRestartDate;

  /// Practice day data, when shown before a future goal starts.
  final DiaryBalancePracticeDayData? practiceDay;
}

/// Practice day state for the diary balance card.
///
/// A practice day renders like a normal day against the goal that starts on
/// [startDate], so the user learns the card before anything counts.
class DiaryBalancePracticeDayData {
  /// Creates practice day data.
  const new({
    required this.startDate,
    required this.futureGoalKcal,
    required this.daily,
  });

  /// First official counting day.
  final DateTime startDate;

  /// Goal that will become active on [startDate].
  final double? futureGoalKcal;

  /// Daily metrics measured against [futureGoalKcal], without carryover.
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
    if (isPracticeDay(week: _weekOverview, day: selectedDay)) {
      final practiceGoalKcal = dayGoalKcal(_weekOverview);
      return DiaryBalanceCardData.practiceDay(
        practiceDay: DiaryBalancePracticeDayData(
          startDate: practiceStartDate!,
          futureGoalKcal: _weekOverview.futureGoalKcal,
          daily: resolveDiaryDailyBalanceMetrics(
            flexibleGoalKcal: practiceGoalKcal,
            totalKcal: selectedDayOverview.totalKcal,
            goalKcal: practiceGoalKcal,
            baseGoalKcal: practiceGoalKcal,
          ),
        ),
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
  final runStateFuture = ref.watch(burnWeekRunControllerProvider.future);
  final nutrition = ref.watch(dailyNutritionTargetResolverProvider);
  final today = ref.watch(diaryTodayProvider);
  final weekOverview = await weekOverviewFuture;
  final runState = await runStateFuture;
  final delta = resolveDayBudget(
    week: weekOverview,
    today: today,
    nutrition: nutrition,
  ).carryoverMacroDelta;

  return DiaryBalanceSource._(
    weekOverview: weekOverview,
    selectedDayOverview: weekOverview.days.last,
    runState: runState,
    // This source reads no plans.
    countedPlans: const <CalorieEntry>[],
    carryoverMacroDelta: DiaryMacroTargets(
      carbs: delta.carbs,
      protein: delta.protein,
      fat: delta.fat,
    ),
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
            ResolvedCalorieGoalDaysRequest.fromDays(visibleDays),
          ),
        )
        ..invalidate(
          calorieWeekOverviewForWindowProvider(normalizedSelectedDay),
        )
        ..invalidate(diaryEntriesForDayProvider(normalizedSelectedDay));
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
