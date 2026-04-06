import 'package:flutter/material.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_flow.dart';

Future<void> showCalorieGoalCalculatorSheet(
  BuildContext context, {
  required CalorieGoalSettings initialSettings,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return CalorieGoalCalculatorFlow(
        initialSettings: initialSettings,
        presentation: CalorieGoalCalculatorFlowPresentation.bottomSheet,
      );
    },
  );
}
