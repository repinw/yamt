import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_amount_unit_l10n.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_delete_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_discard_reason_dialog.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_item_remove_dialog.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/inventory_item_row/inventory_item_amount_input_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Removes a stock item: asks whether it was discarded, eaten elsewhere, or
/// should be deleted, then reduces or deletes it with an undo snackbar.
abstract final class InventoryItemRemoveFlow {
  /// Runs the remove dialogs for [item].
  static Future<void> run({
    required BuildContext context,
    required WidgetRef ref,
    required InventoryItem item,
  }) async {
    final maxAmount = consumableInventoryAmount(item);
    final choice = await showInventoryItemRemoveDialog(
      context,
      itemName: item.name,
      canReduceAmount: maxAmount != null,
    );
    if (choice == null) {
      return;
    }
    await _afterDialog();
    if (!context.mounted) {
      return;
    }

    switch (choice) {
      case InventoryItemRemovalChoice.deleteCompletely:
        await InventoryItemDeleteFlow.deleteWithUndo(
          context: context,
          ref: ref,
          itemId: item.id,
        );
      case InventoryItemRemovalChoice.discarded:
        if (maxAmount != null) {
          await _discard(context, ref, item, maxAmount);
        }
      case InventoryItemRemovalChoice.consumedElsewhere:
        if (maxAmount != null) {
          await _consumeElsewhere(context, ref, item, maxAmount);
        }
    }
  }

  static Future<void> _discard(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
    int maxAmount,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await showInventoryDiscardReasonDialog(
      context,
      itemName: item.name,
    );
    if (reason == null) {
      return;
    }
    await _afterDialog();
    if (!context.mounted) {
      return;
    }
    final amount = await _promptForAmount(
      context,
      item,
      maxAmount,
      l10n.inventoryItemRemoveDiscardAction,
    );
    if (amount == null) {
      return;
    }
    await _afterDialog();
    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final result = await _guard(
      () => controller.throwAwayItemDetailed(item.id, amount, reason),
    );
    if (!messenger.mounted) {
      return;
    }
    if (result == null) {
      messenger.showAppSnackBar(
        l10n.inventoryItemActionFailed,
        tone: AppSnackBarTone.error,
      );
      return;
    }
    messenger.showAppSnackBar(
      l10n.inventoryItemRemovedMessage,
      onUndo: () => controller.undoThrowAwayItem(
        itemId: item.id,
        amount: result.removedAmount,
        discardEventId: result.discardEventId,
      ),
    );
  }

  static Future<void> _consumeElsewhere(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
    int maxAmount,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final amount = await _promptForAmount(
      context,
      item,
      maxAmount,
      l10n.inventoryItemRemoveConsumeElsewhereAction,
    );
    if (amount == null) {
      return;
    }
    await _afterDialog();
    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final result = await _guard(
      () => controller.eatItemDetailed(item.id, amount),
    );
    if (!messenger.mounted) {
      return;
    }
    if (result == null) {
      messenger.showAppSnackBar(
        l10n.inventoryItemActionFailed,
        tone: AppSnackBarTone.error,
      );
      return;
    }
    messenger.showAppSnackBar(
      l10n.inventoryItemRemovedMessage,
      onUndo: () =>
          controller.restoreConsumedItem(item.id, result.removedAmount),
    );
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
