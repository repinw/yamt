import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_eating_window_dialog.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Result card showing BMR, TDEE, and the final daily target.
class CalorieGoalCalculatorResultsCard extends StatelessWidget {
  /// The calorie goal calculator results card.
  const CalorieGoalCalculatorResultsCard({
    required this.calculation,
    super.key,
  });

  /// The calculation.
  final CalorieGoalCalculationResult calculation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final kcalUnit = l10n.caloriesUnitKcal;

    return DecoratedBox(
      key: CalorieGoalCalculatorSheetKeys.resultsCard,
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppInventoryEditorial.cardRadius),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.caloriesCalculatorResultsTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            _ResultRow(
              label: l10n.caloriesCalculatorBmrLabel,
              value:
                  '${numberFormat.format(calculation.bmrKcal.round())} '
                  '$kcalUnit',
            ),
            const SizedBox(height: AppSpacing.sm),
            _ResultRow(
              label: l10n.caloriesCalculatorTdeeLabel,
              value:
                  '${numberFormat.format(calculation.tdeeKcal.round())} '
                  '$kcalUnit',
            ),
            const SizedBox(height: AppSpacing.sm),
            _ResultRow(
              label: l10n.caloriesCalculatorDailyGoalLabel,
              value:
                  '${numberFormat.format(calculation.finalGoalKcal.round())} '
                  '$kcalUnit',
            ),
          ],
        ),
      ),
    );
  }
}

/// Warning card shown when the calculated target is clamped for safety.
class CalorieGoalCalculatorWarningCard extends StatelessWidget {
  /// The calorie goal calculator warning card.
  const CalorieGoalCalculatorWarningCard({required this.message, super.key});

  /// The message.
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      key: CalorieGoalCalculatorSheetKeys.warningCard,
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.onErrorContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Defines calorie goal calculator goal start card.
class CalorieGoalCalculatorGoalStartCard extends StatelessWidget {
  /// The calorie goal calculator goal start card.
  const CalorieGoalCalculatorGoalStartCard({
    required this.goalStartAt,
    required this.onChangeRequested,
    super.key,
    this.enabled = true,
  });

  /// The goal start at.
  final DateTime goalStartAt;

  /// The on change requested.
  final VoidCallback onChangeRequested;

  /// The enabled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale).add_Hm();

    return DecoratedBox(
      key: CalorieGoalCalculatorSheetKeys.goalStartCard,
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.caloriesCalculatorGoalStartLabel,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              dateFormat.format(goalStartAt),
              key: CalorieGoalCalculatorSheetKeys.goalStartValue,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.caloriesCalculatorGoalStartHint,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              key: CalorieGoalCalculatorSheetKeys.goalStartChangeButton,
              onPressed: enabled ? onChangeRequested : null,
              icon: const Icon(Icons.schedule_rounded),
              label: Text(l10n.caloriesCalculatorGoalStartChangeAction),
            ),
          ],
        ),
      ),
    );
  }
}

/// Defines calorie goal calculator eating window card.
class CalorieGoalCalculatorEatingWindowCard extends StatelessWidget {
  /// The calorie goal calculator eating window card.
  const CalorieGoalCalculatorEatingWindowCard({
    required this.startMinuteOfDay,
    required this.endMinuteOfDay,
    required this.onChangeRequested,
    super.key,
    this.enabled = true,
  });

  /// The start minute of day.
  final int startMinuteOfDay;

  /// The end minute of day.
  final int endMinuteOfDay;

  /// The on change requested.
  final VoidCallback onChangeRequested;

  /// The enabled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      key: CalorieGoalCalculatorSheetKeys.eatingWindowCard,
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.caloriesCalculatorEatingWindowLabel,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              formatEatingWindowLabel(
                context,
                startMinuteOfDay: startMinuteOfDay,
                endMinuteOfDay: endMinuteOfDay,
              ),
              key: CalorieGoalCalculatorSheetKeys.eatingWindowValue,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.caloriesCalculatorEatingWindowHint,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              key: CalorieGoalCalculatorSheetKeys.eatingWindowChangeButton,
              onPressed: enabled ? onChangeRequested : null,
              icon: const Icon(Icons.schedule_rounded),
              label: Text(l10n.caloriesCalculatorGoalStartChangeAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
