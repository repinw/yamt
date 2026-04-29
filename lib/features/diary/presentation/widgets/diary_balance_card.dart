import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/burn_week_mock_logic.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_live_overview_logic.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';

const _balanceCardRadius = 32.0;
const _balanceProgressHeight = 24.0;
const _balanceFlameIconSize = 24.0;
const _balanceTargetMarkerWidth = 3.0;
const _balanceProgressAreaHeight = 56.0;
const _balanceStatTileHeight = 84.0;

/// Weekly calorie balance card for the Tagebuch page.
class DiaryBalanceCard extends ConsumerStatefulWidget {
  /// Creates the diary balance card.
  const DiaryBalanceCard({required this.selectedDay, super.key});

  /// The selected diary day.
  final DateTime selectedDay;

  @override
  ConsumerState<DiaryBalanceCard> createState() => _DiaryBalanceCardState();
}

class _DiaryBalanceCardState extends ConsumerState<DiaryBalanceCard>
    with AutomaticKeepAliveClientMixin<DiaryBalanceCard> {
  CalorieWeekOverview? _lastWeekOverview;
  CalorieWeekDayOverview? _lastSelectedDayOverview;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final weekOverviewState = ref.watch(
      calorieWeekOverviewForWindowProvider(widget.selectedDay),
    );
    final selectedDayState = ref.watch(
      calorieWeekDayOverviewForDateProvider(widget.selectedDay),
    );
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
        runState: runState,
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
        runState: runState,
      );
    }

    if (weekOverviewState.hasError || selectedDayState.hasError) {
      return _buildShell(
        context,
        child: Text(
          'Balance konnte nicht geladen werden',
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
    required BurnWeekRunState runState,
  }) {
    final colors = Theme.of(context).colorScheme;
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final currentWeekStartDate = resolveBurnWeekLiveWeekStartDate(
      currentDay: selectedDayOverview.date,
      balanceStartDate: weekOverview.balanceStartDate,
      storedWeekStartDayKey: runState.currentWeekStartDayKey,
    );
    final metrics = _resolveMetrics(
      weekOverview: weekOverview,
      selectedDayOverview: selectedDayOverview,
      currentWeekStartDate: currentWeekStartDate,
      runState: runState,
    );
    final dayBudgetKcal = weekOverview.todayFlexibleGoalKcal;
    final dayLeftKcal = dayBudgetKcal - selectedDayOverview.totalKcal;

    return _buildShell(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProgressBar(
            context,
            metrics: metrics,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScaleLabel(context, '0 kcal'),
              _buildScaleLabel(
                context,
                _formatKcal(numberFormat, metrics.barMaxKcal),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  context,
                  label: 'Gegessen',
                  value: _formatKcal(
                    numberFormat,
                    selectedDayOverview.totalKcal,
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
                  label: 'Übrig',
                  value: _formatKcal(numberFormat, dayLeftKcal),
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

    return resolveBurnWeekLiveMetrics(
      now: _referenceNowForDay(selectedDayOverview.date),
      weekOverview: weekOverview,
      todayOverview: selectedDayOverview,
      currentWeekStartDate: currentWeekStartDate,
      previousWeekOverflowKcal: previousWeekOverflowKcal,
      heartCreditKcal: runState.heartCreditKcal,
      plannedLaterTodayKcal: 0,
      safeZoneMultiplier: difficulty.safeZoneMultiplier,
    );
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

  String _formatKcal(NumberFormat numberFormat, double value) {
    return '${numberFormat.format(value.round())} kcal';
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
