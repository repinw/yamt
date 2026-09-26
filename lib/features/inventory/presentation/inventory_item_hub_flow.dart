import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_hub_page.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_remove_flow.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_result.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_item_editor/inventory_receipt_item_editor_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/inventory_item_row/inventory_item_candidate_swap_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the item hub of a stock item and runs what the user picks there.
///
/// Every pick closes the hub first, so the follow-up sheets and snackbars
/// belong to the inventory page and never show a stale item.
abstract final class InventoryItemHubFlow {
  /// Opens the hub for [item].
  static Future<void> open({
    required BuildContext context,
    required WidgetRef ref,
    required InventoryItem item,
    required bool isOnShoppingList,
  }) async {
    final result = await Navigator.of(context, rootNavigator: true)
        .push<InventoryItemHubResult>(
          MaterialPageRoute<InventoryItemHubResult>(
            fullscreenDialog: true,
            builder: (_) => InventoryItemHubPage(
              item: item,
              isOnShoppingList: isOnShoppingList,
            ),
          ),
        );
    if (result == null || !context.mounted) {
      return;
    }

    switch (result) {
      case InventoryItemHubEat(:final request):
        final started = await InventoryItemEatFlow.stageAndComplete(
          context: context,
          container: ref.container,
          item: item,
          request: request,
        );
        if (!started && context.mounted) {
          _showFailure(context);
        }
      case InventoryItemHubPick(action: InventoryItemHubAction.remove):
        await InventoryItemRemoveFlow.run(
          context: context,
          ref: ref,
          item: item,
        );
      case InventoryItemHubPick(
        action: InventoryItemHubAction.addToShoppingList,
      ):
        await _addToShoppingList(context, ref, item);
      case InventoryItemHubPick(action: InventoryItemHubAction.edit):
        await _edit(context, ref, item);
      case InventoryItemHubPick(action: InventoryItemHubAction.replace):
        await _replace(context, ref, item);
    }
  }

  static Future<void> _addToShoppingList(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final revert = await _guard(() => controller.buyAgainItem(item));
    if (!messenger.mounted) {
      return;
    }
    if (revert == null) {
      messenger.showAppSnackBar(
        l10n.inventoryItemActionFailed,
        tone: AppSnackBarTone.error,
      );
      return;
    }
    messenger.showAppSnackBar(
      l10n.inventoryItemBuyAgainSucceeded,
      onUndo: () => controller.undoBuyAgainItem(revert),
    );
  }

  static Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (!item.isFullyAvailable) {
      _showFailure(context, l10n.inventoryItemEditRequiresFullItem);
      return;
    }
    final edited = await showModalBottomSheet<InventoryItem>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (_) => InventoryReceiptItemEditorSheet(
        item: item,
        title: l10n.inventoryItemEditTitle,
        showDiscountFields: false,
        showReviewOnlyFields: false,
      ),
    );
    if (edited == null || edited == item || !context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final saved = await _guard(() => controller.updateItem(edited)) ?? false;
    if (!messenger.mounted) {
      return;
    }
    if (!saved) {
      messenger.showAppSnackBar(
        l10n.inventoryItemActionFailed,
        tone: AppSnackBarTone.error,
      );
      return;
    }
    messenger.showAppSnackBar(
      l10n.inventoryItemUpdatedMessage,
      onUndo: () => controller.updateItem(item),
    );
  }

  static Future<void> _replace(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
  ) async {
    if (!item.isFullyAvailable) {
      _showFailure(
        context,
        AppLocalizations.of(context)!
            .inventoryItemSwapCandidateRequiresFullItem,
      );
      return;
    }
    final request = await showInventoryItemCandidateSwapFlow(
      context: context,
      ref: ref,
      item: item,
    );
    if (request == null || !context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final saved =
        await _guard(
          () => ref
              .read(inventoryItemsControllerProvider.notifier)
              .swapItemCandidate(
                itemId: item.id,
                resolvedProduct: request.resolvedProduct,
                requiresGlobalPersistence: request.requiresGlobalPersistence,
                weight: request.weight,
              ),
        ) ??
        false;
    if (!messenger.mounted) {
      return;
    }
    if (!saved) {
      messenger.showAppSnackBar(
        l10n.inventoryItemActionFailed,
        tone: AppSnackBarTone.error,
      );
    }
  }

  static void _showFailure(BuildContext context, [String? message]) {
    ScaffoldMessenger.of(context).showAppSnackBar(
      message ?? AppLocalizations.of(context)!.inventoryItemActionFailed,
      tone: AppSnackBarTone.error,
    );
  }

  static Future<T?> _guard<T>(Future<T?> Function() action) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      developer.log(
        'Item hub action failed.',
        name: 'InventoryItemHubFlow',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
