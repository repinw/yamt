import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/macro_budget_calculator.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';
import 'package:yamt/features/calories/domain/macro_reference_weight.dart';

/// The weight that protein and fat count against: [macroWeightKg] capped by
/// the height of [profile], or a default by sex without either.
double macroCountedWeightKg({
  required CalorieCalculatorProfile? profile,
  required double? macroWeightKg,
}) {
  if (profile == null || macroWeightKg == null) {
    return profile?.sex == CalorieCalculatorSex.female ? 65.0 : 80.0;
  }
  return macroReferenceWeightKg(
    weightKg: macroWeightKg,
    heightCm: profile.heightCm,
  );
}

/// Macro targets of one day for [goalKcal], which includes the day's
/// carryover.
///
/// Protein and fat count against [macroCountedWeightKg]. Protein also
/// depends on [baseGoalKcal], training, and a weight loss goal.
MacroCalculationResult resolveMacroDayTargets({
  required MacroGoalSettings macroSettings,
  required CalorieCalculatorProfile? profile,
  required double? macroWeightKg,
  required double goalKcal,
  required double baseGoalKcal,
  required bool hasTrainingDays,
  required bool isLosingWeight,
}) {
  final isMale =
      (profile?.sex ?? CalorieCalculatorSex.male) == CalorieCalculatorSex.male;
  final weightKg = macroCountedWeightKg(
    profile: profile,
    macroWeightKg: macroWeightKg,
  );
  final fatGramsPerKg = macroSettings.effectiveFatMultiplier(isMale: isMale);
  final proteinGrams = macroSettings.resolveProteinGrams(
    referenceWeightKg: weightKg,
    baseGoalKcal: baseGoalKcal,
    fatGrams: weightKg * fatGramsPerKg,
    hasTrainingDays: hasTrainingDays,
    isLosingWeight: isLosingWeight,
  );
  return MacroBudgetCalculator.calculate(
    goalKcal: goalKcal,
    weightKg: weightKg,
    proteinGramsPerKg: proteinGrams / weightKg,
    fatGramsPerKg: fatGramsPerKg,
  );
}
