import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/burn_week_mock_logic.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_live_overview_dialogs.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_live_overview_logic.dart';
import 'package:yamt/features/calories/provider/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'diary_balance_header.dart';
part 'diary_balance_practice_day_card.dart';
part 'diary_balance_progress.dart';
part 'diary_balance_shell.dart';

const _balanceCardRadius = 32.0;
const _balanceProgressHeight = 24.0;
const _balanceFlameIconSize = 24.0;
const _balanceTargetMarkerWidth = 3.0;
const _balanceProgressAreaHeight = 56.0;
const _balanceStatTileHeight = 84.0;
const _balanceGameHeaderHeight = 24.0;
const _balanceCounterBadgeHeight = 22.0;
const _balanceCounterIconSize = 14.0;
const _balanceTickerPeriod = Duration(minutes: 1);

/// Ticker period for minute-sensitive balance UI updates.
final diaryBalanceTickerPeriodProvider = Provider<Duration>(
  (ref) => _balanceTickerPeriod,
);

/// Optional observer for balance ticker tests.
final diaryBalanceTickerObserverProvider = Provider<VoidCallback?>(
  (ref) => null,
);

/// Stable keys for diary balance card tests.
abstract final class DiaryBalanceCardKeys {
  /// Progress track key.
  static const progressTrack = ValueKey<String>(
    'diary-balance-progress-track',
  );

  /// Safe-zone fill key.
  static const safeZone = ValueKey<String>('diary-balance-safe-zone');

  /// Target marker key.
  static const targetMarker = ValueKey<String>(
    'diary-balance-target-marker',
  );

  /// Consumed marker key.
  static const consumedMarker = ValueKey<String>(
    'diary-balance-consumed-marker',
  );

  /// Practice day card key.
  static const practiceDay = ValueKey<String>('diary-balance-practice-day');
}

final FutureProviderFamily<List<CalorieEntry>, DateTime>
_diaryBalanceEntriesForDayProvider =
    FutureProvider.family<List<CalorieEntry>, DateTime>((ref, day) {
      ref.watch(calorieOverviewRevisionProvider);
      return ref
          .watch(calorieLogRepositoryProvider)
          .readEntriesForDay(normalizeDiaryDay(day));
    });

/// Weekly calorie balance card for the diary page.
class DiaryBalanceCard extends ConsumerStatefulWidget {
  /// Creates the diary balance card.
  const DiaryBalanceCard({
    required this.selectedDay,
    required this.hasAutoOpeningWeeklyCheckIn,
    super.key,
  });

  /// The selected diary day.
  final DateTime selectedDay;

  /// Whether weekly check-in is about to open and should own dialogs.
  final bool hasAutoOpeningWeeklyCheckIn;

  @override
  ConsumerState<DiaryBalanceCard> createState() => _DiaryBalanceCardState();
}

class _DiaryBalanceCardState extends ConsumerState<DiaryBalanceCard>
    with
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin<DiaryBalanceCard> {
  CalorieWeekOverview? _lastWeekOverview;
  CalorieWeekDayOverview? _lastSelectedDayOverview;
  Timer? _ticker;
  NavigatorState? _zoneDialogNavigator;
  Route<void>? _zoneDialogRoute;
  var _zoneDialogEpoch = 0;
  bool _isZoneDialogOpen = false;
  BurnWeekZoneStatus _lastZoneStatus = BurnWeekZoneStatus.inside;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTicker();
  }

  @override
  void didUpdateWidget(covariant DiaryBalanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameDiaryDay(oldWidget.selectedDay, widget.selectedDay)) {
      _zoneDialogEpoch += 1;
      _lastZoneStatus = BurnWeekZoneStatus.inside;
      _closeZoneDialog();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTicker();
      if (mounted) {
        setState(() {});
      }
      return;
    }
    _stopTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _closeZoneDialog();
    _stopTicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.watch(burnWeekLiveSyncProvider);

    final isLiveDay = _isLiveDay(widget.selectedDay);
    final weekOverviewState = ref.watch(
      calorieWeekOverviewForWindowProvider(widget.selectedDay),
    );
    final selectedDayState = ref.watch(
      calorieWeekDayOverviewForDateProvider(widget.selectedDay),
    );
    final dayEntriesState = isLiveDay
        ? ref.watch(_diaryBalanceEntriesForDayProvider(widget.selectedDay))
        : null;
    final dayEntries = dayEntriesState?.asData?.value ?? const <CalorieEntry>[];
    final dayEntriesLoaded = !isLiveDay || dayEntriesState?.hasValue == true;
    final runState =
        ref.watch(burnWeekRunControllerProvider).asData?.value ??
        const BurnWeekRunState.initial();
    final weekOverview = weekOverviewState.asData?.value;
    final selectedDayOverview = selectedDayState.asData?.value;

    if (weekOverview != null && selectedDayOverview != null) {
      _lastWeekOverview = weekOverview;
      _lastSelectedDayOverview = selectedDayOverview;

      return _buildLoaded(
        context,
        weekOverview: weekOverview,
        selectedDayOverview: selectedDayOverview,
        selectedDayEntries: dayEntries,
        selectedDayEntriesLoaded: dayEntriesLoaded,
        runState: runState,
        isLiveDay: isLiveDay,
      );
    }

    final lastWeekOverview = _lastWeekOverview;
    final lastSelectedDayOverview = _lastSelectedDayOverview;
    if (!weekOverviewState.hasError &&
        !selectedDayState.hasError &&
        lastWeekOverview != null &&
        lastSelectedDayOverview != null) {
      return _buildLoaded(
        context,
        weekOverview: lastWeekOverview,
        selectedDayOverview: lastSelectedDayOverview,
        selectedDayEntries: dayEntries,
        selectedDayEntriesLoaded: dayEntriesLoaded,
        runState: runState,
        isLiveDay: isLiveDay,
      );
    }

    if (weekOverviewState.hasError || selectedDayState.hasError) {
      final l10n = AppLocalizations.of(context)!;
      return _DiaryBalanceShell(
        child: Text(
          l10n.diaryBalanceLoadFailed,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return const _DiaryBalanceLoading();
  }

  Widget _buildLoaded(
    BuildContext context, {
    required CalorieWeekOverview weekOverview,
    required CalorieWeekDayOverview selectedDayOverview,
    required List<CalorieEntry> selectedDayEntries,
    required bool selectedDayEntriesLoaded,
    required BurnWeekRunState runState,
    required bool isLiveDay,
  }) {
    final colors = Theme.of(context).colorScheme;
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final l10n = AppLocalizations.of(context)!;
    final scheduledRestartDate = _scheduledRestartDate(
      runState: runState,
      today: selectedDayOverview.date,
      isLiveDay: isLiveDay,
    );
    if (scheduledRestartDate != null) {
      return _DiaryBalanceScheduledRestartCard(
        scheduledRestartDate: scheduledRestartDate,
      );
    }
    if (shouldShowDiaryBalancePracticeDayCard(
      weekOverview: weekOverview,
      selectedDay: selectedDayOverview.date,
      isLiveDay: isLiveDay,
    )) {
      return DiaryBalancePracticeDayCard(
        startDate: weekOverview.nextGoalStartDate!,
        futureGoalKcal: weekOverview.futureGoalKcal,
      );
    }
    final currentWeekStartDate = resolveBurnWeekLiveWeekStartDate(
      currentDay: selectedDayOverview.date,
      balanceStartDate: weekOverview.balanceStartDate,
      storedWeekStartDayKey: runState.currentWeekStartDayKey,
    );
    final metrics = _resolveMetrics(
      weekOverview: weekOverview,
      selectedDayOverview: selectedDayOverview,
      selectedDayEntries: selectedDayEntries,
      currentWeekStartDate: currentWeekStartDate,
      runState: runState,
    );
    final dayBudgetKcal = weekOverview.todayFlexibleGoalKcal;
    final dayLeftKcal = dayBudgetKcal - selectedDayOverview.totalKcal;
    final showGameControls = isLiveDay && !weekOverview.goalStartsInFuture;
    final runWeekNumber = isLiveDay
        ? runState.runWeekNumber
        : _resolveSnapshotRunWeekNumber(
            currentDay: selectedDayOverview.date,
            balanceStartDate: weekOverview.balanceStartDate,
          );
    final weekDayLabel = formatBurnWeekLiveWeekDayLabel(
      currentDay: selectedDayOverview.date,
      currentWeekStartDate: currentWeekStartDate,
      runWeekNumber: runWeekNumber,
      l10n: l10n,
    );
    if (showGameControls &&
        selectedDayEntriesLoaded &&
        !widget.hasAutoOpeningWeeklyCheckIn) {
      _queueZoneDialogIfNeeded(metrics: metrics, runState: runState);
    }

    return _DiaryBalanceShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DiaryBalanceGameHeader(
            label: weekDayLabel,
            starCount: showGameControls ? runState.starCount : null,
            heartCount: showGameControls ? runState.heartCount : null,
            onHeartTap: showGameControls && runState.heartCount > 0
                ? () => _showUseHeartDialog(
                    dailyGoalKcal: metrics.dailyGoalKcal,
                    runState: runState,
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          _DiaryBalanceProgressBar(metrics: metrics),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DiaryBalanceScaleLabel('0 ${l10n.caloriesUnitKcal}'),
              _DiaryBalanceScaleLabel(
                _formatKcal(
                  numberFormat,
                  metrics.barMaxKcal,
                  l10n.caloriesUnitKcal,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(
                child: _DiaryBalanceStatTile(
                  label: l10n.diaryBalanceEatenLabel,
                  value: _formatKcal(
                    numberFormat,
                    selectedDayOverview.totalKcal,
                    l10n.caloriesUnitKcal,
                  ),
                  valueColor: const Color(0xFF3A5A78),
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? colors.surfaceContainerLowest
                      : Colors.white,
                  borderColor: Theme.of(context).brightness == Brightness.dark
                      ? colors.outlineVariant
                      : const Color(0xFFCBD5E1),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DiaryBalanceStatTile(
                  label: l10n.diaryBalanceLeftLabel,
                  value: _formatKcal(
                    numberFormat,
                    dayLeftKcal,
                    l10n.caloriesUnitKcal,
                  ),
                  valueColor: dayLeftKcal < 0
                      ? colors.error
                      : const Color(0xFF116B5A),
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF052E2B).withValues(alpha: 0.28)
                      : const Color(0xFFF4FCF9),
                  borderColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF065F46)
                      : const Color(0xFFA1C4B9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BurnWeekMockMetrics _resolveMetrics({
    required CalorieWeekOverview weekOverview,
    required CalorieWeekDayOverview selectedDayOverview,
    required List<CalorieEntry> selectedDayEntries,
    required DateTime currentWeekStartDate,
    required BurnWeekRunState runState,
  }) {
    final weekCarryoverBeforeTodayKcal =
        resolveBurnWeekCarryoverBeforeTodayKcal(
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
    final plannedLaterTodayKcal = _isLiveDay(selectedDayOverview.date)
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

  bool _isLiveDay(DateTime day) {
    return isSameDiaryDay(day, DateTime.now());
  }

  DateTime? _scheduledRestartDate({
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
    await WidgetsBinding.instance.endOfFrame;
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
    if (!mounted ||
        expectedEpoch != _zoneDialogEpoch ||
        widget.hasAutoOpeningWeeklyCheckIn ||
        !_isLiveDay(widget.selectedDay)) {
      return false;
    }
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      return false;
    }
    return true;
  }

  void _rememberZoneDialogRoute(NavigatorState navigator, Route<void> route) {
    _zoneDialogNavigator = navigator;
    _zoneDialogRoute = route;
    if (!_canShowZoneDialogs(_zoneDialogEpoch)) {
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
      await _showRunOverDialog(message: l10n.burnWeekZoneAboveRunOverMessage);
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

  DateTime _referenceNowForDay(DateTime day) {
    final today = normalizeDiaryDay(DateTime.now());
    final normalizedSelectedDay = normalizeDiaryDay(day);
    if (normalizedSelectedDay.isBefore(today)) {
      return DateTime(
        day.year,
        day.month,
        day.day,
        23,
        59,
        59,
      );
    }
    if (normalizedSelectedDay.isAfter(today)) {
      return normalizeDiaryDay(day);
    }

    return DateTime.now();
  }

  String _formatKcal(NumberFormat numberFormat, double value, String unit) {
    return '${numberFormat.format(value.round())} $unit';
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(ref.read(diaryBalanceTickerPeriodProvider), (_) {
      ref.read(diaryBalanceTickerObserverProvider)?.call();
      if (!mounted) {
        _stopTicker();
        return;
      }
      setState(() {});
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
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
