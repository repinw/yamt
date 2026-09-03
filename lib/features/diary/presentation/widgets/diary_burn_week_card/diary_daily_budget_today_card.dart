import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_budget_details_data.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_balance_formatters.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_budget_sheet_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Calculation breakdown card for today's calorie budget.
class DiaryDailyBudgetTodayCard extends StatelessWidget {
  /// Creates the today calculation card.
  const DiaryDailyBudgetTodayCard({
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

    return DiaryDailyBudgetSheetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.diaryBudgetDetailsTodaySectionTitle,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          if (data.hasExpectedActivity) ...[
            DiaryDailyBudgetRow(
              label: l10n.diaryBudgetDetailsBaseGoalWithoutActivityLabel,
              value: formatDiaryKcal(
                numberFormat,
                data.baseGoalWithoutActivityKcal,
                unit,
              ),
            ),
            DiaryDailyBudgetRow(
              label: l10n.diaryBudgetDetailsExpectedActivityLabel,
              value: '+${formatDiaryKcal(
                numberFormat,
                data.expectedActivityKcal,
                unit,
              )}',
              valueColor: accents.activityFor(colors.brightness),
            ),
          ] else ...[
            DiaryDailyBudgetRow(
              label: l10n.diaryBudgetDetailsBaseGoalLabel,
              value: formatDiaryKcal(numberFormat, data.baseGoalKcal, unit),
            ),
          ],
          if (data.hasExceededActivity)
            DiaryDailyBudgetRow(
              label: l10n.diaryBudgetDetailsExtraSportLabel,
              value: formatDiarySignedKcal(
                data.extraSportKcal,
                numberFormat,
                unit,
              ),
              valueColor: accents.activityFor(colors.brightness),
            ),
          if (data.carryoverKcal.round() != 0)
            DiaryDailyBudgetRow(
              label: l10n.diaryBudgetDetailsCarryoverLabel,
              value: formatDiarySignedKcal(
                data.carryoverKcal,
                numberFormat,
                unit,
              ),
              valueColor: data.carryoverKcal > 0
                  ? primary
                  : accents.activityFor(colors.brightness),
            ),
          const Divider(height: AppSpacing.md),
          DiaryDailyBudgetRow(
            label: l10n.diaryBudgetDetailsEffectiveGoalLabel,
            value: formatDiaryKcal(numberFormat, data.targetKcal, unit),
            isBold: true,
          ),
          DiaryDailyBudgetRow(
            label: l10n.diaryBudgetDetailsEatenLabel,
            value: '-${formatDiaryKcal(numberFormat, data.eatenKcal, unit)}',
            valueColor: colors.onSurfaceVariant,
          ),
          const Divider(height: AppSpacing.md),
          DiaryDailyBudgetRow(
            label: l10n.diaryBudgetDetailsLeftLabel,
            value: data.isHeartDay
                ? l10n.diaryBalanceHeartDayValue
                : formatDiaryKcal(numberFormat, data.dayLeftKcal, unit),
            isBold: true,
            isHighlight: true,
            valueColor: data.isHeartDay
                ? accents.heartFor(colors.brightness)
                : primary,
          ),
        ],
      ),
    );
  }
}
