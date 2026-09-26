import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_hub_page.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_remove_flow.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_action.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_item_editor/inventory_receipt_item_editor_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/inventory_item_row/inventory_item_candidate_swap_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the item hub of a stock item and runs what the user picks there.
///
/// Action dialogs and sheets open on top of the hub, so cancelling one
/// returns to the hub. A finished edit, replace or remove closes the hub and
/// reports on the inventory page, which then shows the changed item. Adding
/// to the shopping list keeps the hub open.
abstract final class InventoryItemHubFlow {
  /// Opens the hub for [item].
  static Future<void> open({
    required BuildContext context,
    required WidgetRef ref,
    required InventoryItem item,
    required bool isOnShoppingList,
  }) async {
    final pageMessenger = ScaffoldMessenger.of(context);
    final request = await Navigator.of(context, rootNavigator: true)
        .push<InventoryItemEatRequest>(
          MaterialPageRoute<InventoryItemEatRequest>(
            fullscreenDialog: true,
            builder: (_) => InventoryItemHubPage(
              item: item,
              isOnShoppingList: isOnShoppingList,
              onAction: (hubContext, action) =>
                  _run(hubContext, ref, item, action, pageMessenger),
            ),
          ),
        );
    if (request == null || !context.mounted) {
      return;
    }

    final started = await InventoryItemEatFlow.stageAndComplete(
      context: context,
      container: ref.container,
      item: item,
      request: request,
    );
    if (!started && context.mounted) {
      _showFailure(context);
    }
  }

  static Future<bool> _run(
    BuildContext hubContext,
    WidgetRef ref,
    InventoryItem item,
    InventoryItemHubAction action,
    ScaffoldMessengerState pageMessenger,
  ) {
    return switch (action) {
      InventoryItemHubAction.remove => InventoryItemRemoveFlow.run(
        context: hubContext,
        ref: ref,
        item: item,
        messenger: pageMessenger,
      ),
      InventoryItemHubAction.addToShoppingList => _addToShoppingList(
        hubContext,
        ref,
        item,
      ),
      InventoryItemHubAction.edit => _edit(
        hubContext,
        ref,
        item,
        pageMessenger,
      ),
      InventoryItemHubAction.replace => _replace(hubContext, ref, item),
    };
  }

  /// Adds [item] to the shopping list and reports it on the hub, which stays
  /// open.
  static Future<bool> _addToShoppingList(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final revert = await _guard(() => controller.buyAgainItem(item));
    if (!context.mounted) {
      return false;
    }
    if (revert == null) {
      _showFailure(context);
      return false;
    }
    ScaffoldMessenger.of(context).showAppSnackBar(
      l10n.inventoryItemBuyAgainSucceeded,
      onUndo: () => controller.undoBuyAgainItem(revert),
    );
    return true;
  }

  static Future<bool> _edit(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
    ScaffoldMessengerState pageMessenger,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (!item.isFullyAvailable) {
      _showFailure(context, l10n.inventoryItemEditRequiresFullItem);
      return false;
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
      return false;
    }

    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final saved = await _guard(() => controller.updateItem(edited)) ?? false;
    if (!context.mounted) {
      return false;
    }
    if (!saved) {
      _showFailure(context);
      return false;
    }
    pageMessenger.showAppSnackBar(
      l10n.inventoryItemUpdatedMessage,
      onUndo: () => controller.updateItem(item),
    );
    return true;
  }

  static Future<bool> _replace(
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
      return false;
    }
    final request = await showInventoryItemCandidateSwapFlow(
      context: context,
      ref: ref,
      item: item,
    );
    if (request == null || !context.mounted) {
      return false;
    }

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
    if (!saved && context.mounted) {
      _showFailure(context);
    }
    return saved;
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
