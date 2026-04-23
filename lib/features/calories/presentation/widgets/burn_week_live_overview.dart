import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/burn_week_mock_logic.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_live_overview_dialogs.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_live_overview_logic.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_overview_card.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_resolved_goal_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_summary_view_mode_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
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

class _BurnWeekLiveOverviewState extends ConsumerState<BurnWeekLiveOverview> {
  Timer? _ticker;
  ProviderSubscription<CalorieSummaryViewMode>? _summaryModeSubscription;
  NavigatorState? _zoneDialogNavigator;
  Route<void>? _zoneDialogRoute;
  var _dismissZoneDialogs = false;
  var _zoneDialogEpoch = 0;
  bool _isZoneDialogOpen = false;
  BurnWeekZoneStatus _lastZoneStatus = BurnWeekZoneStatus.inside;

  @override
  void initState() {
    super.initState();
    _summaryModeSubscription = ref.listenManual(
      calorieSummaryViewModeControllerProvider,
      (previous, next) {
        _zoneDialogEpoch += 1;
        _dismissZoneDialogs = next != CalorieSummaryViewMode.balance;
        if (!_dismissZoneDialogs) {
          return;
        }
        _closeZoneDialog();
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
    _closeZoneDialog();
    _summaryModeSubscription?.close();
    _ticker?.cancel();
    super.dispose();
  }

  void _queueZoneDialogIfNeeded({
    required BurnWeekMockMetrics metrics,
    required BurnWeekRunState runState,
  }) {
    final expectedEpoch = _zoneDialogEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_canShowZoneDialogs(expectedEpoch)) {
        return;
      }
      unawaited(
        _maybeShowZoneDialog(
          metrics: metrics,
          runState: runState,
          expectedEpoch: expectedEpoch,
        ),
      );
    });
  }

  Future<void> _maybeShowZoneDialog({
    required BurnWeekMockMetrics metrics,
    required BurnWeekRunState runState,
    required int expectedEpoch,
  }) async {
    if (!_canShowZoneDialogs(expectedEpoch)) {
      return;
    }

    final zoneDecision = resolveBurnWeekZoneDecision(metrics);
    if (zoneDecision.status == BurnWeekZoneStatus.inside) {
      _lastZoneStatus = BurnWeekZoneStatus.inside;
      return;
    }
    if (_isZoneDialogOpen || zoneDecision.status == _lastZoneStatus) {
      return;
    }

    _lastZoneStatus = zoneDecision.status;
    _isZoneDialogOpen = true;
    switch (zoneDecision.status) {
      case BurnWeekZoneStatus.below:
        await _showBelowZoneDialog(
          metrics: metrics,
          runState: runState,
          decision: zoneDecision,
        );
      case BurnWeekZoneStatus.above:
        await _showAboveZoneDialog(
          metrics: metrics,
          runState: runState,
          decision: zoneDecision,
        );
      case BurnWeekZoneStatus.inside:
        break;
    }
    _zoneDialogNavigator = null;
    _zoneDialogRoute = null;
    _isZoneDialogOpen = false;
  }

  bool _canShowZoneDialogs(int expectedEpoch) {
    if (!mounted || expectedEpoch != _zoneDialogEpoch) {
      return false;
    }
    return ref.read(calorieSummaryViewModeControllerProvider) ==
        CalorieSummaryViewMode.balance;
  }

  void _rememberZoneDialogRoute(
    NavigatorState navigator,
    Route<void> route,
  ) {
    _zoneDialogNavigator = navigator;
    _zoneDialogRoute = route;
    if (_dismissZoneDialogs || !_canShowZoneDialogs(_zoneDialogEpoch)) {
      _closeZoneDialog();
    }
  }

  void _closeZoneDialog() {
    final navigator = _zoneDialogNavigator;
    final route = _zoneDialogRoute;
    if (navigator == null || route == null) {
      return;
    }
    if (!route.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_zoneDialogNavigator != navigator || _zoneDialogRoute != route) {
          return;
        }
        if (!route.isActive) {
          return;
        }
        navigator.removeRoute(route);
        _zoneDialogNavigator = null;
        _zoneDialogRoute = null;
      });
      return;
    }
    navigator.removeRoute(route);
    _zoneDialogNavigator = null;
    _zoneDialogRoute = null;
  }

  Future<void> _showBelowZoneDialog({
    required BurnWeekMockMetrics metrics,
    required BurnWeekRunState runState,
    required BurnWeekZoneDecision decision,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (decision.type == BurnWeekZoneDecisionType.belowNeedsHeart) {
      if (runState.heartCount <= 0) {
        await _showRunOverDialog(
          message: l10n.burnWeekZoneBelowRunOverMessage,
        );
        return;
      }
      final shouldUseHeart = await showBurnWeekBelowNeedsHeartDialog(
        context,
        onRouteReady: _rememberZoneDialogRoute,
      );
      if (shouldUseHeart == true && mounted) {
        await ref
            .read(burnWeekRunControllerProvider.notifier)
            .usePositiveHeart(metrics.dailyGoalKcal);
        if (mounted) {
          setState(() {
            _lastZoneStatus = BurnWeekZoneStatus.inside;
          });
        }
      }
      return;
    }

    final action = await showBurnWeekBelowRecoverDialog(
      context: context,
      hasHearts: runState.heartCount > 0,
      onRouteReady: _rememberZoneDialogRoute,
    );
    if (!mounted) {
      return;
    }
    if (action == BurnWeekLiveBelowZoneAction.useHeart) {
      await ref
          .read(burnWeekRunControllerProvider.notifier)
          .usePositiveHeart(metrics.dailyGoalKcal);
      if (mounted) {
        setState(() {
          _lastZoneStatus = BurnWeekZoneStatus.inside;
        });
      }
      return;
    }
    await showBurnWeekSimpleDialog(
      context: context,
      title: l10n.burnWeekZoneEatMoreTitle,
      message: l10n.burnWeekZoneEatMoreMessage,
      onRouteReady: _rememberZoneDialogRoute,
    );
  }

  Future<void> _showAboveZoneDialog({
    required BurnWeekMockMetrics metrics,
    required BurnWeekRunState runState,
    required BurnWeekZoneDecision decision,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (decision.type == BurnWeekZoneDecisionType.aboveFastOnly) {
      await showBurnWeekSimpleDialog(
        context: context,
        title: l10n.burnWeekZoneOutOfSafeZoneTitle,
        message: l10n.burnWeekZoneAboveFastMessage,
        onRouteReady: _rememberZoneDialogRoute,
      );
      return;
    }
    if (runState.heartCount <= 0) {
      await _showRunOverDialog(
        message: l10n.burnWeekZoneAboveRunOverMessage,
      );
      return;
    }
    final shouldUseHeart = await showBurnWeekAboveNeedsHeartDialog(
      context,
      onRouteReady: _rememberZoneDialogRoute,
    );
    if (shouldUseHeart == true && mounted) {
      await ref
          .read(burnWeekRunControllerProvider.notifier)
          .useNegativeHeart(metrics.dailyGoalKcal);
      if (mounted) {
        setState(() {
          _lastZoneStatus = BurnWeekZoneStatus.inside;
        });
      }
    }
  }

  Future<void> _showRunOverDialog({required String message}) async {
    final l10n = AppLocalizations.of(context)!;
    await showBurnWeekSimpleDialog(
      context: context,
      title: l10n.burnWeekRunOverTitle,
      message: message,
      onRouteReady: _rememberZoneDialogRoute,
    );
    if (!mounted) {
      return;
    }
    await ref
        .read(burnWeekRunControllerProvider.notifier)
        .restartRunFrom(weekStartDate: nextDiaryDay(DateTime.now()));
  }

  Future<void> _showUseHeartDialog({
    required double dailyGoalKcal,
    required BurnWeekRunState runState,
  }) async {
    if (runState.heartCount <= 0) {
      return;
    }

    final action = await showBurnWeekUseHeartDialog(
      context: context,
      dayKcal: dailyGoalKcal.round(),
    );

    if (!mounted || action == null) {
      return;
    }

    final controller = ref.read(burnWeekRunControllerProvider.notifier);
    switch (action) {
      case BurnWeekLiveHeartAction.add:
        await controller.usePositiveHeart(dailyGoalKcal);
      case BurnWeekLiveHeartAction.remove:
        await controller.useNegativeHeart(dailyGoalKcal);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _lastZoneStatus = BurnWeekZoneStatus.inside;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = normalizeDiaryDay(DateTime.now());
    final weekOverviewState = ref.watch(
      calorieWeekOverviewForWindowProvider(today),
    );
    final todayOverviewState = ref.watch(
      calorieWeekDayOverviewForDateProvider(today),
    );
    final todayEntriesState = ref.watch(_burnWeekEntriesForDayProvider(today));
    final runStateAsync = ref.watch(burnWeekRunControllerProvider);
    final runState =
        runStateAsync.asData?.value ?? const BurnWeekRunState.initial();

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
    final now = DateTime.now();
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
    final storedWeekStartDate = tryParseBurnWeekDayKey(
      runState.currentWeekStartDayKey,
    );
    final hasScheduledRestart =
        storedWeekStartDate != null &&
        storedWeekStartDate.isAfter(todayOverview.date);
    if (hasScheduledRestart) {
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
                      dateFormat.format(storedWeekStartDate),
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
    final difficulty = resolveBurnWeekMockDifficulty(runState.starCount);
    final todayProgress = resolveBurnWeekCurrentDayProgress(now);
    final currentWeekStartDate = resolveBurnWeekLiveWeekStartDate(
      currentDay: todayOverview.date,
      balanceStartDate: weekOverview.balanceStartDate,
      storedWeekStartDayKey: runState.currentWeekStartDayKey,
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
    final weekGuardedBurnKcal = resolveBurnWeekGuardedBurnKcal(
      weekOverview: weekOverview,
      currentWeekStartDate: currentWeekStartDate,
      resolvedGoalStates: resolvedGoalStates,
    );
    final previousWeekOverflowKcal = resolveBurnWeekPreviousOverflowKcal(
      cycleCarryoverBeforeTodayKcal: weekOverview.carryoverBeforeTodayKcal,
      currentWeekCarryoverBeforeTodayKcal: weekCarryoverBeforeTodayKcal,
      runWeekNumber: runState.runWeekNumber,
    );
    final plannedLaterTodayKcal = resolveBurnWeekPlannedLaterTodayKcal(
      todayEntries: todayEntries,
      now: now,
    );
    final metrics = resolveBurnWeekLiveMetrics(
      now: now,
      weekOverview: weekOverview,
      todayOverview: todayOverview,
      currentWeekStartDate: currentWeekStartDate,
      previousWeekOverflowKcal: previousWeekOverflowKcal,
      heartCreditKcal: runState.heartCreditKcal,
      plannedLaterTodayKcal: plannedLaterTodayKcal,
      safeZoneMultiplier: difficulty.safeZoneMultiplier,
    );
    _queueZoneDialogIfNeeded(
      metrics: metrics,
      runState: runState,
    );
    final weekRemainingAfterFoodKcal =
        metrics.weeklyGoalKcal - metrics.consumedKcal;
    final todayBudgetKcal = metrics.dailyGoalKcal * (completedDaysCount + 1);
    const kcalUnit = 'kcal';
    final weekDayLabel = formatBurnWeekLiveWeekDayLabel(
      currentDay: todayOverview.date,
      currentWeekStartDate: currentWeekStartDate,
      runWeekNumber: runState.runWeekNumber,
      l10n: l10n,
    );
    final currentTimeLabel = formatBurnWeekLiveClockTime(now);
    final todayLeftKcal =
        todayBudgetKcal - metrics.consumedKcal - weekGuardedBurnKcal;
    final todayActualKcal = todayOverview.totalKcal - plannedLaterTodayKcal;
    final todayActualText =
        '${numberFormat.format(todayActualKcal.round())} $kcalUnit';
    final todayLeftText =
        '${numberFormat.format(todayLeftKcal.round())} $kcalUnit';
    final actualText =
        '${numberFormat.format(metrics.consumedKcal.round())} $kcalUnit';
    final targetText =
        '${numberFormat.format(metrics.targetKcal.round())} $kcalUnit';
    final dailyGoalText =
        '${numberFormat.format(metrics.dailyGoalKcal.round())} $kcalUnit';
    final weeklyGoalText =
        '${numberFormat.format(metrics.weeklyGoalKcal.round())} $kcalUnit';
    final safeMinText =
        '${numberFormat.format(metrics.safeZoneMinKcal.round())} $kcalUnit';
    final safeMaxText =
        '${numberFormat.format(metrics.safeZoneMaxKcal.round())} $kcalUnit';
    final ratioText = metrics.paceRatio.toStringAsFixed(3);
    final weekRatioText = '${(metrics.paceRatio * 100).round()}% ($ratioText)';
    final targetFormulaText =
        '$dailyGoalText x $completedDaysCount full days + '
        '${(todayProgress * 100).round()}% today = $targetText';
    final weekCarryoverText =
        '${numberFormat.format(weekCarryoverBeforeTodayKcal.round())} '
        '$kcalUnit';
    final weekEatenSoFarText =
        '${numberFormat.format(metrics.consumedKcal.round())} $kcalUnit';
    final plannedLaterTodayText =
        '${numberFormat.format(plannedLaterTodayKcal.round())} $kcalUnit';
    final weekGuardedBurnText = formatBurnWeekBurnedKcal(
      weekGuardedBurnKcal,
      numberFormat,
      kcalUnit,
    );
    final previousWeekOverflowText = formatBurnWeekSignedKcal(
      previousWeekOverflowKcal,
      numberFormat,
      kcalUnit,
    );
    final weekRemainingAfterFoodText =
        '${numberFormat.format(weekRemainingAfterFoodKcal.round())} '
        '$kcalUnit';
    final heartCreditText = formatBurnWeekSignedKcal(
      runState.heartCreditKcal,
      numberFormat,
      kcalUnit,
    );
    final starsHeartsText =
        '${runState.starCount} stars / ${runState.heartCount} hearts';

    return BurnWeekOverviewCard(
      title: weekDayLabel,
      metrics: metrics,
      numberFormat: numberFormat,
      kcalUnit: kcalUnit,
      starCount: runState.starCount,
      heartCount: runState.heartCount,
      onHeartTap: runState.heartCount > 0
          ? () => _showUseHeartDialog(
              dailyGoalKcal: metrics.dailyGoalKcal,
              runState: runState,
            )
          : null,
      onInfoPressed: () {
        unawaited(
          showBurnWeekDetailsDialog(
            context: context,
            data: BurnWeekLiveDetailsData(
              actualText: actualText,
              targetText: targetText,
              dailyGoalText: dailyGoalText,
              weeklyGoalText: weeklyGoalText,
              currentTimeLabel: currentTimeLabel,
              weekRatioText: weekRatioText,
              targetFormulaText: targetFormulaText,
              weekEatenSoFarText: weekEatenSoFarText,
              plannedLaterTodayText: plannedLaterTodayText,
              weekGuardedBurnText: weekGuardedBurnText,
              weekCarryoverText: weekCarryoverText,
              previousWeekOverflowText: previousWeekOverflowText,
              weekRemainingAfterFoodText: weekRemainingAfterFoodText,
              safeMinText: safeMinText,
              safeMaxText: safeMaxText,
              starsHeartsText: starsHeartsText,
              heartCreditText: heartCreditText,
            ),
          ),
        );
      },
      infoTooltip: l10n.burnWeekInfoTooltip,
      primaryStat: BurnWeekOverviewStatData(
        title: l10n.burnWeekStatEaten.toUpperCase(),
        value: todayActualText,
        borderColor: colors.tertiary,
      ),
      secondaryStat: BurnWeekOverviewStatData(
        title: l10n.burnWeekStatTodayLeft.toUpperCase(),
        value: todayLeftText,
        borderColor: todayLeftKcal < 0 ? colors.error : colors.primary,
      ),
    );
  }
}
