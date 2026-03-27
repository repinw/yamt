import 'package:flutter/material.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows the calorie-goal dialog and persists the selected action.
Future<void> showCalorieGoalDialog({
  required BuildContext context,
  required double currentGoal,
  required Future<bool> Function(double dailyKcalGoal) onSaveGoal,
  required Future<bool> Function() onClearGoal,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(
    text: currentGoal.toStringAsFixed(0),
  );
  double? parsedGoal;
  String? errorText;

  final action = await showDialog<_GoalDialogAction>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l10n.caloriesGoalDialogTitle),
            content: TextField(
              key: CalorieGoalDialogKeys.valueField,
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.caloriesGoalFieldLabel,
                errorText: errorText,
              ),
            ),
            actions: <Widget>[
              TextButton(
                key: CalorieGoalDialogKeys.clearButton,
                onPressed: () =>
                    Navigator.of(context).pop(_GoalDialogAction.clear),
                child: Text(l10n.caloriesGoalClearAction),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.inventoryReceiptReviewCancelAction),
              ),
              FilledButton(
                key: CalorieGoalDialogKeys.saveButton,
                onPressed: () {
                  parsedGoal = double.tryParse(
                    controller.text.trim().replaceAll(',', '.'),
                  );
                  if (parsedGoal == null || parsedGoal! <= 0) {
                    setState(() {
                      errorText = l10n.caloriesGoalInvalidValue;
                    });
                    return;
                  }
                  Navigator.of(context).pop(_GoalDialogAction.save);
                },
                child: Text(l10n.caloriesGoalSaveAction),
              ),
            ],
          );
        },
      );
    },
  );

  if (!context.mounted || action == null) {
    controller.dispose();
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  switch (action) {
    case _GoalDialogAction.save:
      final goal = parsedGoal;
      if (goal == null) {
        controller.dispose();
        return;
      }
      final saved = await onSaveGoal(goal);
      if (!context.mounted || saved) {
        controller.dispose();
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.caloriesGoalSaveFailed)),
      );
    case _GoalDialogAction.clear:
      final cleared = await onClearGoal();
      if (!context.mounted || cleared) {
        controller.dispose();
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.caloriesGoalClearFailed)),
      );
  }

  controller.dispose();
}

enum _GoalDialogAction { save, clear }
