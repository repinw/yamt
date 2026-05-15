import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_weekly_balance_metrics.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_balance_formatters.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_metric_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_progress.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_shell.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Weekly Burn Week pacing card.
class DiaryWeeklyBalanceCard extends StatelessWidget {
  /// Creates the weekly balance card.
  const DiaryWeeklyBalanceCard({
    required this.weeklyMetrics,
    required this.runWeekNumber,
    required this.numberFormat,
    super.key,
  });

  /// Derived metrics for the weekly card.
  final DiaryWeeklyBalanceMetrics weeklyMetrics;

  /// Run week number to display for the selected day.
  final int runWeekNumber;

  /// Locale-aware number formatter.
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DiaryBalanceShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WeeklyPacingHeader(
            title: l10n.diaryBalanceWeekLabel(runWeekNumber),
            dayLabel: l10n.diaryBalanceDayProgressLabel(
              weeklyMetrics.progressDay,
              weeklyMetrics.totalDays,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          DiaryBalanceProgressBar(
            actualConsumedKcal: weeklyMetrics.pacing.actualConsumedKcal,
            targetKcal: weeklyMetrics.targetKcal,
            weeklyGoalKcal: weeklyMetrics.goalKcal,
            totalDays: weeklyMetrics.totalDays,
          ),
          const SizedBox(height: AppSpacing.xl),
          _WeeklySummaryRow(
            actualLabel: l10n.diaryBalanceWeekActualLabel,
            actualValue: formatDiaryKcal(
              numberFormat,
              weeklyMetrics.pacing.actualConsumedKcal,
              l10n.caloriesUnitKcal,
            ),
            targetLabel: l10n.diaryBalanceWeekTargetLabel,
            targetValue: formatDiaryKcal(
              numberFormat,
              weeklyMetrics.goalKcal,
              l10n.caloriesUnitKcal,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyPacingHeader extends StatelessWidget {
  const _WeeklyPacingHeader({
    required this.title,
    required this.dayLabel,
  });

  final String title;
  final String dayLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final activity = MetricAccentColors.of(context).activityFor(
      colors.brightness,
    );

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: activity,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _SoftBadge(label: dayLabel),
      ],
    );
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
          colors.surfaceContainerLowest,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.32 : 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 5,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _WeeklySummaryRow extends StatelessWidget {
  const _WeeklySummaryRow({
    required this.actualLabel,
    required this.actualValue,
    required this.targetLabel,
    required this.targetValue,
  });

  final String actualLabel;
  final String actualValue;
  final String targetLabel;
  final String targetValue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: DiaryBalanceMetricTile.weekly(
            label: actualLabel,
            value: actualValue,
            labelColor: colors.onSurfaceVariant,
            valueColor: colors.onSurface,
            unitColor: colors.onSurfaceVariant,
            alignment: CrossAxisAlignment.start,
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: DiaryBalanceMetricTile.weekly(
            label: targetLabel,
            value: targetValue,
            labelColor: colors.onSurfaceVariant,
            valueColor: colors.onSurface,
            unitColor: colors.onSurfaceVariant,
            alignment: CrossAxisAlignment.end,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
