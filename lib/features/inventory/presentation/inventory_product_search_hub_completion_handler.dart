import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_save_flow.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_handler.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_result.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_saved_selection.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Inventory completion handler for product search hub.
@Dependencies([
  InventoryItemsController,
])
class InventoryProductSearchHubCompletionHandler
    implements ProductSearchHubCompletionHandler {
  /// Creates an inventory completion handler.
  const InventoryProductSearchHubCompletionHandler({
    required ProviderContainer container,
  }) : _container = container;

  final ProviderContainer _container;

  @override
  Future<ProductSearchHubCompletionResult> completeResult({
    required BuildContext context,
    required ProductSearchHubRouteArgs args,
    required String sourceKey,
    required InventoryReceiptManualProductResult result,
    bool continueDiaryBatch = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await saveManualProductResultToInventory(
      context: context,
      container: ProviderScope.containerOf(context, listen: false),
      l10n: l10n,
      result: result,
    );
    if (!context.mounted) {
      return const ProductSearchHubCompletionResult.none();
    }
    if (outcome.status != InventoryManualProductSaveStatus.saved ||
        outcome.item == null) {
      if (outcome.status == InventoryManualProductSaveStatus.failed) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.inventoryManualAddSaveFailed)),
          );
      }
      return const ProductSearchHubCompletionResult.none();
    }
    return ProductSearchHubCompletionResult.showOverlay(
      ProductSearchHubSavedSelection(
        item: outcome.item!,
        sourceKey: sourceKey,
        calorieEntryId: outcome.calorieEntryId,
      ),
    );
  }

  @override
  Future<bool> removeSavedSelection(
    ProductSearchHubSavedSelection selection,
  ) async {
    return _container
        .read(inventoryItemsControllerProvider.notifier)
        .deleteItem(selection.item.id);
  }
}
