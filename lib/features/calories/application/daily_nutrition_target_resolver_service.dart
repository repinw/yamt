import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/macro_goal_settings_controller.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target_resolver.dart';
import 'package:yamt/features/calories/domain/macro_budget_calculator.dart';
import 'package:yamt/features/calories/domain/macro_carryover_calculator.dart';
import 'package:yamt/features/calories/domain/macro_day_targets.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';

part 'daily_nutrition_target_resolver_service.g.dart';

/// Concrete service implementing [DailyNutritionTargetResolver].
class DailyNutritionTargetResolverService
    implements DailyNutritionTargetResolver {
  /// Creates a target resolver service.
  const new({required this.macroSettings, this.goalSettings});

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
    final settings = goalSettings;
    final profile = settings?.calculatorProfile;
    final dayProfile =
        settings?.goalEntryForDay(day)?.calculatorProfile ?? profile;
    final isTraining = settings?.isTrainingDay(day) ?? false;
    final macroWeightKg = settings?.macroWeightKgForDay(day);
    final weightKg = macroCountedWeightKg(
      profile: profile,
      macroWeightKg: macroWeightKg,
    );

    final baseResult = resolveMacroDayTargets(
      macroSettings: macroSettings,
      profile: profile,
      macroWeightKg: macroWeightKg,
      goalKcal: goalKcal,
      baseGoalKcal: settings?.baseGoalKcalForDay(day) ?? goalKcal,
      // A training day set only for this day counts too, not only the
      // weekly schedule.
      hasTrainingDays:
          (dayProfile?.trainingWeekdays.isNotEmpty ?? false) || isTraining,
      isLosingWeight: dayProfile?.goalMode == CalorieGoalMode.lose,
    );

    final adjustedMacros = _applyCarryoverIfNeeded(
      baseResult: baseResult,
      carryoverKcal: carryoverKcal,
      weightKg: weightKg,
      goalKcal: goalKcal,
    );

    final isPause = settings?.isPauseDay(day) ?? false;

    return DailyNutritionTarget(
      date: day,
      goalKcal: goalKcal,
      carbsGrams: adjustedMacros.carbs,
      proteinGrams: adjustedMacros.protein,
      fatGrams: adjustedMacros.fat,
      baseGoalKcal: settings?.dailyKcalGoal ?? goalKcal,
      isTrainingDay: isTraining,
      isPauseDay: isPause,
    );
  }

  @override
  DailyNutritionTarget resolveBaseTarget({
    required DateTime day,
    required double goalKcal,
  }) {
    return resolveTarget(day: day, goalKcal: goalKcal);
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
