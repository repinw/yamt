import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_budget_details_data.dart';
import 'package:yamt/l10n/app_localizations.dart';

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
