import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/controllers/'
    'calorie_entry_editor_controller.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_flow_handler.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Actions of the entry details sheet that save at once and offer an undo.
///
/// Undo callbacks may run after the sheet closed, so they only use the
/// keep-alive editor controller, never the sheet's `ref` or `context`.
abstract final class CalorieEntryDetailsActions {
  /// Saves [updated] in place of [previous]. Returns whether it saved.
  ///
  /// [onUndone] runs after the undo restored [previous].
  static Future<bool> saveChange(
    BuildContext context, {
    required CalorieEntryEditorController controller,
    required CalorieEntry previous,
    required CalorieEntry updated,
    required VoidCallback onUndone,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await controller.saveEntry(entry: updated, isEditing: true);
    if (!context.mounted) {
      return saved;
    }
    _showResult(
      messenger,
      l10n,
      succeeded: saved,
      successMessage: l10n.caloriesEntryUpdatedMessage,
      failureMessage: l10n.caloriesSaveFailed,
      onUndo: () async {
        await controller.saveEntry(entry: previous, isEditing: true);
        onUndone();
      },
    );
    return saved;
  }

  /// Logs [repeated] as a new entry and closes the sheet.
  static Future<void> eatAgain(
    BuildContext context, {
    required CalorieEntryEditorController controller,
    required CalorieEntry repeated,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await controller.saveEntry(entry: repeated);
    if (!context.mounted) {
      return;
    }
    if (saved) {
      CalorieEntryEditorFlowHandler.maybePopRootNavigator(
        context,
        isEditing: true,
      );
    }
    _showResult(
      messenger,
      l10n,
      succeeded: saved,
      successMessage: l10n.caloriesEatAgainDoneMessage,
      failureMessage: l10n.caloriesSaveFailed,
      onUndo: () =>
          controller.deleteEntry(entry: repeated, restoreToInventory: false),
    );
  }

  /// Removes [entry] and closes the sheet. Entries with stock to return go
  /// through the return-to-inventory dialogs instead of an undo.
  static Future<void> remove(
    BuildContext context, {
    required CalorieEntryEditorController controller,
    required CalorieEntry entry,
  }) async {
    if (entry.canRestoreToInventory || entry.canReturnPreparedMealToInventory) {
      await CalorieEntryEditorFlowHandler.returnEntryToInventory(
        context,
        entry: entry,
        controller: controller,
        onDeleted: () => CalorieEntryEditorFlowHandler.maybePopRootNavigator(
          context,
          isEditing: true,
        ),
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final result = await controller.deleteEntry(
      entry: entry,
      restoreToInventory: false,
    );
    if (!context.mounted) {
      return;
    }
    if (result.isSuccess) {
      CalorieEntryEditorFlowHandler.maybePopRootNavigator(
        context,
        isEditing: true,
      );
    }
    _showResult(
      messenger,
      l10n,
      succeeded: result.isSuccess,
      successMessage: l10n.caloriesEntryDeletedMessage,
      failureMessage: l10n.caloriesDeleteFailed,
      onUndo: () => controller.saveEntry(entry: entry),
    );
  }

  static void _showResult(
    ScaffoldMessengerState messenger,
    AppLocalizations l10n, {
    required bool succeeded,
    required String successMessage,
    required String failureMessage,
    required Future<void> Function() onUndo,
  }) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(succeeded ? successMessage : failureMessage),
          action: succeeded
              ? SnackBarAction(
                  label: l10n.commonUndoAction,
                  onPressed: () => unawaited(onUndo()),
                )
              : null,
        ),
      );
  }
}
