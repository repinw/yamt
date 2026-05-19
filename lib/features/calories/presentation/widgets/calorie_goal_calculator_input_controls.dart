import 'package:flutter/material.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Numeric text field used inside the calorie-goal calculator onboarding.
class CalorieGoalCalculatorNumberField extends StatelessWidget {
  /// The calorie goal calculator number field.
  const CalorieGoalCalculatorNumberField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.onChanged,
    super.key,
    this.autofocus = false,
    this.hintText,
    this.errorText,
    this.keyboardType,
  });

  /// The field key.
  final Key fieldKey;

  /// The controller.
  final TextEditingController controller;

  /// The label.
  final String label;

  /// The hint text.
  final String? hintText;

  /// The error text.
  final String? errorText;

  /// The autofocus.
  final bool autofocus;

  /// The on changed.
  final ValueChanged<String> onChanged;

  /// The keyboard type.
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
  /// The calorie goal calculator sex segmented control.
  const CalorieGoalCalculatorSexSegmentedControl({
    required this.selectedSex,
    required this.onSelected,
    super.key,
  });

  /// The selected sex.
  final CalorieCalculatorSex selectedSex;

  /// The on selected.
  final ValueChanged<CalorieCalculatorSex> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SegmentedButton<CalorieCalculatorSex>(
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
  /// The calorie goal calculator goal mode segmented control.
  const CalorieGoalCalculatorGoalModeSegmentedControl({
    required this.selectedGoalMode,
    required this.onSelected,
    super.key,
  });

  /// The selected goal mode.
  final CalorieGoalMode selectedGoalMode;

  /// The on selected.
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
