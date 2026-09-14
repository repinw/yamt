import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _deleteUndoSnackBarDuration = Duration(seconds: 5);

/// Handles item deletion with undo SnackBar feedback.
@Dependencies([
  InventoryItemsController,
])
class InventoryItemDeleteFlow {
  const InventoryItemDeleteFlow._();

  /// Deletes an inventory item and shows an undo snackbar.
  static Future<bool> deleteWithUndo({
    required BuildContext context,
    required WidgetRef ref,
    required String itemId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final deleted = await controller.deleteItem(itemId);
    if (!deleted || !context.mounted) {
      return deleted;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: _deleteUndoSnackBarDuration,
          persist: false,
          content: Text(l10n.inventoryItemDeletedMessage),
          action: SnackBarAction(
            label: l10n.commonUndoAction,
            onPressed: () {
              unawaited(undoDelete(context: context, ref: ref));
            },
          ),
        ),
      );
    return true;
  }

  /// Restores the last deleted item.
  static Future<void> undoDelete({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final restored = await ref
        .read(inventoryItemsControllerProvider.notifier)
        .undoLastDeletedItem();
    if (!context.mounted) {
      return;
    }
    if (restored) {
      messenger.hideCurrentSnackBar();
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.inventoryItemActionFailed)),
      );
  }
}
