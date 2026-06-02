import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
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

/// Result of completing a hub product result.
class ProductSearchHubCompletionResult {
  const ProductSearchHubCompletionResult._({
    required this.shouldCloseHub,
    this.selection,
  });

  /// No user-visible completion action.
  const ProductSearchHubCompletionResult.none() : this._(shouldCloseHub: false);

  /// Close the hub after a direct save.
  const ProductSearchHubCompletionResult.closeHub({
    ProductSearchHubSavedSelection? selection,
  }) : this._(shouldCloseHub: true, selection: selection);

  /// Show saved item in the hub overlay.
  const ProductSearchHubCompletionResult.showOverlay(
    ProductSearchHubSavedSelection selection,
  ) : this._(shouldCloseHub: false, selection: selection);

  /// Whether hub should close after completion.
  final bool shouldCloseHub;

  /// Saved selection to show in overlay.
  final ProductSearchHubSavedSelection? selection;
}

/// Completes a product search hub editor result for the active route mode.
@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
Future<ProductSearchHubCompletionResult> completeProductSearchHubResult({
  required BuildContext context,
  required ProviderContainer container,
  required AppLocalizations l10n,
  required ProductSearchHubRouteArgs args,
  required String sourceKey,
  required InventoryReceiptManualProductResult result,
  bool continueDiaryBatch = false,
}) async {
  if (args.mode == ProductSearchHubMode.selection) {
    return const ProductSearchHubCompletionResult.none();
  }

  final outcome = await _completeForMode(
    context: context,
    container: container,
    l10n: l10n,
    args: args,
    result: result,
    continueDiaryBatch: continueDiaryBatch,
  );
  if (!context.mounted) {
    return const ProductSearchHubCompletionResult.none();
  }

  final savedItem = outcome.item;
  if (outcome.status != InventoryManualProductSaveStatus.saved ||
      savedItem == null) {
    if (outcome.status == InventoryManualProductSaveStatus.failed) {
      _showSnackBar(context, l10n.inventoryManualAddSaveFailed);
    }
    return const ProductSearchHubCompletionResult.none();
  }
  final selection = ProductSearchHubSavedSelection(
    item: savedItem,
    sourceKey: sourceKey,
    calorieEntryId: outcome.calorieEntryId,
  );
  if (args.mode == ProductSearchHubMode.diary && !outcome.addMoreRequested) {
    return ProductSearchHubCompletionResult.closeHub(selection: selection);
  }
  return ProductSearchHubCompletionResult.showOverlay(selection);
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
  required bool continueDiaryBatch,
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
      continueBatchOnConfirm: continueDiaryBatch,
    ),
    ProductSearchHubMode.selection => Future.value(
      const InventoryManualProductSaveOutcome.canceled(),
    ),
  };
}

/// Removes a saved hub selection from diary and inventory.
@Dependencies([InventoryItemsController])
Future<bool> removeProductSearchHubSelection({
  required ProviderContainer container,
  required ProductSearchHubSavedSelection selection,
}) async {
  final diaryEntryId = selection.calorieEntryId;
  if (diaryEntryId != null) {
    final deletedDiaryEntry = await container
        .read(calorieEntriesControllerProvider.notifier)
        .deleteEntry(diaryEntryId);
    if (!deletedDiaryEntry) {
      return false;
    }
  }

  return container
      .read(inventoryItemsControllerProvider.notifier)
      .deleteItem(selection.item.id);
}

void _showSnackBar(BuildContext context, String message) {
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
