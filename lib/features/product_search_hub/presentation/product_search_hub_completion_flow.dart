import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_eat_completion_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_save_flow.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_saved_selection.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Completes a product search hub editor result for the active route mode.
@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
Future<ProductSearchHubSavedSelection?> completeProductSearchHubResult({
  required BuildContext context,
  required ProviderContainer container,
  required AppLocalizations l10n,
  required ProductSearchHubRouteArgs args,
  required String sourceKey,
  required InventoryReceiptManualProductResult result,
}) async {
  if (args.mode == ProductSearchHubMode.selection) {
    return null;
  }

  final outcome = await _completeForMode(
    context: context,
    container: container,
    l10n: l10n,
    args: args,
    result: result,
  );
  if (!context.mounted) {
    return null;
  }

  final savedItem = outcome.item;
  if (outcome.status != InventoryManualProductSaveStatus.saved ||
      savedItem == null) {
    if (outcome.status == InventoryManualProductSaveStatus.failed) {
      _showSnackBar(context, l10n.inventoryManualAddSaveFailed);
    }
    return null;
  }
  return ProductSearchHubSavedSelection(item: savedItem, sourceKey: sourceKey);
}

@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
Future<InventoryManualProductSaveOutcome> _completeForMode({
  required BuildContext context,
  required ProviderContainer container,
  required AppLocalizations l10n,
  required ProductSearchHubRouteArgs args,
  required InventoryReceiptManualProductResult result,
}) {
  return switch (args.mode) {
    ProductSearchHubMode.inventory => saveManualProductResultToInventory(
      context: context,
      container: container,
      l10n: l10n,
      result: result,
    ),
    ProductSearchHubMode.diary => saveManualProductResultForEatFlow(
      context: context,
      container: container,
      l10n: l10n,
      result: result,
      preselectedMealType: args.preselectedMealType,
      preselectedLoggedAt: args.preselectedLoggedAt,
    ),
    ProductSearchHubMode.selection => Future.value(
      const InventoryManualProductSaveOutcome.canceled(),
    ),
  };
}

/// Removes a saved hub selection from inventory.
@Dependencies([InventoryItemsController])
Future<bool> removeProductSearchHubSelection({
  required ProviderContainer container,
  required InventoryItem item,
}) {
  return container
      .read(inventoryItemsControllerProvider.notifier)
      .deleteItem(item.id);
}

void _showSnackBar(BuildContext context, String message) {
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
