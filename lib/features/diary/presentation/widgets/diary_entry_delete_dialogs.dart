import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The button of [showDiaryEntryReturnToInventoryDialog] that gives the
/// stock back.
const diaryEntryReturnToInventoryButtonKey = Key(
  'diary_entry_return_to_inventory_button',
);

/// Asks whether removing [entry] gives its stock back to the Vorrat:
/// true for yes, false for removing only the entry, null for cancel.
Future<bool?> showDiaryEntryReturnToInventoryDialog(
  BuildContext context, {
  required CalorieEntry entry,
}) {
  final l10n = AppLocalizations.of(context)!;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.caloriesRemoveEntryDialogTitle),
        content: Text(
          entry.canReturnPreparedMealToInventory
              ? l10n.caloriesRemoveEntryPreparedMealMessage
              : l10n.caloriesRemoveEntryDialogMessage,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.inventoryReceiptReviewCancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.caloriesRemoveEntryOnlyAction),
          ),
          FilledButton(
            key: diaryEntryReturnToInventoryButtonKey,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.caloriesRemoveAndRestoreAction),
          ),
        ],
      );
    },
  );
}

/// Asks whether to remove [entry] although its stock source is gone.
Future<bool?> showDiaryEntryMissingInventorySourceDialog(
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
