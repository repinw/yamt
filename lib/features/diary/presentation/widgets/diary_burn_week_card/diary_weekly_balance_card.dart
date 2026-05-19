import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_weekly_balance_metrics.dart';
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
    this.framed = true,
    super.key,
  });

  /// Derived metrics for the weekly card.
  final DiaryWeeklyBalanceMetrics weeklyMetrics;

  /// Run week number to display for the selected day.
  final int runWeekNumber;

  /// Locale-aware number formatter.
  final NumberFormat numberFormat;

  /// Whether to draw the standalone card frame.
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final activity = MetricAccentColors.of(context).activityFor(
      colors.brightness,
    );
    final actualKcal = numberFormat.format(
      weeklyMetrics.pacing.actualConsumedKcal.round(),
    );
    final goalKcal = numberFormat.format(weeklyMetrics.goalKcal.round());
    final valueLabel =
        '$actualKcal / $goalKcal '
        '${l10n.caloriesUnitKcal}';

    return DiaryBalanceShell(
      framed: framed,
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: activity,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.diaryBalanceWeekLabel(runWeekNumber),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          valueLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                DiaryBalanceProgressBar(
                  actualConsumedKcal: weeklyMetrics.pacing.actualConsumedKcal,
                  targetKcal: weeklyMetrics.targetKcal,
                  weeklyGoalKcal: weeklyMetrics.goalKcal,
                  totalDays: weeklyMetrics.totalDays,
                  compact: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
