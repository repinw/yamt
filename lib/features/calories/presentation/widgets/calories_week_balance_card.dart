import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _weekBalanceChartMinKcal = 800.0;
const _weekBalanceChartHeadroomFactor = 1.1;
const _weekBalanceChartHeight = 64.0;
const _weekBalanceGoalLineHeight = 2.0;
const _weekBalanceGoalLineAdjustment = 1.0;
const _weekBalanceSummaryIconSize = 18.0;

/// Defines calories week balance card.
class CaloriesWeekBalanceCard extends StatelessWidget {
  /// The calories week balance card.
  const CaloriesWeekBalanceCard({required this.overview, super.key});

  /// The overview.
  final CalorieWeekOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final activeDays = overview.days
        .where((day) => !_isBeforeDay(day.date, overview.balanceStartDate))
        .toList(growable: false);
    final chartMaxKcal = _chartMaxKcal(activeDays);

    return DecoratedBox(
      key: CaloriesPageKeys.weekBufferCard,
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppInventoryEditorial.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.caloriesWeekBufferTitle,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.lg),
            _WeekBalanceChart(
              days: overview.days,
              balanceStartDate: overview.balanceStartDate,
              chartMaxKcal: chartMaxKcal,
            ),
            const SizedBox(height: AppSpacing.lg),
            _WeekBalanceSummary(
              carryoverBeforeTodayKcal: overview.carryoverBeforeTodayKcal,
              balanceStartDate: overview.balanceStartDate,
              goalStartsInFuture: overview.goalStartsInFuture,
              nextGoalStartDate: overview.nextGoalStartDate,
            ),
          ],
        ),
      ),
    );
  }

  double _chartMaxKcal(List<CalorieWeekDayOverview> activeDays) {
    final peakKcal = activeDays.fold<double>(0, (peak, day) {
      return math.max(peak, math.max(day.goalKcal, day.totalKcal));
    });
    return math.max(
      _weekBalanceChartMinKcal,
      peakKcal * _weekBalanceChartHeadroomFactor,
    );
  }
}

class _WeekBalanceChart extends StatelessWidget {
  const _WeekBalanceChart({
    required this.days,
    required this.balanceStartDate,
    required this.chartMaxKcal,
  });

  final List<CalorieWeekDayOverview> days;
  final DateTime balanceStartDate;
  final double chartMaxKcal;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: CaloriesPageKeys.weekBalanceChart,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var index = 0; index < days.length; index += 1) ...[
          if (index > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _WeekBalanceDayColumn(
              key: CaloriesPageKeys.weekBalanceDayColumn(
                _dayKey(days[index].date),
              ),
              day: days[index],
              isActive: !_isBeforeDay(days[index].date, balanceStartDate),
              chartMaxKcal: chartMaxKcal,
            ),
          ),
        ],
      ],
    );
  }
}

class _WeekBalanceDayColumn extends StatelessWidget {
  const _WeekBalanceDayColumn({
    required this.day, required this.isActive, required this.chartMaxKcal, super.key,
  });

  final CalorieWeekDayOverview day;
  final bool isActive;
  final double chartMaxKcal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isToday = _isToday(day.date);
    final locale = Localizations.localeOf(context).languageCode;
    final goalRatio = (day.goalKcal / chartMaxKcal).clamp(0.0, 1.0);
    final totalRatio = (day.totalKcal / chartMaxKcal).clamp(0.0, 1.0);
    final goalBottomOffset = _weekBalanceChartHeight * goalRatio;
    final barHeight = _weekBalanceChartHeight * totalRatio;

    return Semantics(
      label: _semanticLabel(context, isToday: isToday),
      child: Column(
        children: [
          SizedBox(
            height: _weekBalanceChartHeight,
            child: isActive
                ? Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: isToday
                                ? colors.primaryContainer.withValues(
                                    alpha: 0.35,
                                  )
                                : colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: isToday
                                  ? colors.primary.withValues(alpha: 0.35)
                                  : AppInventoryEditorialSurfaces.ghostBorder(
                                      colors,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.xs,
                        right: AppSpacing.xs,
                        bottom:
                            goalBottomOffset - _weekBalanceGoalLineAdjustment,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.outlineVariant,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const SizedBox(
                            height: _weekBalanceGoalLineHeight,
                          ),
                        ),
                      ),
                      if (barHeight > 0)
                        Positioned(
                          left: AppSpacing.xs,
                          right: AppSpacing.xs,
                          bottom: 0,
                          height: barHeight,
                          child: DecoratedBox(
                            key: CaloriesPageKeys.weekBalanceBar(
                              _dayKey(day.date),
                            ),
                            decoration: BoxDecoration(
                              color: _barColor(colors, isToday: isToday),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                    ],
                  )
                : const SizedBox.expand(),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isToday
                ? AppLocalizations.of(context)!.caloriesWeekBalanceTodayLabel
                : _weekdayLabel(day.date, locale),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isToday ? colors.primary : colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _barColor(ColorScheme colors, {required bool isToday}) {
    if (isToday) {
      return colors.primary;
    }
    if (day.isOverGoal) {
      return colors.error;
    }
    return colors.primary;
  }

  String _semanticLabel(BuildContext context, {required bool isToday}) {
    final l10n = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat.decimalPatternDigits(decimalDigits: 0);
    final label = isToday
        ? l10n.caloriesWeekBalanceTodayLabel
        : _weekdayLabel(day.date, Localizations.localeOf(context).languageCode);
    if (!isActive) {
      return label;
    }
    return '$label: ${numberFormat.format(day.totalKcal)} von '
        '${numberFormat.format(day.goalKcal)} kcal';
  }

  String _weekdayLabel(DateTime day, String locale) {
    return DateFormat.E(locale).format(day).replaceAll('.', '');
  }

  bool _isToday(DateTime date) {
    final today = normalizeDiaryDay(DateTime.now());
    return normalizeDiaryDay(date) == today;
  }
}

class _WeekBalanceSummary extends StatelessWidget {
  const _WeekBalanceSummary({
    required this.carryoverBeforeTodayKcal,
    required this.balanceStartDate,
    required this.goalStartsInFuture,
    required this.nextGoalStartDate,
  });

  final double carryoverBeforeTodayKcal;
  final DateTime balanceStartDate;
  final bool goalStartsInFuture;
  final DateTime? nextGoalStartDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final isGoalStartToday =
        normalizeDiaryDay(balanceStartDate) ==
        normalizeDiaryDay(DateTime.now());
    final accentColor = carryoverBeforeTodayKcal < 0
        ? colors.error
        : colors.primary;
    final backgroundColor = carryoverBeforeTodayKcal < 0
        ? colors.error.withValues(alpha: 0.08)
        : colors.primary.withValues(alpha: 0.08);
    final absoluteCarryover = carryoverBeforeTodayKcal.abs().round();
    final futureGoalStartLabel = nextGoalStartDate == null
        ? null
        : DateFormat.yMMMd(
            Localizations.localeOf(context).toLanguageTag(),
          ).format(nextGoalStartDate!);

    final message = switch ((isGoalStartToday, carryoverBeforeTodayKcal)) {
      _ when goalStartsInFuture && futureGoalStartLabel != null =>
        l10n.caloriesWeekBalanceStartsLater(futureGoalStartLabel),
      (true, _) => l10n.caloriesWeekBalanceStartedToday,
      (_, > 0) => l10n.caloriesWeekBalanceSaved(absoluteCarryover),
      (_, < 0) => l10n.caloriesWeekBalanceOverspent(absoluteCarryover),
      _ => l10n.caloriesWeekBalanceStable,
    };

    return DecoratedBox(
      key: CaloriesPageKeys.weekBalanceSummary,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              key: CaloriesPageKeys.weekBalanceSummaryIcon,
              size: _weekBalanceSummaryIconSize,
              color: accentColor,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _dayKey(DateTime day) {
  final normalized = normalizeDiaryDay(day);
  return '${normalized.year}-${normalized.month}-${normalized.day}';
}

bool _isBeforeDay(DateTime left, DateTime right) {
  return normalizeDiaryDay(left).isBefore(normalizeDiaryDay(right));
}
