import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/macro_goal_settings_controller.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';

/// Resolves daily macro targets using user preferences and calorie goal.
///
/// When [carryoverKcal] is non-zero, applies the 75/25 carbs/fat split and
/// physiological safety limits (constant protein, fat floor, carbs floor).
DiaryMacroTargets resolveDiaryMacroTargets(
  Ref ref, {
  required double goalKcal,
  double carryoverKcal = 0,
}) {
  final macroSettings = ref.read(macroGoalSettingsControllerProvider);
  final goalSettings = ref.read(calorieGoalControllerProvider).value;
  final profile = goalSettings?.calculatorProfile;
  final isMale =
      (profile?.sex ?? CalorieCalculatorSex.male) == CalorieCalculatorSex.male;
  final weightKg = profile?.weightKg ?? (isMale ? 80.0 : 65.0);

  final baseTargets = DiaryMacroTargets.calculate(
    goalKcal: goalKcal,
    weightKg: weightKg,
    proteinGramsPerKg: macroSettings.effectiveProteinMultiplier(isMale: isMale),
    fatGramsPerKg: macroSettings.effectiveFatMultiplier(isMale: isMale),
  );

  if (carryoverKcal == 0) {
    return baseTargets;
  }

  return baseTargets.applyCarryover(
    carryoverKcal: carryoverKcal,
    weightKg: weightKg,
    baseGoalKcal: goalKcal,
  );
}
