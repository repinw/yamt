import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_daily_balance_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_buffer_badge.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_shell.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_balance_metrics_row.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_balance_subtitle_row.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_budget_details_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_goal_progress_bar.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_nutrition_bars.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Daily calories, macros, and pacing balance card.
class DiaryDailyBalanceCard extends StatelessWidget {
  /// Creates the daily balance card.
  const DiaryDailyBalanceCard({
    required this.data,
    super.key,
  });

  /// Render-ready daily card data.
  final DiaryDailyBalanceData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return DiaryBalanceShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DiaryDailyBalanceMetricsRow(data: data),
          const SizedBox(height: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.xs),
          DiaryDailyBalanceSubtitleRow(
            data: data,
            onBudgetDetailsTap: data.budgetDetails == null
                ? null
                : () => showDiaryDailyBudgetDetailsSheet(
                    context: context,
                    data: data.budgetDetails!,
                    numberFormat: data.numberFormat,
                  ),
          ),
          if (data.bufferAdjustmentLabel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            DiaryBalanceBufferBadge(
              label: data.bufferAdjustmentLabel!,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Divider(
            height: 1,
            thickness: 1,
            color: colors.outlineVariant.withValues(alpha: 0.35),
          ),
          const SizedBox(height: AppSpacing.md),
          DiaryNutritionBars.embedded(selectedDay: data.selectedDay),
        ],
      ),
    );
  }
}
