import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_amount_unit_l10n.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_discard_reason_dialog.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_item_remove_dialog.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/inventory_item_row/inventory_item_amount_input_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Removes a stock item: asks whether it was discarded, eaten elsewhere, or
/// should be deleted, then reduces or deletes it.
///
/// The dialogs open on [run]'s context. The undo snackbar goes to
/// `messenger`, which outlives that context.
abstract final class InventoryItemRemoveFlow {
  /// Runs the remove dialogs for [item]. Returns whether the item changed;
  /// false when the user cancelled or saving failed.
  static Future<bool> run({
    required BuildContext context,
    required WidgetRef ref,
    required InventoryItem item,
    required ScaffoldMessengerState messenger,
  }) async {
    final maxAmount = consumableInventoryAmount(item);
    final choice = await showInventoryItemRemoveDialog(
      context,
      itemName: item.name,
      canReduceAmount: maxAmount != null,
    );
    if (choice == null) {
      return false;
    }
    await _afterDialog();
    if (!context.mounted) {
      return false;
    }

    return await switch (choice) {
      InventoryItemRemovalChoice.deleteCompletely => _delete(
        context,
        ref,
        item,
        messenger,
      ),
      InventoryItemRemovalChoice.discarded when maxAmount != null => _discard(
        context,
        ref,
        item,
        maxAmount,
        messenger,
      ),
      InventoryItemRemovalChoice.consumedElsewhere when maxAmount != null =>
        _consumeElsewhere(context, ref, item, maxAmount, messenger),
      _ => Future.value(false),
    };
  }

  static Future<bool> _delete(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
    ScaffoldMessengerState messenger,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final hubMessenger = ScaffoldMessenger.of(context);
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final deleted = await _guard(() => controller.deleteItem(item.id));
    return _report(
      hubMessenger,
      messenger,
      failure: l10n.inventoryItemActionFailed,
      succeeded: deleted ?? false,
      message: l10n.inventoryItemDeletedMessage,
      onUndo: controller.undoLastDeletedItem,
    );
  }

  static Future<bool> _discard(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
    int maxAmount,
    ScaffoldMessengerState messenger,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await showInventoryDiscardReasonDialog(
      context,
      itemName: item.name,
    );
    if (reason == null) {
      return false;
    }
    await _afterDialog();
    if (!context.mounted) {
      return false;
    }
    final amount = await _promptForAmount(
      context,
      item,
      maxAmount,
      l10n.inventoryItemRemoveDiscardAction,
    );
    if (amount == null) {
      return false;
    }
    await _afterDialog();
    if (!context.mounted) {
      return false;
    }

    final hubMessenger = ScaffoldMessenger.of(context);
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final result = await _guard(
      () => controller.throwAwayItemDetailed(item.id, amount, reason),
    );
    return _report(
      hubMessenger,
      messenger,
      failure: l10n.inventoryItemActionFailed,
      succeeded: result != null,
      message: l10n.inventoryItemRemovedMessage,
      onUndo: () => controller.undoThrowAwayItem(
        itemId: item.id,
        amount: result!.removedAmount,
        discardEventId: result.discardEventId,
      ),
    );
  }

  static Future<bool> _consumeElsewhere(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
    int maxAmount,
    ScaffoldMessengerState messenger,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final amount = await _promptForAmount(
      context,
      item,
      maxAmount,
      l10n.inventoryItemRemoveConsumeElsewhereAction,
    );
    if (amount == null) {
      return false;
    }
    await _afterDialog();
    if (!context.mounted) {
      return false;
    }

    final hubMessenger = ScaffoldMessenger.of(context);
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final result = await _guard(
      () => controller.eatItemDetailed(item.id, amount),
    );
    return _report(
      hubMessenger,
      messenger,
      failure: l10n.inventoryItemActionFailed,
      succeeded: result != null,
      message: l10n.inventoryItemRemovedMessage,
      onUndo: () =>
          controller.restoreConsumedItem(item.id, result!.removedAmount),
    );
  }

  /// Shows [message] with its undo on [messenger] after a change, or
  /// [failure] on [hubMessenger], whose page stays open. Returns [succeeded].
  static bool _report(
    ScaffoldMessengerState hubMessenger,
    ScaffoldMessengerState messenger, {
    required bool succeeded,
    required String message,
    required String failure,
    required Future<bool> Function() onUndo,
  }) {
    if (!succeeded) {
      if (hubMessenger.mounted) {
        hubMessenger.showAppSnackBar(failure, tone: AppSnackBarTone.error);
      }
      return false;
    }
    if (messenger.mounted) {
      messenger.showAppSnackBar(message, onUndo: onUndo);
    }
    return true;
  }

  static Future<int?> _promptForAmount(
    BuildContext context,
    InventoryItem item,
    int maxAmount,
    String action,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final unit = item.usesAmountProgress ? item.amountUnit : null;
    return showDialog<int>(
      context: context,
      builder: (context) => InventoryItemAmountInputDialog(
        title: action,
        confirmLabel: action,
        cancelLabel: l10n.inventoryReceiptReviewCancelAction,
        fieldLabel: unit == null
            ? l10n.inventoryReceiptReviewFieldQuantity
            : l10n.inventoryReceiptReviewFieldWeight,
        invalidAmountMessage: l10n.inventoryReceiptReviewInvalidNumber,
        maxAmount: maxAmount,
        quickFillLabel: l10n.inventoryAmountDialogAllRemainingAction,
        suffixText: unit?.localizedName(l10n),
        amountUnit: unit,
        amountScale: unit == null ? 1 : item.amountScale,
      ),
    );
  }

  /// Waits until the closed dialog left the tree, so the next dialog opens
  /// on a settled route.
  static Future<void> _afterDialog() async {
    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
  }

  static Future<T?> _guard<T>(Future<T?> Function() action) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      developer.log(
        'Removing the item failed.',
        name: 'InventoryItemRemoveFlow',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
