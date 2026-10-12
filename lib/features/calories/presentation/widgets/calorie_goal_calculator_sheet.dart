import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_reset_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_learned_tdee_goal_sheet.dart';

enum _CalorieGoalCalculatorSheetRoute { learnedTdee, fullCalculator }

/// Show calorie goal calculator sheet.
///
/// Completes with whether the sheet saved a goal. With [showBackButton], an
/// arrow at the top closes the sheet without saving.
Future<bool> showCalorieGoalCalculatorSheet(
  BuildContext context, {
  required CalorieGoalSettings initialSettings,
  bool preferLearnedTdee = true,
  bool useRootNavigator = true,
  bool startsNewGoal = false,
  bool showBackButton = false,
  double? currentWeightKg,
}) {
  final route = _resolveCalorieGoalCalculatorSheetRoute(
    initialSettings: initialSettings,
    preferLearnedTdee: preferLearnedTdee,
    startsNewGoal: startsNewGoal,
  );

  return switch (route) {
    _CalorieGoalCalculatorSheetRoute.learnedTdee =>
      showCalorieLearnedTdeeGoalSheet(
        context,
        initialSettings: initialSettings,
        useRootNavigator: useRootNavigator,
        startsNewGoal: startsNewGoal,
        showBackButton: showBackButton,
        currentWeightKg: currentWeightKg,
      ),
    _CalorieGoalCalculatorSheetRoute.fullCalculator =>
      showCalorieGoalCalculatorResetSheet(
        context,
        initialSettings: initialSettings,
        useRootNavigator: useRootNavigator,
        startsNewGoal: startsNewGoal,
        showBackButton: showBackButton,
      ),
  };
}

_CalorieGoalCalculatorSheetRoute _resolveCalorieGoalCalculatorSheetRoute({
  required CalorieGoalSettings initialSettings,
  required bool preferLearnedTdee,
  required bool startsNewGoal,
}) {
  if ((preferLearnedTdee || startsNewGoal) && initialSettings.hasLearnedTdee) {
    return _CalorieGoalCalculatorSheetRoute.learnedTdee;
  }
  return _CalorieGoalCalculatorSheetRoute.fullCalculator;
}
