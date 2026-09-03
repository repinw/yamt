import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_budget_details_data.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_balance_formatters.dart';
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
          _CarryoverDistributionFormulaBox(
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

class _CarryoverDistributionFormulaBox extends StatelessWidget {
  const _CarryoverDistributionFormulaBox({
    required this.data,
    required this.numberFormat,
    required this.unit,
    required this.primary,
  });

  final DiaryDailyBudgetDetailsData data;
  final NumberFormat numberFormat;
  final String unit;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
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
    );
  }
}

/// Row displaying a single previous day's consumed vs goal calories
/// and diff badge.
class DiaryDailyBudgetPreviousDayRow extends StatelessWidget {
  /// Creates the previous day row.
  const DiaryDailyBudgetPreviousDayRow({
    required this.day,
    required this.numberFormat,
    super.key,
  });

  /// Day detail model.
  final DiaryCarryoverDayDetail day;

  /// Locale-aware number format.
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final accents = MetricAccentColors.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final unit = l10n.caloriesUnitKcal;
    final weekday = DateFormat.E(locale).format(day.date);
    final monthDay = DateFormat.MMMd(locale).format(day.date);

    if (day.isHeartDay) {
      return Row(
        children: [
          Expanded(
            child: Text(
              '$weekday, $monthDay',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            Icons.favorite_rounded,
            size: 16,
            color: accents.heartFor(colors.brightness),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            l10n.diaryBudgetDetailsHeartDayLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: accents.heartFor(colors.brightness),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    final diff = day.differenceKcal.round();
    final (diffText, diffColor) = switch (diff) {
      > 0 => (
          '+${numberFormat.format(diff)} $unit '
              '${l10n.diaryBudgetDetailsDaySavedLabel}',
          accents.today,
        ),
      < 0 => (
          '${numberFormat.format(diff)} $unit '
              '${l10n.diaryBudgetDetailsDayOverLabel}',
          accents.activityFor(colors.brightness),
        ),
      _ => (
          '±0 $unit (${l10n.diaryBudgetDetailsDayExactLabel})',
          colors.onSurfaceVariant,
        ),
    };

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$weekday, $monthDay',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${numberFormat.format(day.consumedKcal.round())} / '
                '${numberFormat.format(day.goalKcal.round())} $unit',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          diffText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: diffColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
