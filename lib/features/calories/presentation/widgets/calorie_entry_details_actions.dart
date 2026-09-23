import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_stock_adjustment.dart';
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
      succeeded: saved,
      successMessage: l10n.caloriesEntryUpdatedMessage,
      failureMessage: l10n.caloriesSaveFailed,
      onUndo: () async {
        final restored = await controller.saveEntry(
          entry: previous,
          isEditing: true,
        );
        if (restored) {
          onUndone();
        }
        return restored;
      },
    );
    return saved;
  }

  /// Changes the consumed amount of [entry] to [amount]. Returns whether it
  /// saved.
  ///
  /// The snackbar reports how far the inventory stock could follow, and the
  /// undo puts both the entry and the stock back.
  static Future<bool> changeAmount(
    BuildContext context, {
    required CalorieEntryEditorController controller,
    required CalorieEntry entry,
    required double amount,
    required VoidCallback onUndone,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final result = await controller.changeAmount(entry: entry, amount: amount);
    if (!context.mounted) {
      return result.saved;
    }
    _showResult(
      messenger,
      succeeded: result.saved,
      successMessage: _amountChangeMessage(l10n, result.status),
      failureMessage: l10n.caloriesSaveFailed,
      onUndo: () async {
        final undo = await controller.changeAmount(
          entry: result.entry,
          amount: entry.consumedAmount,
        );
        if (undo.saved) {
          onUndone();
        }
        return undo.saved;
      },
    );
    return result.saved;
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
      succeeded: saved,
      successMessage: l10n.caloriesEatAgainDoneMessage,
      failureMessage: l10n.caloriesSaveFailed,
      onUndo: () async {
        final result = await controller.deleteEntry(
          entry: repeated,
          restoreToInventory: false,
        );
        return result.isSuccess;
      },
    );
  }

  /// Removes [entry] and closes the sheet. Entries with stock to return ask
  /// first whether the stock goes back to the inventory.
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
      succeeded: result.isSuccess,
      successMessage: l10n.caloriesEntryDeletedMessage,
      failureMessage: l10n.caloriesDeleteFailed,
      onUndo: () => controller.saveEntry(entry: entry),
    );
  }

  static String _amountChangeMessage(
    AppLocalizations l10n,
    CalorieInventoryStockAdjustmentStatus status,
  ) {
    return switch (status) {
      CalorieInventoryStockAdjustmentStatus.stockExhausted =>
        l10n.caloriesEntryAmountStockExhaustedMessage,
      CalorieInventoryStockAdjustmentStatus.sourceMissing =>
        l10n.caloriesEntryAmountSourceMissingMessage,
      CalorieInventoryStockAdjustmentStatus.applied ||
      CalorieInventoryStockAdjustmentStatus.stockUnchanged =>
        l10n.caloriesEntryUpdatedMessage,
    };
  }

  static void _showResult(
    ScaffoldMessengerState messenger, {
    required bool succeeded,
    required String successMessage,
    required String failureMessage,
    required Future<bool> Function() onUndo,
  }) {
    if (!succeeded) {
      messenger.showAppSnackBar(failureMessage, tone: AppSnackBarTone.error);
      return;
    }
    messenger.showAppSnackBar(successMessage, onUndo: onUndo);
  }
}
