import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_onboarding_start.dart';
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
    required this.goalStartDate,
    required this.onChangeRequested,
    super.key,
    this.enabled = true,
  });

  /// The goal start date.
  final DateTime goalStartDate;

  /// The on change requested.
  final VoidCallback onChangeRequested;

  /// The enabled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale);

    return _GoalStartCardShell(
      key: CalorieGoalCalculatorSheetKeys.goalStartCard,
      title: l10n.caloriesCalculatorGoalStartLabel,
      children: [
        Text(
          dateFormat.format(goalStartDate),
          key: CalorieGoalCalculatorSheetKeys.goalStartValue,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        _GoalStartCardHint(text: l10n.caloriesCalculatorGoalStartHint),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          key: CalorieGoalCalculatorSheetKeys.goalStartChangeButton,
          onPressed: enabled ? onChangeRequested : null,
          icon: const Icon(Icons.event_outlined),
          label: Text(l10n.caloriesCalculatorGoalStartChangeAction),
        ),
      ],
    );
  }
}

/// Defines onboarding start card for same-day or future kickoff.
class CalorieGoalCalculatorOnboardingStartCard extends StatelessWidget {
  /// The onboarding start card.
  const CalorieGoalCalculatorOnboardingStartCard({
    required this.goalStartDate,
    required this.catchUpEstimate,
    required this.startNowSelected,
    required this.startLaterSelected,
    required this.onStartNowSelected,
    required this.onStartLaterSelected,
    required this.onChangeFutureDateRequested,
    required this.onCatchUpEstimateSelected,
    super.key,
    this.enabled = true,
  });

  /// Selected goal start date.
  final DateTime goalStartDate;

  /// Selected catch-up estimate.
  final CalorieGoalOnboardingCatchUpEstimate catchUpEstimate;

  /// Whether "start now" is selected.
  final bool startNowSelected;

  /// Whether "start later" is selected.
  final bool startLaterSelected;

  /// Called when user chooses today.
  final VoidCallback onStartNowSelected;

  /// Called when user chooses later start.
  final VoidCallback onStartLaterSelected;

  /// Called when user wants another future day.
  final VoidCallback onChangeFutureDateRequested;

  /// Called when catch-up estimate changes.
  final ValueChanged<CalorieGoalOnboardingCatchUpEstimate>
  onCatchUpEstimateSelected;

  /// Whether controls enabled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale);

    return _GoalStartCardShell(
      key: CalorieGoalCalculatorSheetKeys.goalStartCard,
      title: l10n.caloriesCalculatorOnboardingStartTitle,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              key: CalorieGoalCalculatorSheetKeys.goalStartNowOption,
              label: Text(l10n.caloriesCalculatorOnboardingStartNowAction),
              selected: startNowSelected,
              onSelected: enabled ? (_) => onStartNowSelected() : null,
            ),
            ChoiceChip(
              key: CalorieGoalCalculatorSheetKeys.goalStartLaterOption,
              label: Text(
                l10n.caloriesCalculatorOnboardingStartLaterAction,
              ),
              selected: startLaterSelected,
              onSelected: enabled ? (_) => onStartLaterSelected() : null,
            ),
          ],
        ),
        if (startNowSelected || startLaterSelected)
          const SizedBox(height: AppSpacing.md),
        if (startNowSelected) ...[
          _GoalStartCardHint(
            text: l10n.caloriesCalculatorOnboardingCatchUpLabel,
            isBody: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                key: CalorieGoalCalculatorSheetKeys.catchUpLowOption,
                label: Text(
                  l10n.caloriesCalculatorOnboardingCatchUpLowAction,
                ),
                selected:
                    catchUpEstimate == CalorieGoalOnboardingCatchUpEstimate.low,
                onSelected: enabled
                    ? (_) => onCatchUpEstimateSelected(
                        CalorieGoalOnboardingCatchUpEstimate.low,
                      )
                    : null,
              ),
              ChoiceChip(
                key: CalorieGoalCalculatorSheetKeys.catchUpNormalOption,
                label: Text(
                  l10n.caloriesCalculatorOnboardingCatchUpNormalAction,
                ),
                selected:
                    catchUpEstimate ==
                    CalorieGoalOnboardingCatchUpEstimate.normal,
                onSelected: enabled
                    ? (_) => onCatchUpEstimateSelected(
                        CalorieGoalOnboardingCatchUpEstimate.normal,
                      )
                    : null,
              ),
              ChoiceChip(
                key: CalorieGoalCalculatorSheetKeys.catchUpHighOption,
                label: Text(
                  l10n.caloriesCalculatorOnboardingCatchUpHighAction,
                ),
                selected:
                    catchUpEstimate ==
                    CalorieGoalOnboardingCatchUpEstimate.high,
                onSelected: enabled
                    ? (_) => onCatchUpEstimateSelected(
                        CalorieGoalOnboardingCatchUpEstimate.high,
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _GoalStartCardHint(
            text: l10n.caloriesCalculatorOnboardingCatchUpHint,
          ),
        ] else if (startLaterSelected) ...[
          Text(
            dateFormat.format(goalStartDate),
            key: CalorieGoalCalculatorSheetKeys.goalStartValue,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          _GoalStartCardHint(
            text: l10n.caloriesCalculatorOnboardingStartLaterHint,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            key: CalorieGoalCalculatorSheetKeys.goalStartChangeButton,
            onPressed: enabled ? onChangeFutureDateRequested : null,
            icon: const Icon(Icons.event_outlined),
            label: Text(
              l10n.caloriesCalculatorOnboardingChooseFutureDateAction,
            ),
          ),
        ],
      ],
    );
  }
}

class _GoalStartCardShell extends StatelessWidget {
  const _GoalStartCardShell({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
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
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _GoalStartCardHint extends StatelessWidget {
  const _GoalStartCardHint({
    required this.text,
    this.isBody = false,
  });

  final String text;
  final bool isBody;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final baseStyle = isBody
        ? Theme.of(context).textTheme.bodyMedium
        : Theme.of(context).textTheme.bodySmall;
    return Text(
      text,
      style: baseStyle?.copyWith(color: colors.onSurfaceVariant),
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
