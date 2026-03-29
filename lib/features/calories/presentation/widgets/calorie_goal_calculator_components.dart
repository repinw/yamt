import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Numeric text field used inside the calorie-goal calculator onboarding.
class CalorieGoalCalculatorNumberField extends StatelessWidget {
  const CalorieGoalCalculatorNumberField({
    super.key,
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.onChanged,
    this.autofocus = false,
    this.hintText,
    this.errorText,
    this.keyboardType,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      autofocus: autofocus,
      keyboardType:
          keyboardType ?? const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
      ),
    );
  }
}

/// Segmented sex selector for the calorie-goal calculator.
class CalorieGoalCalculatorSexSegmentedControl extends StatelessWidget {
  const CalorieGoalCalculatorSexSegmentedControl({
    super.key,
    required this.selectedSex,
    required this.onSelected,
  });

  final CalorieCalculatorSex selectedSex;
  final ValueChanged<CalorieCalculatorSex> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SegmentedButton<CalorieCalculatorSex>(
      key: CalorieGoalCalculatorSheetKeys.sexSegment,
      showSelectedIcon: false,
      segments: <ButtonSegment<CalorieCalculatorSex>>[
        ButtonSegment<CalorieCalculatorSex>(
          value: CalorieCalculatorSex.male,
          label: Text(l10n.caloriesCalculatorSexMale),
        ),
        ButtonSegment<CalorieCalculatorSex>(
          value: CalorieCalculatorSex.female,
          label: Text(l10n.caloriesCalculatorSexFemale),
        ),
      ],
      selected: <CalorieCalculatorSex>{selectedSex},
      onSelectionChanged: (selection) {
        final nextValue = selection.firstOrNull;
        if (nextValue != null) {
          onSelected(nextValue);
        }
      },
    );
  }
}

/// Segmented goal-mode selector for the calorie-goal calculator.
class CalorieGoalCalculatorGoalModeSegmentedControl extends StatelessWidget {
  const CalorieGoalCalculatorGoalModeSegmentedControl({
    super.key,
    required this.selectedGoalMode,
    required this.onSelected,
  });

  final CalorieGoalMode selectedGoalMode;
  final ValueChanged<CalorieGoalMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SegmentedButton<CalorieGoalMode>(
      key: CalorieGoalCalculatorSheetKeys.goalModeSegment,
      showSelectedIcon: false,
      segments: <ButtonSegment<CalorieGoalMode>>[
        ButtonSegment<CalorieGoalMode>(
          value: CalorieGoalMode.lose,
          label: Text(l10n.caloriesCalculatorGoalModeLose),
        ),
        ButtonSegment<CalorieGoalMode>(
          value: CalorieGoalMode.maintain,
          label: Text(l10n.caloriesCalculatorGoalModeMaintain),
        ),
        ButtonSegment<CalorieGoalMode>(
          value: CalorieGoalMode.gain,
          label: Text(l10n.caloriesCalculatorGoalModeGain),
        ),
      ],
      selected: <CalorieGoalMode>{selectedGoalMode},
      onSelectionChanged: (selection) {
        final nextValue = selection.firstOrNull;
        if (nextValue != null) {
          onSelected(nextValue);
        }
      },
    );
  }
}

/// Result card showing BMR, TDEE, and the final daily target.
class CalorieGoalCalculatorResultsCard extends StatelessWidget {
  const CalorieGoalCalculatorResultsCard({
    super.key,
    required this.calculation,
  });

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
  const CalorieGoalCalculatorWarningCard({super.key, required this.message});

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
