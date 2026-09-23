import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Handles item deletion with undo SnackBar feedback.
class InventoryItemDeleteFlow {
  const new _();

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

    ScaffoldMessenger.of(context).showAppSnackBar(
      l10n.inventoryItemDeletedMessage,
      onUndo: controller.undoLastDeletedItem,
    );
    return true;
  }
}
