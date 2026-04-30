import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/burn_week_mock_logic.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_live_overview_dialogs.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_live_overview_logic.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_overview_card.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_zone_dialog_host.dart';
import 'package:yamt/features/calories/provider/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_resolved_goal_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_summary_view_mode_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Live Burn Week overview backed by real diary data.
class BurnWeekLiveOverview extends ConsumerStatefulWidget {
  /// Creates live Burn Week overview.
  const BurnWeekLiveOverview({super.key});

  @override
  ConsumerState<BurnWeekLiveOverview> createState() {
    return _BurnWeekLiveOverviewState();
  }
}

// Keep this local provider lightweight here because only Burn live overview
// needs raw same-day entries for shadow/pre-logging math.
// ignore: specify_nonobvious_property_types
final _burnWeekEntriesForDayProvider =
    FutureProvider.family<List<CalorieEntry>, DateTime>((ref, day) {
      ref.watch(calorieOverviewRevisionProvider);
      return ref.watch(calorieLogRepositoryProvider).readEntriesForDay(day);
    });

class _BurnWeekLiveOverviewState extends ConsumerState<BurnWeekLiveOverview>
    with BurnWeekZoneDialogHost<BurnWeekLiveOverview> {
  Timer? _ticker;
  ProviderSubscription<CalorieSummaryViewMode>? _summaryModeSubscription;

  @override
  void initState() {
    super.initState();
    _summaryModeSubscription = ref.listenManual(
      calorieSummaryViewModeControllerProvider,
      (previous, next) {
        invalidateBurnWeekZoneDialogs();
        if (next == CalorieSummaryViewMode.balance) {
          return;
        }
        closeBurnWeekZoneDialog();
      },
    );
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    closeBurnWeekZoneDialog();
    _summaryModeSubscription?.close();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  bool get canShowBurnWeekZoneDialogs {
    return ref.read(calorieSummaryViewModeControllerProvider) ==
        CalorieSummaryViewMode.balance;
  }

  @override
  Widget build(BuildContext context) {
    final displayMode = _BurnWeekDisplayMode.fromSelection(
      wallNow: DateTime.now(),
      selectedDay: ref.watch(calorieDayControllerProvider),
    );
    if (displayMode.isLive) {
      ref.watch(burnWeekLiveSyncProvider);
    }
    final weekOverviewState = ref.watch(
      calorieWeekOverviewForWindowProvider(displayMode.day),
    );
    final todayOverviewState = ref.watch(
      calorieWeekDayOverviewForDateProvider(displayMode.day),
    );
    final todayEntriesState = ref.watch(
      _burnWeekEntriesForDayProvider(displayMode.day),
    );
    final runStateAsync = ref.watch(burnWeekRunControllerProvider);
    final runState =
        runStateAsync.asData?.value ?? const BurnWeekRunState.initial();
    final weeklyCheckInState = ref.watch(calorieWeeklyCheckInViewModelProvider);
    final hasAutoOpeningWeeklyCheckIn =
        displayMode.isLive && _hasAutoOpeningWeeklyCheckIn(weeklyCheckInState);

    final weekOverview = weekOverviewState.value;
    final todayOverview = todayOverviewState.value;
    final todayEntries = todayEntriesState.asData?.value;
    if (weekOverview == null || todayOverview == null || todayEntries == null) {
      return const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final resolvedGoalStates = weekOverview.days
        .map((day) => ref.watch(resolvedCalorieGoalForDayProvider(day.date)))
        .toList(growable: false);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final l10n = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat.decimalPattern(locale);
    final colors = Theme.of(context).colorScheme;
    if (weekOverview.goalStartsInFuture &&
        weekOverview.nextGoalStartDate != null) {
      final dateFormat = DateFormat.yMMMd(locale);
      final futureGoalText = weekOverview.futureGoalKcal == null
          ? null
          : '${l10n.caloriesGoalLabel}: '
                '${numberFormat.format(weekOverview.futureGoalKcal!.round())} '
                'kcal';
      return SizedBox(
        height: 280,
        child: Card(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.burnWeekPracticeDayTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.burnWeekPracticeDayMessage(
                      dateFormat.format(weekOverview.nextGoalStartDate!),
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (futureGoalText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      futureGoalText,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }
    final scheduledRestartDate = displayMode.scheduledRestartDate(
      runState: runState,
      today: todayOverview.date,
    );
    if (scheduledRestartDate != null) {
      final dateFormat = DateFormat.yMMMd(locale);
      return SizedBox(
        height: 280,
        child: Card(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.burnWeekRunOverTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.burnWeekRunRestartsOn(
                      dateFormat.format(scheduledRestartDate),
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final overviewViewModel = displayMode.isSnapshot
        ? _BurnWeekOverviewViewModel.fromSnapshot(
            mode: displayMode,
            weekOverview: weekOverview,
            todayOverview: todayOverview,
            todayEntries: todayEntries,
            resolvedGoalStates: resolvedGoalStates,
            l10n: l10n,
            numberFormat: numberFormat,
            colors: colors,
          )
        : _BurnWeekOverviewViewModel.fromLive(
            mode: displayMode,
            runState: runState,
            weekOverview: weekOverview,
            todayOverview: todayOverview,
            todayEntries: todayEntries,
            resolvedGoalStates: resolvedGoalStates,
            l10n: l10n,
            numberFormat: numberFormat,
            colors: colors,
          );
    if (overviewViewModel.shouldQueueZoneDialog) {
      queueBurnWeekZoneDialogIfNeeded(
        metrics: overviewViewModel.metrics,
        runState: runState,
        shouldSkip: () => hasAutoOpeningWeeklyCheckIn,
      );
    }

    return BurnWeekOverviewCard(
      title: overviewViewModel.title,
      metrics: overviewViewModel.metrics,
      numberFormat: numberFormat,
      kcalUnit: overviewViewModel.kcalUnit,
      starCount: overviewViewModel.starCount,
      heartCount: overviewViewModel.heartCount,
      onHeartTap: overviewViewModel.canUseHeart
          ? () => showBurnWeekZoneUseHeartDialog(
              dailyGoalKcal: overviewViewModel.metrics.dailyGoalKcal,
              runState: runState,
            )
          : null,
      onInfoPressed: () {
        unawaited(
          showBurnWeekDetailsDialog(
            context: context,
            data: overviewViewModel.detailsData,
          ),
        );
      },
      infoTooltip: l10n.burnWeekInfoTooltip,
      primaryStat: overviewViewModel.primaryStat,
      secondaryStat: overviewViewModel.secondaryStat,
    );
  }
}

bool _hasAutoOpeningWeeklyCheckIn(
  AsyncValue<CalorieWeeklyCheckInViewModel> state,
) {
  final viewModel = state.asData?.value;
  return state.isLoading ||
      (viewModel?.pendingWeeklyCheckIn != null &&
          viewModel?.shouldAutoOpen == true);
}

class _BurnWeekDisplayMode {
  const _BurnWeekDisplayMode._({
    required this.day,
    required this.now,
    required this.isSnapshot,
  });

  factory _BurnWeekDisplayMode.fromSelection({
    required DateTime wallNow,
    required DateTime selectedDay,
  }) {
    final liveToday = normalizeDiaryDay(wallNow);
    final displayDay = normalizeDiaryDay(selectedDay);
    final isSnapshot = displayDay.isBefore(liveToday);
    final day = isSnapshot ? displayDay : liveToday;
    return _BurnWeekDisplayMode._(
      day: day,
      now: isSnapshot ? _snapshotEndOfDay(day) : wallNow,
      isSnapshot: isSnapshot,
    );
  }

  final DateTime day;
  final DateTime now;
  final bool isSnapshot;

  bool get isLive => !isSnapshot;

  DateTime? scheduledRestartDate({
    required BurnWeekRunState runState,
    required DateTime today,
  }) {
    if (isSnapshot) {
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
}

class _BurnWeekOverviewViewModel {
  const _BurnWeekOverviewViewModel({
    required this.title,
    required this.metrics,
    required this.detailsData,
    required this.primaryStat,
    required this.secondaryStat,
    required this.starCount,
    required this.heartCount,
    required this.canUseHeart,
    required this.shouldQueueZoneDialog,
  });

  factory _BurnWeekOverviewViewModel.fromLive({
    required _BurnWeekDisplayMode mode,
    required BurnWeekRunState runState,
    required CalorieWeekOverview weekOverview,
    required CalorieWeekDayOverview todayOverview,
    required List<CalorieEntry> todayEntries,
    required List<AsyncValue<ResolvedCalorieGoalData>> resolvedGoalStates,
    required AppLocalizations l10n,
    required NumberFormat numberFormat,
    required ColorScheme colors,
  }) {
    return _BurnWeekOverviewViewModel._resolve(
      mode: mode,
      weekOverview: weekOverview,
      todayOverview: todayOverview,
      todayEntries: todayEntries,
      resolvedGoalStates: resolvedGoalStates,
      l10n: l10n,
      numberFormat: numberFormat,
      colors: colors,
      runWeekNumber: runState.runWeekNumber,
      storedWeekStartDayKey: runState.currentWeekStartDayKey,
      difficultyStarCount: runState.starCount,
      displayStarCount: runState.starCount,
      displayHeartCount: runState.heartCount,
      heartCreditKcal: runState.heartCreditKcal,
      todayProgress: resolveBurnWeekCurrentDayProgress(mode.now),
      secondaryStatTitle: l10n.burnWeekStatTodayLeft,
      shouldQueueZoneDialog: true,
    );
  }

  factory _BurnWeekOverviewViewModel.fromSnapshot({
    required _BurnWeekDisplayMode mode,
    required CalorieWeekOverview weekOverview,
    required CalorieWeekDayOverview todayOverview,
    required List<CalorieEntry> todayEntries,
    required List<AsyncValue<ResolvedCalorieGoalData>> resolvedGoalStates,
    required AppLocalizations l10n,
    required NumberFormat numberFormat,
    required ColorScheme colors,
  }) {
    return _BurnWeekOverviewViewModel._resolve(
      mode: mode,
      weekOverview: weekOverview,
      todayOverview: todayOverview,
      todayEntries: todayEntries,
      resolvedGoalStates: resolvedGoalStates,
      l10n: l10n,
      numberFormat: numberFormat,
      colors: colors,
      runWeekNumber: _resolveSnapshotRunWeekNumber(
        currentDay: todayOverview.date,
        balanceStartDate: weekOverview.balanceStartDate,
      ),
      storedWeekStartDayKey: null,
      difficultyStarCount: 0,
      displayStarCount: null,
      displayHeartCount: null,
      heartCreditKcal: 0,
      todayProgress: 1,
      secondaryStatTitle: l10n.burnWeekStatDayLeft,
      shouldQueueZoneDialog: false,
    );
  }

  factory _BurnWeekOverviewViewModel._resolve({
    required _BurnWeekDisplayMode mode,
    required CalorieWeekOverview weekOverview,
    required CalorieWeekDayOverview todayOverview,
    required List<CalorieEntry> todayEntries,
    required List<AsyncValue<ResolvedCalorieGoalData>> resolvedGoalStates,
    required AppLocalizations l10n,
    required NumberFormat numberFormat,
    required ColorScheme colors,
    required int runWeekNumber,
    required String? storedWeekStartDayKey,
    required int difficultyStarCount,
    required int? displayStarCount,
    required int? displayHeartCount,
    required double heartCreditKcal,
    required double todayProgress,
    required String secondaryStatTitle,
    required bool shouldQueueZoneDialog,
  }) {
    const kcalUnit = 'kcal';
    final difficulty = resolveBurnWeekMockDifficulty(difficultyStarCount);
    final currentWeekStartDate = resolveBurnWeekLiveWeekStartDate(
      currentDay: todayOverview.date,
      balanceStartDate: weekOverview.balanceStartDate,
      storedWeekStartDayKey: storedWeekStartDayKey,
    );
    final completedDaysCount = weekOverview.days
        .where(
          (day) =>
              !isBeforeBurnWeekDay(day.date, currentWeekStartDate) &&
              isBeforeBurnWeekDay(day.date, todayOverview.date),
        )
        .length;
    final weekCarryoverBeforeTodayKcal =
        resolveBurnWeekCarryoverBeforeTodayKcal(
          weekOverview: weekOverview,
          currentWeekStartDate: currentWeekStartDate,
          today: todayOverview.date,
        );
    final weekActivityBonusKcal = resolveBurnWeekActivityBonusKcal(
      weekOverview: weekOverview,
      currentWeekStartDate: currentWeekStartDate,
      resolvedGoalStates: resolvedGoalStates,
    );
    final previousWeekOverflowKcal = resolveBurnWeekPreviousOverflowKcal(
      cycleCarryoverBeforeTodayKcal: weekOverview.carryoverBeforeTodayKcal,
      currentWeekCarryoverBeforeTodayKcal: weekCarryoverBeforeTodayKcal,
      runWeekNumber: runWeekNumber,
    );
    final plannedLaterTodayKcal = resolveBurnWeekPlannedLaterTodayKcal(
      todayEntries: todayEntries,
      now: mode.now,
    );
    final metrics = resolveBurnWeekLiveMetrics(
      now: mode.now,
      weekOverview: weekOverview,
      todayOverview: todayOverview,
      currentWeekStartDate: currentWeekStartDate,
      previousWeekOverflowKcal: previousWeekOverflowKcal,
      heartCreditKcal: heartCreditKcal,
      plannedLaterTodayKcal: plannedLaterTodayKcal,
      safeZoneMultiplier: difficulty.safeZoneMultiplier,
    );
    final fullDayBudget = _resolveFullDayBudget(
      weekOverview: weekOverview,
      todayOverview: todayOverview,
      resolvedGoalStates: resolvedGoalStates,
    );
    final todayLeftKcal = fullDayBudget.remainingKcal;
    final todayActualKcal = todayOverview.totalKcal - plannedLaterTodayKcal;
    final todayActualText = _formatKcal(
      todayActualKcal,
      numberFormat,
      kcalUnit,
    );
    final todayLeftText = _formatKcal(todayLeftKcal, numberFormat, kcalUnit);
    final dailyGoalText = _formatKcal(
      metrics.dailyGoalKcal,
      numberFormat,
      kcalUnit,
    );
    final targetText = _formatKcal(metrics.targetKcal, numberFormat, kcalUnit);
    final ratioText = metrics.paceRatio.toStringAsFixed(3);
    final detailsData = BurnWeekLiveDetailsData(
      actualText: _formatKcal(metrics.consumedKcal, numberFormat, kcalUnit),
      targetText: targetText,
      dailyGoalText: dailyGoalText,
      weeklyGoalText: _formatKcal(
        metrics.weeklyGoalKcal,
        numberFormat,
        kcalUnit,
      ),
      currentTimeLabel: formatBurnWeekLiveClockTime(mode.now),
      weekRatioText: '${(metrics.paceRatio * 100).round()}% ($ratioText)',
      targetFormulaText:
          '$dailyGoalText x $completedDaysCount full days + '
          '${(todayProgress * 100).round()}% today = $targetText',
      weekEatenSoFarText: _formatKcal(
        metrics.consumedKcal,
        numberFormat,
        kcalUnit,
      ),
      plannedLaterTodayText: _formatKcal(
        plannedLaterTodayKcal,
        numberFormat,
        kcalUnit,
      ),
      todayBudgetText: _formatKcal(
        fullDayBudget.goalKcal,
        numberFormat,
        kcalUnit,
      ),
      todayFoodText: _formatKcal(
        todayOverview.totalKcal,
        numberFormat,
        kcalUnit,
      ),
      todayLeftText: todayLeftText,
      weekActivityBonusText: formatBurnWeekSignedKcal(
        weekActivityBonusKcal,
        numberFormat,
        kcalUnit,
      ),
      weekCarryoverText: _formatKcal(
        weekCarryoverBeforeTodayKcal,
        numberFormat,
        kcalUnit,
      ),
      previousWeekOverflowText: formatBurnWeekSignedKcal(
        previousWeekOverflowKcal,
        numberFormat,
        kcalUnit,
      ),
      weekRemainingAfterFoodText: _formatKcal(
        metrics.weeklyGoalKcal - metrics.consumedKcal,
        numberFormat,
        kcalUnit,
      ),
      safeMinText: _formatKcal(
        metrics.safeZoneMinKcal,
        numberFormat,
        kcalUnit,
      ),
      safeMaxText: _formatKcal(
        metrics.safeZoneMaxKcal,
        numberFormat,
        kcalUnit,
      ),
      starsHeartsText: displayStarCount == null || displayHeartCount == null
          ? '-'
          : '$displayStarCount stars / $displayHeartCount hearts',
      heartCreditText: formatBurnWeekSignedKcal(
        heartCreditKcal,
        numberFormat,
        kcalUnit,
      ),
    );
    return _BurnWeekOverviewViewModel(
      title: formatBurnWeekLiveWeekDayLabel(
        currentDay: todayOverview.date,
        currentWeekStartDate: currentWeekStartDate,
        runWeekNumber: runWeekNumber,
        l10n: l10n,
      ),
      metrics: metrics,
      detailsData: detailsData,
      primaryStat: BurnWeekOverviewStatData(
        title: l10n.burnWeekStatEaten.toUpperCase(),
        value: todayActualText,
        borderColor: colors.tertiary,
      ),
      secondaryStat: BurnWeekOverviewStatData(
        title: secondaryStatTitle.toUpperCase(),
        value: todayLeftText,
        borderColor: todayLeftKcal < 0 ? colors.error : colors.primary,
      ),
      starCount: displayStarCount,
      heartCount: displayHeartCount,
      canUseHeart: displayHeartCount != null && displayHeartCount > 0,
      shouldQueueZoneDialog: shouldQueueZoneDialog,
    );
  }

  final String title;
  final BurnWeekMockMetrics metrics;
  final BurnWeekLiveDetailsData detailsData;
  final BurnWeekOverviewStatData primaryStat;
  final BurnWeekOverviewStatData secondaryStat;
  final int? starCount;
  final int? heartCount;
  final bool canUseHeart;
  final bool shouldQueueZoneDialog;
  String get kcalUnit => 'kcal';
}

CalorieClassicBudgetBreakdown _resolveFullDayBudget({
  required CalorieWeekOverview weekOverview,
  required CalorieWeekDayOverview todayOverview,
  required List<AsyncValue<ResolvedCalorieGoalData>> resolvedGoalStates,
}) {
  final todayResolvedGoal = _resolvedGoalForDay(
    weekOverview: weekOverview,
    resolvedGoalStates: resolvedGoalStates,
    day: todayOverview.date,
  );
  return CalorieBudgetCalculator.calculateFullDayBudget(
    storedGoalKcal: todayResolvedGoal?.storedGoalKcal ?? todayOverview.goalKcal,
    activityDeltaKcal: todayResolvedGoal?.activityDeltaKcal ?? 0,
    carryoverKcal: weekOverview.carryoverBeforeTodayKcal,
    consumedKcal: todayOverview.totalKcal,
  );
}

String _formatKcal(
  double value,
  NumberFormat numberFormat,
  String kcalUnit,
) {
  return '${numberFormat.format(value.round())} $kcalUnit';
}

DateTime _snapshotEndOfDay(DateTime day) {
  return nextDiaryDay(day).subtract(const Duration(microseconds: 1));
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

ResolvedCalorieGoalData? _resolvedGoalForDay({
  required CalorieWeekOverview weekOverview,
  required List<AsyncValue<ResolvedCalorieGoalData>> resolvedGoalStates,
  required DateTime day,
}) {
  for (var index = 0; index < weekOverview.days.length; index += 1) {
    if (!isSameDiaryDay(weekOverview.days[index].date, day)) {
      continue;
    }
    return resolvedGoalStates[index].asData?.value;
  }
  return null;
}
