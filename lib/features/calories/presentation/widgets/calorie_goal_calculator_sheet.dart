import 'package:flutter/material.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_reset_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_learned_tdee_goal_sheet.dart';

enum _CalorieGoalCalculatorSheetRoute {
  learnedTdee,
  fullCalculator,
}

/// Show calorie goal calculator sheet.
Future<void> showCalorieGoalCalculatorSheet(
  BuildContext context, {
  required CalorieGoalSettings initialSettings,
  bool preferLearnedTdee = true,
  bool useRootNavigator = false,
}) {
  final route = _resolveCalorieGoalCalculatorSheetRoute(
    initialSettings: initialSettings,
    preferLearnedTdee: preferLearnedTdee,
  );

  return switch (route) {
    _CalorieGoalCalculatorSheetRoute.learnedTdee =>
      showCalorieLearnedTdeeGoalSheet(
        context,
        initialSettings: initialSettings,
        useRootNavigator: useRootNavigator,
      ),
    _CalorieGoalCalculatorSheetRoute.fullCalculator =>
      showCalorieGoalCalculatorResetSheet(
        context,
        initialSettings: initialSettings,
        useRootNavigator: useRootNavigator,
      ),
  };
}

_CalorieGoalCalculatorSheetRoute _resolveCalorieGoalCalculatorSheetRoute({
  required CalorieGoalSettings initialSettings,
  required bool preferLearnedTdee,
}) {
  if (preferLearnedTdee && initialSettings.hasLearnedTdee) {
    return _CalorieGoalCalculatorSheetRoute.learnedTdee;
  }
  return _CalorieGoalCalculatorSheetRoute.fullCalculator;
}
