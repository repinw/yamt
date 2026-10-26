import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Slider that derives lose, maintain, or gain from a target weight.
class CalorieTargetWeightSelector extends StatelessWidget {
  /// Creates the target-weight selector.
  const new({
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.onChanged,
    super.key,
  });

  /// Latest measured weight.
  final double currentWeightKg;

  /// Currently selected target weight.
  final double targetWeightKg;

  /// Receives the rounded target and its derived goal mode.
  final void Function(double targetWeightKg, CalorieGoalMode mode) onChanged;

  @override
  Widget build(BuildContext context) {
    final minWeight = math.max<double>(1, currentWeightKg - 50);
    final maxWeight = math.min<double>(700, currentWeightKg + 50);
    final target = targetWeightKg.clamp(minWeight, maxWeight);
    return Slider(
      value: target,
      min: minWeight,
      max: maxWeight,
      divisions: ((maxWeight - minWeight) * 10).round(),
      label:
          '${_formatWeight(target)} '
          '${AppLocalizations.of(context)!.caloriesUnitKg}',
      onChanged: (value) => onChanged(value, modeForTarget(value)),
    );
  }

  /// Resolves the goal mode represented by [targetWeightKg].
  CalorieGoalMode modeForTarget(double targetWeightKg) {
    if (targetWeightKg < currentWeightKg - 0.05) return CalorieGoalMode.lose;
    if (targetWeightKg > currentWeightKg + 0.05) return CalorieGoalMode.gain;
    return CalorieGoalMode.maintain;
  }

  String _formatWeight(double value) {
    return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
  }
}
