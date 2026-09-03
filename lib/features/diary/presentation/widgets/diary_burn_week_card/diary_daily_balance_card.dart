import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_daily_balance_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_buffer_badge.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_metric_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_shell.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_budget_details_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_goal_progress_bar.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_nutrition_bars.dart';
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
            data: data,
            onBudgetDetailsTap: data.budgetDetails == null
                ? null
                : () => showDiaryDailyBudgetDetailsSheet(
                    context: context,
                    data: data.budgetDetails!,
                    numberFormat: data.numberFormat,
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          DiaryDailyGoalProgressBar(
            eatenKcal: data.metrics.eatenKcal,
            targetKcal: data.metrics.targetKcal,
            activitySegmentKcal: data.metrics.activitySegmentKcal,
            activitySegmentReferenceKcal:
                data.metrics.activitySegmentReferenceKcal,
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
    required this.data,
    this.onBudgetDetailsTap,
  });

  final DiaryDailyBalanceData data;
  final VoidCallback? onBudgetDetailsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final accents = MetricAccentColors.of(context);
    final primary = accents.today;

    final resolvedLeftLabel = data.isFutureDay
        ? l10n.diaryBalanceBaseLabel
        : l10n.diaryBalanceLeftTodayLabel;
    final resolvedLeftValue = data.isFutureDay
        ? data.baseValue
        : data.leftValue;
    final resolvedLeftLabelColor = data.isFutureDay
        ? colors.onSurfaceVariant
        : (data.isHeartDay ? accents.heartFor(colors.brightness) : primary);
    final resolvedLeftValueColor = data.isFutureDay
        ? colors.onSurface
        : (data.isHeartDay ? accents.heartFor(colors.brightness) : primary);
    final resolvedLeftUnitColor = data.isFutureDay
        ? colors.onSurfaceVariant
        : (data.isHeartDay
              ? accents.heartFor(colors.brightness).withValues(alpha: 0.78)
              : primary.withValues(alpha: 0.78));

    final resolvedRightLabel = data.isFutureDay
        ? l10n.diaryBalancePlannedWithCarryoverLabel
        : l10n.diaryBalanceEatenLabel;
    final resolvedRightValue = data.isFutureDay
        ? data.plannedWithCarryoverValue
        : data.eatenValue;
    final resolvedRightSubtitle = data.isFutureDay ? null : data.eatenSubtitle;
    final resolvedRightLabelColor = data.isFutureDay
        ? primary
        : colors.onSurfaceVariant;
    final resolvedRightValueColor = data.isFutureDay
        ? primary
        : colors.onSurface;
    final resolvedRightUnitColor = data.isFutureDay
        ? primary.withValues(alpha: 0.78)
        : colors.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DiaryBalanceMetricTile.daily(
                label: resolvedLeftLabel,
                value: resolvedLeftValue,
                labelColor: resolvedLeftLabelColor,
                valueColor: resolvedLeftValueColor,
                unitColor: resolvedLeftUnitColor,
                alignment: CrossAxisAlignment.start,
                splitUnit: data.isFutureDay || !data.isHeartDay,
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: DiaryBalanceMetricTile.daily(
                label: resolvedRightLabel,
                value: resolvedRightValue,
                subtitle: resolvedRightSubtitle,
                labelColor: resolvedRightLabelColor,
                valueColor: resolvedRightValueColor,
                unitColor: resolvedRightUnitColor,
                alignment: CrossAxisAlignment.end,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        if (data.leftSubtitle != null || onBudgetDetailsTap != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: data.leftSubtitle == null
                    ? const SizedBox.shrink()
                    : Text(
                        data.leftSubtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: data.isHeartDay
                              ? accents
                                    .heartFor(colors.brightness)
                                    .withValues(alpha: 0.78)
                              : primary.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
              ),
              if (onBudgetDetailsTap != null) ...[
                const SizedBox(width: AppSpacing.xs),
                _DailyBudgetDetailsButton(
                  onTap: onBudgetDetailsTap!,
                  isHeartDay: data.isHeartDay,
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _DailyBudgetDetailsButton extends StatelessWidget {
  const _DailyBudgetDetailsButton({
    required this.onTap,
    required this.isHeartDay,
  });

  final VoidCallback onTap;
  final bool isHeartDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final accents = MetricAccentColors.of(context);
    final buttonColor = isHeartDay
        ? accents.heartFor(colors.brightness)
        : accents.today;

    return Semantics(
      button: true,
      label: l10n.diaryBudgetDetailsTitle,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: DiaryBalanceCardKeys.dailyBudgetDetailsButton,
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.diaryBudgetDetailsButtonLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: buttonColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: buttonColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
