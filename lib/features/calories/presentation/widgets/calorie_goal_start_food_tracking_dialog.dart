import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Ask whether a same-day goal start should count today for learning.
Future<bool?> showCalorieGoalStartFoodTrackingDialog(
  BuildContext context, {
  required int entryCount,
}) {
  final l10n = AppLocalizations.of(context)!;
  final hasFoodEntries = entryCount > 0;

  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          hasFoodEntries
              ? l10n.caloriesGoalStartFoodTrackingTitle
              : l10n.caloriesGoalStartNoFoodTrackingTitle,
        ),
        content: Text(
          hasFoodEntries
              ? l10n.caloriesGoalStartFoodTrackingBody(entryCount)
              : l10n.caloriesGoalStartNoFoodTrackingBody,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        actions: <Widget>[
          TextButton(
            key: CalorieGoalStartFoodTrackingDialogKeys.noButton,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              hasFoodEntries
                  ? l10n.caloriesGoalStartFoodTrackingNoAction
                  : l10n.caloriesGoalStartFoodTrackingOkAction,
            ),
          ),
          if (hasFoodEntries)
            FilledButton(
              key: CalorieGoalStartFoodTrackingDialogKeys.yesButton,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.caloriesGoalStartFoodTrackingYesAction),
            ),
        ],
      );
    },
  );
}
