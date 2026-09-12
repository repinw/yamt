import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Slider that derives lose, maintain, or gain from a target weight.
class CalorieTargetWeightSelector extends StatelessWidget {
  /// Creates the target-weight selector.
  const CalorieTargetWeightSelector({
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.goalMode,
    required this.onChanged,
    super.key,
  });

  /// Latest measured weight.
  final double currentWeightKg;

  /// Currently selected target weight.
  final double targetWeightKg;

  /// Goal mode derived from the target.
  final CalorieGoalMode goalMode;

  /// Receives the rounded target and its derived goal mode.
  final void Function(double targetWeightKg, CalorieGoalMode mode) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final minWeight = math.max<double>(1, currentWeightKg - 50);
    final maxWeight = math.min<double>(700, currentWeightKg + 50);
    final target = targetWeightKg.clamp(minWeight, maxWeight);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.caloriesNewGoalCurrentWeight(_formatWeight(currentWeightKg)),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '${l10n.caloriesCalculatorTargetWeightLabel}: '
          '${_formatWeight(target)} kg',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Slider(
          value: target,
          min: minWeight,
          max: maxWeight,
          divisions: ((maxWeight - minWeight) * 10).round(),
          label: '${_formatWeight(target)} kg',
          onChanged: (value) => onChanged(value, modeForTarget(value)),
        ),
        Text(_modeLabel(l10n), style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }

  /// Resolves the goal mode represented by [targetWeightKg].
  CalorieGoalMode modeForTarget(double targetWeightKg) {
    if (targetWeightKg < currentWeightKg - 0.05) return CalorieGoalMode.lose;
    if (targetWeightKg > currentWeightKg + 0.05) return CalorieGoalMode.gain;
    return CalorieGoalMode.maintain;
  }

  String _modeLabel(AppLocalizations l10n) => switch (goalMode) {
    CalorieGoalMode.lose => l10n.caloriesCalculatorGoalModeLose,
    CalorieGoalMode.maintain => l10n.caloriesCalculatorGoalModeMaintain,
    CalorieGoalMode.gain => l10n.caloriesCalculatorGoalModeGain,
  };

  String _formatWeight(double value) {
    return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
  }
}
