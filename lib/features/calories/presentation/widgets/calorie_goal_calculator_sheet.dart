import 'package:flutter/material.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_flow.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_learned_tdee_goal_sheet.dart';

/// Show calorie goal calculator sheet.
Future<void> showCalorieGoalCalculatorSheet(
  BuildContext context, {
  required CalorieGoalSettings initialSettings,
  bool preferLearnedTdee = true,
}) {
  if (preferLearnedTdee && initialSettings.hasLearnedTdee) {
    return showCalorieLearnedTdeeGoalSheet(
      context,
      initialSettings: initialSettings,
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return CalorieGoalCalculatorFlow(
        initialSettings: initialSettings,
      );
    },
  );
}
