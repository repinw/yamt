import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/macro_goal_settings_controller.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target_resolver.dart';
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

    // The carryover follows the same rules as the day's own kcal: the macros
    // of goal plus carryover. Protein keeps the weekly average as its base.
    final macros = resolveMacroDayTargets(
      macroSettings: macroSettings,
      profile: profile,
      macroWeightKg: macroWeightKg,
      goalKcal: goalKcal + carryoverKcal,
      baseGoalKcal: settings?.baseGoalKcalForDay(day) ?? goalKcal,
      // A training day set only for this day counts too, not only the
      // weekly schedule.
      hasTrainingDays:
          (dayProfile?.trainingWeekdays.isNotEmpty ?? false) || isTraining,
      isLosingWeight: dayProfile?.goalMode == CalorieGoalMode.lose,
    );

    final isPause = settings?.isPauseDay(day) ?? false;

    return DailyNutritionTarget(
      date: day,
      goalKcal: goalKcal + carryoverKcal,
      carbsGrams: macros.carbs,
      proteinGrams: macros.protein,
      fatGrams: macros.fat,
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
