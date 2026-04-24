import 'package:flutter/material.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Show discard-changes confirmation dialog for calorie editor.
Future<bool?> showCalorieEntryDiscardChangesDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.caloriesDiscardChangesDialogTitle),
        content: Text(l10n.caloriesDiscardChangesDialogMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.inventoryReceiptReviewCancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.caloriesDiscardChangesConfirmAction),
          ),
        ],
      );
    },
  );
}

/// Show restore-to-inventory confirmation dialog for calorie entry.
Future<bool?> showCalorieEntryReturnToInventoryDialog(
  BuildContext context, {
  required CalorieEntry entry,
}) {
  final l10n = AppLocalizations.of(context)!;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          entry.canReturnPreparedMealToInventory
              ? l10n.caloriesReturnPreparedMealDialogTitle
              : l10n.caloriesReturnPreparedMealConfirmAction,
        ),
        content: Text(
          entry.canReturnPreparedMealToInventory
              ? l10n.caloriesReturnPreparedMealDialogMessage(entry.name)
              : l10n.caloriesDeleteRestoreInventoryQuestion,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.inventoryReceiptReviewCancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.caloriesReturnPreparedMealConfirmAction),
          ),
        ],
      );
    },
  );
}

/// Show delete-only confirmation when the inventory source is gone.
Future<bool?> showCalorieEntryMissingInventorySourceDialog(
  BuildContext context, {
  required CalorieEntry entry,
}) {
  final l10n = AppLocalizations.of(context)!;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.caloriesMissingInventorySourceDialogTitle),
        content: Text(
          l10n.caloriesMissingInventorySourceDialogMessage(entry.name),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.inventoryReceiptReviewCancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.caloriesDeleteDiaryOnlyConfirmAction),
          ),
        ],
      );
    },
  );
}
