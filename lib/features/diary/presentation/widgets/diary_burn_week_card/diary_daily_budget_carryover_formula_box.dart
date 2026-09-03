import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_budget_details_data.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_balance_formatters.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Formula box explaining how carryover is distributed across remaining days
/// and its impact on macronutrients.
class DiaryDailyBudgetCarryoverFormulaBox extends StatelessWidget {
  /// Creates the carryover distribution formula box.
  const DiaryDailyBudgetCarryoverFormulaBox({
    required this.data,
    required this.numberFormat,
    required this.unit,
    required this.primary,
    super.key,
  });

  /// Budget details data.
  final DiaryDailyBudgetDetailsData data;

  /// Locale-aware number format.
  final NumberFormat numberFormat;

  /// Energy unit label (e.g. kcal).
  final String unit;

  /// Accent primary color.
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final accents = MetricAccentColors.of(context);

    final hasCarryover = data.carryoverKcal.round() != 0;

    final proteinStr = '±0 ${l10n.caloriesUnitGram}';
    final carbsDelta = data.carryoverCarbsDeltaGrams;
    final carbsSign = carbsDelta >= 0 ? '+' : '';
    final carbsFormatted = numberFormat.format(carbsDelta.round());
    final carbsStr = '$carbsSign$carbsFormatted ${l10n.caloriesUnitGram}';

    final fatDelta = data.carryoverFatDeltaGrams;
    final fatSign = fatDelta >= 0 ? '+' : '';
    final fatFormatted = numberFormat.format(fatDelta.round());
    final fatStr = '$fatSign$fatFormatted ${l10n.caloriesUnitGram}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: primary.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(Icons.swap_horiz_rounded, size: 20, color: primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.diaryBudgetDetailsDistributionFormula(
                    formatDiarySignedKcal(
                      data.totalCarryoverBeforeTodayKcal,
                      numberFormat,
                      unit,
                    ),
                    data.remainingRunDays,
                    formatDiarySignedKcal(
                      data.carryoverKcal,
                      numberFormat,
                      unit,
                    ),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasCarryover) ...[
          const SizedBox(height: AppSpacing.xs),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.diaryBudgetDetailsMacroAdjustment(
                      proteinStr,
                      carbsStr,
                      fatStr,
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (data.wasSafetyCapActive) ...[
          const SizedBox(height: AppSpacing.xs),
          Container(
            decoration: BoxDecoration(
              color: accents
                  .heartFor(colors.brightness)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color:
                    accents.heartFor(colors.brightness).withValues(alpha: 0.25),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: accents.heartFor(colors.brightness),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.diaryBudgetDetailsSafetyCapActive,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
