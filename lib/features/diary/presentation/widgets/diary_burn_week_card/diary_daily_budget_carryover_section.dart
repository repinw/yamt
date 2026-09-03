import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_budget_details_data.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_balance_formatters.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_budget_carryover_formula_box.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_budget_previous_day_row.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_budget_sheet_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Section explaining the origin and distribution of carryover
/// from previous days.
class DiaryDailyBudgetCarryoverSection extends StatelessWidget {
  /// Creates the carryover section.
  const DiaryDailyBudgetCarryoverSection({
    required this.data,
    required this.numberFormat,
    super.key,
  });

  /// Budget details data.
  final DiaryDailyBudgetDetailsData data;

  /// Locale-aware number format.
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final accents = MetricAccentColors.of(context);
    final primary = accents.today;
    final unit = l10n.caloriesUnitKcal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.diaryBudgetDetailsCarryoverSectionTitle,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.diaryBudgetDetailsCarryoverExplanation,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (data.previousDays.isEmpty)
          DiaryDailyBudgetSheetCard(
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.diaryBudgetDetailsNoPreviousDays,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          DiaryDailyBudgetSheetCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < data.previousDays.length; i++) ...[
                  if (i > 0) const Divider(height: AppSpacing.md),
                  DiaryDailyBudgetPreviousDayRow(
                    day: data.previousDays[i],
                    numberFormat: numberFormat,
                  ),
                ],
                const Divider(height: AppSpacing.md),
                DiaryDailyBudgetRow(
                  label: l10n.diaryBudgetDetailsTotalCarryoverLabel,
                  value: formatDiarySignedKcal(
                    data.totalCarryoverBeforeTodayKcal,
                    numberFormat,
                    unit,
                  ),
                  isBold: true,
                  valueColor: data.totalCarryoverBeforeTodayKcal > 0
                      ? primary
                      : (data.totalCarryoverBeforeTodayKcal < 0
                          ? accents.activityFor(colors.brightness)
                          : colors.onSurface),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DiaryDailyBudgetCarryoverFormulaBox(
            data: data,
            numberFormat: numberFormat,
            unit: unit,
            primary: primary,
          ),
        ],
      ],
    );
  }
}
