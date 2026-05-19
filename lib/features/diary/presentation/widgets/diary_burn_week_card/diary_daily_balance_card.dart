import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_daily_balance_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_buffer_badge.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_metric_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_shell.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_goal_progress_bar.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Daily calories, macros, and heart adjustment content.
class DiaryDailyBalanceCard extends StatelessWidget {
  /// Creates the daily balance card.
  const DiaryDailyBalanceCard({
    required this.data,
    required this.onUnmarkHeartDay,
    super.key,
  });

  /// Render-ready daily card data.
  final DiaryDailyBalanceData data;

  /// Reverts a heart day.
  final ValueChanged<DateTime> onUnmarkHeartDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DiaryBalanceShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DailyBalanceSummary(
            eatenLabel: l10n.diaryBalanceEatenLabel,
            eatenValue: data.eatenValue,
            eatenSubtitle: data.eatenSubtitle,
            leftLabel: l10n.diaryBalanceLeftTodayLabel,
            leftValue: data.leftValue,
            leftSubtitle: data.leftSubtitle,
            isHeartDay: data.isHeartDay,
          ),
          const SizedBox(height: AppSpacing.md),
          DiaryDailyGoalProgressBar(
            eatenKcal: data.metrics.eatenKcal,
            targetKcal: data.metrics.targetKcal,
            activitySegmentKcal: data.metrics.activitySegmentKcal,
            numberFormat: data.numberFormat,
            unit: l10n.caloriesUnitKcal,
            compact: true,
          ),
          if (data.bufferAdjustmentLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            DiaryBalanceBufferBadge(
              label: data.bufferAdjustmentLabel!,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          DiaryNutritionBars.embedded(selectedDay: data.selectedDay),
          if (data.canRevertHeartDay) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onUnmarkHeartDay(data.selectedDay),
                icon: const Icon(Icons.undo_rounded),
                label: Text(l10n.diaryBalanceRevertHeartDayAction),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyBalanceSummary extends StatelessWidget {
  const _DailyBalanceSummary({
    required this.eatenLabel,
    required this.eatenValue,
    required this.leftLabel,
    required this.leftValue,
    required this.isHeartDay,
    this.eatenSubtitle,
    this.leftSubtitle,
  });

  final String eatenLabel;
  final String eatenValue;
  final String? eatenSubtitle;
  final String leftLabel;
  final String leftValue;
  final String? leftSubtitle;
  final bool isHeartDay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accents = MetricAccentColors.of(context);
    final primary = accents.today;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DiaryBalanceMetricTile.daily(
            label: eatenLabel,
            value: eatenValue,
            subtitle: eatenSubtitle,
            labelColor: colors.onSurfaceVariant,
            valueColor: colors.onSurface,
            unitColor: colors.onSurfaceVariant,
            alignment: CrossAxisAlignment.start,
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: DiaryBalanceMetricTile.daily(
            label: leftLabel,
            value: leftValue,
            subtitle: leftSubtitle,
            labelColor: isHeartDay
                ? accents.heartFor(colors.brightness)
                : primary,
            valueColor: isHeartDay
                ? accents.heartFor(colors.brightness)
                : primary,
            unitColor: isHeartDay
                ? accents.heartFor(colors.brightness).withValues(alpha: 0.78)
                : primary.withValues(alpha: 0.78),
            alignment: CrossAxisAlignment.end,
            textAlign: TextAlign.end,
            splitUnit: !isHeartDay,
          ),
        ),
      ],
    );
  }
}
