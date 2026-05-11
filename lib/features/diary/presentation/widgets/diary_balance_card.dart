import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/burn_week_mock_logic.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_live_overview_logic.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_zone_dialog_host.dart';
import 'package:yamt/features/calories/provider/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_card_helpers.dart';
import 'package:yamt/features/diary/provider/diary_entries_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'diary_balance_header.dart';
part 'diary_balance_practice_day_card.dart';
part 'diary_balance_progress.dart';
part 'diary_balance_shell.dart';

const _balanceCardRadius = 32.0;
const _balanceProgressHeight = 30.0;
const _balanceFlameIconSize = 24.0;
const _balanceTargetMarkerWidth = 3.0;
const _balanceProgressAreaHeight = 62.0;
const _balanceSafeZoneVerticalInset = 4.0;
const _balanceTargetMarkerOverflowTop = 8.0;
const _balanceStatTileHeight = 104.0;
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

  /// Retry button key.
  static const retryButton = ValueKey<String>('diary-balance-retry-button');
}

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
        AutomaticKeepAliveClientMixin<DiaryBalanceCard>,
        BurnWeekZoneDialogHost<DiaryBalanceCard> {
  CalorieWeekOverview? _lastWeekOverview;
  Timer? _ticker;

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
      resetBurnWeekZoneDialogs();
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
    closeBurnWeekZoneDialog();
    _stopTicker();
    super.dispose();
  }

  @override
  bool get canShowBurnWeekZoneDialogs {
    return !widget.hasAutoOpeningWeeklyCheckIn &&
        _isLiveDay(widget.selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.watch(burnWeekLiveSyncProvider);

    final normalizedSelectedDay = normalizeDiaryDay(widget.selectedDay);
    final isLiveDay = _isLiveDay(widget.selectedDay);
    final weekOverviewState = ref.watch(
      calorieWeekOverviewForWindowProvider(normalizedSelectedDay),
    );
    final dayEntriesState = isLiveDay
        ? ref.watch(diaryEntriesForDayProvider(normalizedSelectedDay))
        : null;
    final dayEntries = dayEntriesState?.value ?? const <CalorieEntry>[];
    final dayEntriesLoaded = !isLiveDay || dayEntriesState?.hasValue == true;
    final runState =
        ref.watch(burnWeekRunControllerProvider).value ??
        const BurnWeekRunState.initial();
    final weekOverview = weekOverviewState.value;

    if (weekOverview != null) {
      final selectedDayOverview = weekOverview.days.last;
      _lastWeekOverview = weekOverview;

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
    if (!weekOverviewState.hasError && lastWeekOverview != null) {
      return _buildLoaded(
        context,
        weekOverview: lastWeekOverview,
        selectedDayOverview: lastWeekOverview.days.last,
        selectedDayEntries: dayEntries,
        selectedDayEntriesLoaded: dayEntriesLoaded,
        runState: runState,
        isLiveDay: isLiveDay,
      );
    }

    final hasError =
        weekOverviewState.hasError || dayEntriesState?.hasError == true;
    if (hasError) {
      final l10n = AppLocalizations.of(context)!;
      return _DiaryBalanceShell(
        child: DiaryErrorRetryContent(
          message: l10n.diaryBalanceLoadFailed,
          retryLabel: l10n.caloriesRetryAction,
          retryButtonKey: DiaryBalanceCardKeys.retryButton,
          onRetry: () => _retryBalance(normalizedSelectedDay),
        ),
      );
    }

    return const _DiaryBalanceLoading();
  }

  void _retryBalance(DateTime normalizedSelectedDay) {
    ref
      ..invalidate(calorieWeekOverviewForWindowProvider(normalizedSelectedDay))
      ..invalidate(diaryEntriesForDayProvider(normalizedSelectedDay));
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
      Localizations.localeOf(context).toLanguageTag(),
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
    final realDayLeftKcal = dayBudgetKcal - selectedDayOverview.totalKcal;
    final bufferAdjustmentKcal = isLiveDay ? runState.heartCreditKcal : 0.0;
    final eatenKcal = math.max<double>(
      0,
      selectedDayOverview.totalKcal + bufferAdjustmentKcal,
    );
    final eatenSubtitle = bufferAdjustmentKcal.round() == 0
        ? null
        : '${l10n.diaryBalanceRealEatenLabel(
            _formatKcal(
              numberFormat,
              selectedDayOverview.totalKcal,
              l10n.caloriesUnitKcal,
            ),
          )} · ${l10n.diaryBalanceBufferAdjustmentLabel(
            formatBurnWeekSignedKcal(
              bufferAdjustmentKcal,
              numberFormat,
              l10n.caloriesUnitKcal,
            ),
          )}';
    final bufferAdjustmentLabel = l10n.diaryBalanceBufferAdjustmentLabel(
      formatBurnWeekSignedKcal(
        bufferAdjustmentKcal,
        numberFormat,
        l10n.caloriesUnitKcal,
      ),
    );
    final heartAdjustmentKcal = -runState.heartCreditKcal;
    final isHeartDay = runState.isHeartDay(selectedDayOverview.date);
    final canRevertHeartDay = runState.canUnmarkHeartDay(
      selectedDayOverview.date,
    );
    final dayLeftKcal = isHeartDay
        ? 0.0
        : realDayLeftKcal + heartAdjustmentKcal;
    final leftSubtitle = heartAdjustmentKcal.round() == 0
        ? null
        : '${l10n.diaryBalanceRealLeftLabel(
            _formatKcal(numberFormat, realDayLeftKcal, l10n.caloriesUnitKcal),
          )} · ${l10n.diaryBalanceHeartAdjustmentLabel(
            formatBurnWeekSignedKcal(
              heartAdjustmentKcal,
              numberFormat,
              l10n.caloriesUnitKcal,
            ),
          )}';
    final resolvedLeftSubtitle = isHeartDay
        ? l10n.diaryBalanceHeartDaySubtitle
        : leftSubtitle;
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
    final weekDayLabel = formatBurnWeekLiveWeekDayLabel(
      currentDay: selectedDayOverview.date,
      currentWeekStartDate: currentWeekStartDate,
      runWeekNumber: runWeekNumber,
      l10n: l10n,
    );
    if (showGameControls &&
        selectedDayEntriesLoaded &&
        !widget.hasAutoOpeningWeeklyCheckIn &&
        !isHeartDay) {
      queueBurnWeekZoneDialogIfNeeded(metrics: metrics, runState: runState);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eatenValueColor = isDark
        ? const Color(0xFFBFDBFE)
        : const Color(0xFF2E4A79);
    final leftGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF047857), Color(0xFF065F46)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1FA86A), Color(0xFF168955)],
          );

    return _DiaryBalanceShell(
      framed: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DiaryBalanceGameHeader(
            label: weekDayLabel,
            starCount: showGameControls ? runState.starCount : null,
            heartCount: showGameControls ? runState.heartCount : null,
            onHeartTap:
                showGameControls && runState.heartCount > 0 && !isHeartDay
                ? () => showBurnWeekZoneUseHeartDialog(
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
          if (bufferAdjustmentKcal.round() != 0 && !isHeartDay) ...[
            const SizedBox(height: AppSpacing.sm),
            _DiaryBalanceBufferBadge(label: bufferAdjustmentLabel),
          ],
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(
                child: _DiaryBalanceStatTile(
                  label: l10n.diaryBalanceEatenLabel,
                  value: _formatKcal(
                    numberFormat,
                    eatenKcal,
                    l10n.caloriesUnitKcal,
                  ),
                  subtitle: eatenSubtitle,
                  style: _DiaryBalanceStatTileStyle.eaten(
                    isDark: isDark,
                    valueColor: eatenValueColor,
                    subtitleColor: colors.onSurfaceVariant,
                    backgroundColor: isDark
                        ? colors.surfaceContainerLowest
                        : Colors.white,
                    borderColor: isDark
                        ? colors.outlineVariant
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DiaryBalanceStatTile(
                  label: l10n.diaryBalanceLeftLabel,
                  value: isHeartDay
                      ? l10n.diaryBalanceHeartDayValue
                      : _formatKcal(
                          numberFormat,
                          dayLeftKcal,
                          l10n.caloriesUnitKcal,
                        ),
                  subtitle: resolvedLeftSubtitle,
                  style: _DiaryBalanceStatTileStyle.left(
                    gradient: leftGradient,
                  ),
                ),
              ),
            ],
          ),
          if (canRevertHeartDay) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  unawaited(
                    ref
                        .read(burnWeekRunControllerProvider.notifier)
                        .unmarkHeartDay(selectedDayOverview.date),
                  );
                },
                icon: const Icon(Icons.undo_rounded),
                label: Text(l10n.diaryBalanceRevertHeartDayAction),
              ),
            ),
          ],
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

bool _isBurnWeekLearningWeek(int runWeekNumber) {
  return runWeekNumber <= burnWeekLearningRunWeekNumber;
}
