import 'package:flutter/material.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// User decision after a weight target has been reached.
enum CalorieGoalReachedAction {
  /// Keep the current goal through the ongoing seven-day run.
  continueRun,

  /// End the current goal and configure a new one now.
  newGoal,
}

/// Shows the one-time goal-reached prompt.
Future<CalorieGoalReachedAction?> showCalorieGoalReachedDialog(
  BuildContext context,
) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<CalorieGoalReachedAction>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(l10n.caloriesGoalReachedTitle),
      content: Text(l10n.caloriesGoalReachedBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            CalorieGoalReachedAction.continueRun,
          ),
          child: Text(l10n.caloriesGoalReachedContinue),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            CalorieGoalReachedAction.newGoal,
          ),
          child: Text(l10n.caloriesGoalReachedNewGoal),
        ),
      ],
    ),
  );
}
