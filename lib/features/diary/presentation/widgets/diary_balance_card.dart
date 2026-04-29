import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

const _balanceCardRadius = 32.0;
const _balanceProgressHeight = 24.0;
const _balanceFlameIconSize = 24.0;
const _balanceTargetMarkerWidth = 3.0;
const _balanceProgressAreaHeight = 56.0;
const _balanceStatTileHeight = 84.0;
const _balanceTickerPeriod = Duration(minutes: 1);

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
}

final FutureProvider<List<CalorieEntry>> Function(DateTime)
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
      return _buildShell(
        context,
        child: Text(
          l10n.diaryBalanceLoadFailed,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return _buildLoading(context);
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
      return _buildScheduledRestartCard(
        context,
        scheduledRestartDate: scheduledRestartDate,
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
    final weekDayLabel = formatBurnWeekLiveWeekDayLabel(
      currentDay: selectedDayOverview.date,
      currentWeekStartDate: currentWeekStartDate,
      runWeekNumber: runState.runWeekNumber,
      l10n: l10n,
    );
    if (showGameControls &&
        selectedDayEntriesLoaded &&
        !widget.hasAutoOpeningWeeklyCheckIn) {
      _queueZoneDialogIfNeeded(metrics: metrics, runState: runState);
    }

    return _buildShell(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showGameControls) ...[
            _buildGameHeader(
              context,
              label: weekDayLabel,
              starCount: runState.starCount,
              heartCount: runState.heartCount,
              canUseHeart: runState.heartCount > 0,
              onHeartTap: () => _showUseHeartDialog(
                dailyGoalKcal: metrics.dailyGoalKcal,
                runState: runState,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _buildProgressBar(
            context,
            metrics: metrics,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScaleLabel(context, '0 ${l10n.caloriesUnitKcal}'),
              _buildScaleLabel(
                context,
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
                child: _buildStatTile(
                  context,
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
                child: _buildStatTile(
                  context,
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

  Widget _buildShell(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFEEF2EF),
        borderRadius: BorderRadius.circular(_balanceCardRadius),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFDDE6E0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.1),
            blurRadius: isDark ? 26 : 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: child,
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0xFF1F2937)
        : const Color(0xFFDDE6E0);
    final highlightColor = isDark
        ? const Color(0xFF374151)
        : const Color(0xFFF8FAFC);

    return _buildShell(
      context,
      child: _DiaryBalanceSkeleton(
        baseColor: baseColor,
        highlightColor: highlightColor,
      ),
    );
  }

  Widget _buildScheduledRestartCard(
    BuildContext context, {
    required DateTime scheduledRestartDate,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );
    final colors = Theme.of(context).colorScheme;

    return _buildShell(
      context,
      child: Column(
        children: [
          Icon(
            Icons.favorite_border_rounded,
            color: colors.error,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.burnWeekRunOverTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colors.error,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.burnWeekRunRestartsOn(
              dateFormat.format(scheduledRestartDate),
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameHeader(
    BuildContext context, {
    required String label,
    required int starCount,
    required int heartCount,
    required bool canUseHeart,
    required VoidCallback onHeartTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _BurnWeekCounterBadge(
          icon: Icons.stars_rounded,
          iconColor: const Color(0xFFF59E0B),
          label: l10n.diaryCounterLabel(starCount),
        ),
        const SizedBox(width: AppSpacing.sm),
        _BurnWeekCounterBadge(
          icon: Icons.favorite_rounded,
          iconColor: colors.error,
          label: l10n.diaryCounterLabel(heartCount),
          onTap: canUseHeart ? onHeartTap : null,
        ),
      ],
    );
  }

  Widget _buildProgressBar(
    BuildContext context, {
    required BurnWeekMockMetrics metrics,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: _balanceProgressAreaHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final safeZoneRadiusRatio = _resolveSafeZoneRadiusRatio(metrics);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 16,
                child: Container(
                  key: DiaryBalanceCardKeys.progressTrack,
                  height: _balanceProgressHeight,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              _AnimatedBalanceRatio(
                value: metrics.targetRatio,
                builder: (context, targetRatio) {
                  return _AnimatedBalanceRatio(
                    value: safeZoneRadiusRatio,
                    builder: (context, radiusRatio) {
                      final safeCenter = width * targetRatio;
                      final requestedHalfWidth = width * radiusRatio;
                      final availableHalfWidth = math.min(
                        safeCenter,
                        math.max<double>(0, width - safeCenter),
                      );
                      final safeHalfWidth = math.min(
                        requestedHalfWidth,
                        availableHalfWidth,
                      );
                      final safeWidth = safeHalfWidth * 2;

                      if (safeWidth <= 0) {
                        return const SizedBox.shrink();
                      }

                      return Positioned(
                        left: safeCenter - safeHalfWidth,
                        top: 20,
                        width: safeWidth,
                        child: Container(
                          key: DiaryBalanceCardKeys.safeZone,
                          height: _balanceProgressHeight - 8,
                          decoration: BoxDecoration(
                            color: colors.tertiary.withValues(alpha: 0.32),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              _AnimatedBalanceRatio(
                value: metrics.targetRatio,
                builder: (context, targetRatio) {
                  final markerLeft = (width * targetRatio - 1.5).clamp(
                    0.0,
                    math.max<double>(0, width - _balanceTargetMarkerWidth),
                  );

                  return Positioned(
                    left: markerLeft,
                    top: 8,
                    child: Container(
                      key: DiaryBalanceCardKeys.targetMarker,
                      width: _balanceTargetMarkerWidth,
                      height: _balanceProgressHeight + 8,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                },
              ),
              _AnimatedBalanceRatio(
                value: metrics.consumedRatio,
                builder: (context, consumedRatio) {
                  final flameCenter = width * consumedRatio;
                  final flameLeft = (flameCenter - _balanceFlameIconSize / 2)
                      .clamp(
                        0.0,
                        math.max<double>(0, width - _balanceFlameIconSize),
                      );

                  return Positioned(
                    left: flameLeft,
                    top: 14,
                    child: const SizedBox.square(
                      key: DiaryBalanceCardKeys.consumedMarker,
                      dimension: _balanceFlameIconSize,
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFD32F2F),
                        size: _balanceFlameIconSize,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  double _resolveSafeZoneRadiusRatio(BurnWeekMockMetrics metrics) {
    final span = metrics.barMaxKcal - metrics.barMinKcal;
    if (span <= 0) {
      return 0;
    }

    final lowerRadius = (metrics.targetKcal - metrics.safeZoneMinKcal).abs();
    final upperRadius = (metrics.safeZoneMaxKcal - metrics.targetKcal).abs();
    return (math.max(lowerRadius, upperRadius) / span).clamp(0.0, 0.5);
  }

  Widget _buildScaleLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required String label,
    required String value,
    required Color valueColor,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      height: _balanceStatTileHeight,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: valueColor,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
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
    _ticker ??= Timer.periodic(_balanceTickerPeriod, (_) {
      if (!mounted) {
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

class _AnimatedBalanceRatio extends StatelessWidget {
  const _AnimatedBalanceRatio({required this.value, required this.builder});

  final double value;
  final Widget Function(BuildContext context, double value) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOut,
      tween: Tween<double>(begin: 0, end: value),
      builder: (context, value, child) => builder(context, value),
    );
  }
}

class _BurnWeekCounterBadge extends StatelessWidget {
  const _BurnWeekCounterBadge({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final child = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: child,
      ),
    );
  }
}

class _DiaryBalanceSkeleton extends StatefulWidget {
  const _DiaryBalanceSkeleton({
    required this.baseColor,
    required this.highlightColor,
  });

  final Color baseColor;
  final Color highlightColor;

  @override
  State<_DiaryBalanceSkeleton> createState() => _DiaryBalanceSkeletonState();
}

class _DiaryBalanceSkeletonState extends State<_DiaryBalanceSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shaderOffset = boundsWidthMultiplier(_controller.value);

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.28, 0.5, 0.72],
            ).createShader(
              Rect.fromLTWH(
                bounds.left + (bounds.width * shaderOffset),
                bounds.top,
                bounds.width,
                bounds.height,
              ),
            );
          },
          child: child,
        );
      },
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _balanceProgressAreaHeight,
            child: Align(
              child: _SkeletonBlock(height: _balanceProgressHeight),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SkeletonBlock(width: 52, height: 14),
              _SkeletonBlock(width: 86, height: 14),
            ],
          ),
          SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(child: _SkeletonBlock(height: _balanceStatTileHeight)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: _SkeletonBlock(height: _balanceStatTileHeight)),
            ],
          ),
        ],
      ),
    );
  }

  double boundsWidthMultiplier(double animationValue) {
    return -1 + (animationValue * 2);
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height, this.width});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
