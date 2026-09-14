import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target_resolver.dart';
import 'package:yamt/features/calories/domain/macro_budget_calculator.dart';
import 'package:yamt/features/calories/domain/macro_carryover_calculator.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/macro_goal_settings_controller.dart';

part 'daily_nutrition_target_resolver_service.g.dart';

/// Concrete service implementing [DailyNutritionTargetResolver].
class DailyNutritionTargetResolverService
    implements DailyNutritionTargetResolver {
  /// Creates a target resolver service.
  const DailyNutritionTargetResolverService({
    required this.macroSettings,
    this.goalSettings,
  });

  /// Current macro multiplier settings.
  final MacroGoalSettings macroSettings;

  /// Current calorie goal settings.
  final CalorieGoalSettings? goalSettings;

  @override
  DailyNutritionTarget resolveTarget({
    required DateTime day,
    required double goalKcal,
    double carryoverKcal = 0.0,
  }) {
    final profile = goalSettings?.calculatorProfile;
    final isMale =
        (profile?.sex ?? CalorieCalculatorSex.male) ==
        CalorieCalculatorSex.male;
    final weightKg = profile?.weightKg ?? (isMale ? 80.0 : 65.0);

    final baseResult = MacroBudgetCalculator.calculate(
      goalKcal: goalKcal,
      weightKg: weightKg,
      proteinGramsPerKg: macroSettings.effectiveProteinMultiplier(
        isMale: isMale,
      ),
      fatGramsPerKg: macroSettings.effectiveFatMultiplier(isMale: isMale),
    );

    final adjustedMacros = _applyCarryoverIfNeeded(
      baseResult: baseResult,
      carryoverKcal: carryoverKcal,
      weightKg: weightKg,
      goalKcal: goalKcal,
    );

    final isTraining = goalSettings?.isTrainingDay(day) ?? false;
    final isPause = goalSettings?.isPauseDay(day) ?? false;

    return DailyNutritionTarget(
      date: day,
      goalKcal: goalKcal,
      carbsGrams: adjustedMacros.carbs,
      proteinGrams: adjustedMacros.protein,
      fatGrams: adjustedMacros.fat,
      baseGoalKcal: goalSettings?.dailyKcalGoal ?? goalKcal,
      isTrainingDay: isTraining,
      isPauseDay: isPause,
    );
  }

  @override
  DailyNutritionTarget resolveBaseTarget({
    required DateTime day,
    required double goalKcal,
  }) {
    return resolveTarget(
      day: day,
      goalKcal: goalKcal,
    );
  }

  MacroCalculationResult _applyCarryoverIfNeeded({
    required MacroCalculationResult baseResult,
    required double carryoverKcal,
    required double weightKg,
    required double goalKcal,
  }) {
    if (carryoverKcal == 0.0) {
      return baseResult;
    }
    final delta = MacroCarryoverCalculator.calculateCarryoverDelta(
      baseCarbs: baseResult.carbs,
      baseFat: baseResult.fat,
      carryoverKcal: carryoverKcal,
      weightKg: weightKg,
      baseGoalKcal: goalKcal,
    );
    return MacroCalculationResult(
      carbs: baseResult.carbs + delta.carbsGrams,
      protein: baseResult.protein + delta.proteinGrams,
      fat: baseResult.fat + delta.fatGrams,
    );
  }
}

/// Provides the resolved [DailyNutritionTargetResolver] implementation.
@riverpod
DailyNutritionTargetResolver dailyNutritionTargetResolver(Ref ref) {
  final macroSettings = ref.watch(macroGoalSettingsControllerProvider);
  final goalSettings = ref.watch(calorieGoalControllerProvider).value;
  return DailyNutritionTargetResolverService(
    macroSettings: macroSettings,
    goalSettings: goalSettings,
  );
}
