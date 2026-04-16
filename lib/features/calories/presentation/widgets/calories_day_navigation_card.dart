import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/calorie_weekday_l10n.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _miniWeekBalanceChartMinKcal = 800.0;
const _miniWeekBalanceChartHeadroomFactor = 1.1;
const _miniWeekBalanceHeight = 64.0;
const _miniWeekBalanceWidth = 30.0;
const _miniWeekBalanceGoalLineHeight = 3.0;
const _miniWeekBalanceHorizontalInset = 4.0;

/// Defines calories day navigation card.
class CaloriesDayNavigationCard extends StatelessWidget {
  /// The calories day navigation card.
  const CaloriesDayNavigationCard({
    required this.days,
    required this.selectedDay,
    required this.onSelectDay,
    super.key,
    this.referenceNow,
    this.isPressEnabled = true,
  });

  /// The days.
  final List<CalorieWeekDayOverview> days;

  /// The selected day.
  final DateTime selectedDay;

  /// The reference now.
  final DateTime? referenceNow;

  /// The on select day.
  final ValueChanged<DateTime> onSelectDay;

  /// Whether press enabled.
  final bool isPressEnabled;

  @override
  Widget build(BuildContext context) {
    final chartMaxKcal = resolveCaloriesDayNavigationChartMaxKcal(days);
    final resolvedNow = referenceNow ?? DateTime.now();

    return Row(
      key: CaloriesPageKeys.weekStrip,
      children: [
        for (final day in days)
          Expanded(
            child: CaloriesDayNavigationDayTile(
              day: day,
              isToday: isSameDiaryDay(day.date, resolvedNow),
              isSelected: isSameDiaryDay(day.date, selectedDay),
              chartMaxKcal: chartMaxKcal,
              onTap: () => onSelectDay(day.date),
              isPressEnabled: isPressEnabled,
            ),
          ),
      ],
    );
  }
}

/// Resolves the vertical chart range for the day navigation preview bars.
double resolveCaloriesDayNavigationChartMaxKcal(
  List<CalorieWeekDayOverview> days,
) {
  final peakKcal = days.fold<double>(0, (peak, day) {
    return math.max(peak, math.max(day.goalKcal, day.totalKcal));
  });
  return math.max(
    _miniWeekBalanceChartMinKcal,
    peakKcal * _miniWeekBalanceChartHeadroomFactor,
  );
}

/// Defines calories day navigation day tile.
class CaloriesDayNavigationDayTile extends StatelessWidget {
  /// The calories day navigation day tile.
  const CaloriesDayNavigationDayTile({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.chartMaxKcal,
    required this.onTap,
    required this.isPressEnabled,
    super.key,
  });

  /// The day.
  final CalorieWeekDayOverview day;

  /// Whether today.
  final bool isToday;

  /// Whether selected.
  final bool isSelected;

  /// The chart max kcal.
  final double chartMaxKcal;

  /// The on tap.
  final VoidCallback onTap;

  /// Whether press enabled.
  final bool isPressEnabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final label = localizedDiaryWeekdayLabel(l10n, day.date);
    final labelColor = isToday
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final numberBackground = isToday ? colorScheme.primary : Colors.transparent;
    final numberColor = isToday ? colorScheme.onPrimary : colorScheme.onSurface;

    return InkWell(
      onTap: isPressEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: labelColor,
                fontWeight: isToday || isSelected
                    ? FontWeight.w800
                    : FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _DiaryDayBalancePreview(
              day: day,
              isToday: isToday,
              isSelected: isSelected,
              chartMaxKcal: chartMaxKcal,
            ),
            const SizedBox(height: AppSpacing.sm),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: numberBackground,
                shape: BoxShape.circle,
                border: isSelected && !isToday
                    ? Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.22),
                      )
                    : null,
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.26),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '${day.date.day}'.padLeft(2, '0'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: numberColor,
                    fontWeight: isToday || isSelected
                        ? FontWeight.w800
                        : FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _DiaryDayStatus(day: day, isToday: isToday, isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _DiaryDayBalancePreview extends StatelessWidget {
  const _DiaryDayBalancePreview({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.chartMaxKcal,
  });

  final CalorieWeekDayOverview day;
  final bool isToday;
  final bool isSelected;
  final double chartMaxKcal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dayKey = diaryDayKey(day.date);
    final goalRatio = (day.goalKcal / chartMaxKcal).clamp(0.0, 1.0);
    final totalRatio = (day.totalKcal / chartMaxKcal).clamp(0.0, 1.0);
    final goalBottomOffset = (_miniWeekBalanceHeight * goalRatio).toDouble();
    final barHeight = (_miniWeekBalanceHeight * totalRatio).toDouble();

    return SizedBox(
      key: CaloriesPageKeys.dayNavigationPreview(dayKey),
      width: _miniWeekBalanceWidth,
      height: _miniWeekBalanceHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isToday
                    ? colors.primaryContainer.withValues(alpha: 0.35)
                    : colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected
                      ? colors.primary.withValues(alpha: 0.35)
                      : AppInventoryEditorialSurfaces.ghostBorder(colors),
                ),
              ),
            ),
          ),
          Positioned(
            left: _miniWeekBalanceHorizontalInset,
            right: _miniWeekBalanceHorizontalInset,
            bottom: goalBottomOffset - 1,
            child: DecoratedBox(
              key: CaloriesPageKeys.dayNavigationPreviewGoalLine(dayKey),
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const SizedBox(height: _miniWeekBalanceGoalLineHeight),
            ),
          ),
          if (barHeight > 0)
            Positioned(
              left: _miniWeekBalanceHorizontalInset,
              right: _miniWeekBalanceHorizontalInset,
              bottom: 0,
              height: barHeight,
              child: DecoratedBox(
                key: CaloriesPageKeys.dayNavigationPreviewBar(dayKey),
                decoration: BoxDecoration(
                  color: _barColor(colors),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _barColor(ColorScheme colors) {
    if (isToday) {
      return colors.primary;
    }
    if (day.isOverGoal) {
      return colors.error;
    }
    return colors.primary;
  }
}

class _DiaryDayStatus extends StatelessWidget {
  const _DiaryDayStatus({
    required this.day,
    required this.isToday,
    required this.isSelected,
  });

  final CalorieWeekDayOverview day;
  final bool isToday;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (isToday) {
      return Container(
        width: 16,
        height: 4,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }
    if (isSelected) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.4)),
          shape: BoxShape.circle,
        ),
      );
    }
    if (day.isWithinGoal) {
      return Icon(Icons.check_circle, size: 12, color: colorScheme.primary);
    }
    late final Color statusColor;
    if (day.isOverGoal) {
      statusColor = colorScheme.error;
    } else {
      statusColor = colorScheme.surfaceContainerHighest;
    }
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
    );
  }
}
