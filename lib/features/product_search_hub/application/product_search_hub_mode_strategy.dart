import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
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
    'product_search_hub_completion_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_navigation.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_saved_selection.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Strategy defining mode-specific behavior for the Product Search Hub.
abstract interface class ProductSearchHubModeStrategy {
  /// The hub mode this strategy represents.
  ProductSearchHubMode get mode;

  /// Localized title for the hub app bar.
  String title(AppLocalizations l10n);

  /// Whether diary actions (meal, recipe, etc.) are visible.
  bool get showsDiarySourceActions;

  /// Whether the hub is running in diary mode.
  bool get isDiary;

  /// Default action to preselect when opening the product editor.
  InventoryReceiptManualProductAction get initialManualProductAction;

  /// Handles completion and persistence of an edited product result.
  Future<ProductSearchHubCompletionResult> completeResult({
    required BuildContext context,
    required ProviderContainer container,
    required AppLocalizations l10n,
    required ProductSearchHubRouteArgs args,
    required String sourceKey,
    required InventoryReceiptManualProductResult result,
    bool continueDiaryBatch = false,
  });
}

/// Resolves the mode strategy for a given [ProductSearchHubMode].
@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
ProductSearchHubModeStrategy productSearchHubModeStrategy(
  ProductSearchHubMode mode,
) {
  return switch (mode) {
    ProductSearchHubMode.inventory => const InventoryHubModeStrategy(),
    ProductSearchHubMode.diary => const DiaryHubModeStrategy(),
    ProductSearchHubMode.selection => const SelectionHubModeStrategy(),
  };
}

/// Strategy for inventory mode (adding items to pantry/fridge).
@Dependencies([InventoryItemsController])
class InventoryHubModeStrategy implements ProductSearchHubModeStrategy {
  /// Creates an inventory hub mode strategy.
  const InventoryHubModeStrategy();

  @override
  ProductSearchHubMode get mode => ProductSearchHubMode.inventory;

  @override
  String title(AppLocalizations l10n) => l10n.productSearchHubInventoryTitle;

  @override
  bool get showsDiarySourceActions => false;

  @override
  bool get isDiary => false;

  @override
  InventoryReceiptManualProductAction get initialManualProductAction =>
      InventoryReceiptManualProductAction.addToInventory;

  @override
  Future<ProductSearchHubCompletionResult> completeResult({
    required BuildContext context,
    required ProviderContainer container,
    required AppLocalizations l10n,
    required ProductSearchHubRouteArgs args,
    required String sourceKey,
    required InventoryReceiptManualProductResult result,
    bool continueDiaryBatch = false,
  }) async {
    final outcome = await saveManualProductResultToInventory(
      context: context,
      container: container,
      l10n: l10n,
      result: result,
    );
    if (!context.mounted) {
      return const ProductSearchHubCompletionResult.none();
    }
    final selection = _extractSavedSelection(
      context: context,
      l10n: l10n,
      outcome: outcome,
      sourceKey: sourceKey,
    );
    if (selection == null) {
      return const ProductSearchHubCompletionResult.none();
    }
    return ProductSearchHubCompletionResult.showOverlay(selection);
  }
}

/// Strategy for diary mode (eating products immediately).
@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
class DiaryHubModeStrategy implements ProductSearchHubModeStrategy {
  /// Creates a diary hub mode strategy.
  const DiaryHubModeStrategy();

  @override
  ProductSearchHubMode get mode => ProductSearchHubMode.diary;

  @override
  String title(AppLocalizations l10n) => l10n.productSearchHubDiaryTitle;

  @override
  bool get showsDiarySourceActions => true;

  @override
  bool get isDiary => true;

  @override
  InventoryReceiptManualProductAction get initialManualProductAction =>
      InventoryReceiptManualProductAction.eatNow;

  @override
  Future<ProductSearchHubCompletionResult> completeResult({
    required BuildContext context,
    required ProviderContainer container,
    required AppLocalizations l10n,
    required ProductSearchHubRouteArgs args,
    required String sourceKey,
    required InventoryReceiptManualProductResult result,
    bool continueDiaryBatch = false,
  }) async {
    final outcome = await saveManualProductResultForEatFlow(
      context: context,
      container: container,
      l10n: l10n,
      result: result,
      preselectedMealType: args.preselectedMealType,
      preselectedLoggedAt: args.preselectedLoggedAt,
      continueBatchOnConfirm: continueDiaryBatch,
    );
    if (!context.mounted) {
      return const ProductSearchHubCompletionResult.none();
    }
    final selection = _extractSavedSelection(
      context: context,
      l10n: l10n,
      outcome: outcome,
      sourceKey: sourceKey,
    );
    if (selection == null) {
      return const ProductSearchHubCompletionResult.none();
    }
    if (!outcome.addMoreRequested) {
      return ProductSearchHubCompletionResult.closeHub(selection: selection);
    }
    return ProductSearchHubCompletionResult.showOverlay(selection);
  }
}

ProductSearchHubSavedSelection? _extractSavedSelection({
  required BuildContext context,
  required AppLocalizations l10n,
  required InventoryManualProductSaveOutcome outcome,
  required String sourceKey,
}) {
  final savedItem = outcome.item;
  if (outcome.status != InventoryManualProductSaveStatus.saved ||
      savedItem == null) {
    if (outcome.status == InventoryManualProductSaveStatus.failed) {
      showProductSearchHubSnackBar(
        context,
        l10n.inventoryManualAddSaveFailed,
      );
    }
    return null;
  }
  return ProductSearchHubSavedSelection(
    item: savedItem,
    sourceKey: sourceKey,
    calorieEntryId: outcome.calorieEntryId,
  );
}

/// Strategy for selection mode (returning raw edited result to caller).
class SelectionHubModeStrategy implements ProductSearchHubModeStrategy {
  /// Creates a selection hub mode strategy.
  const SelectionHubModeStrategy();

  @override
  ProductSearchHubMode get mode => ProductSearchHubMode.selection;

  @override
  String title(AppLocalizations l10n) => l10n.productSearchHubTitle;

  @override
  bool get showsDiarySourceActions => false;

  @override
  bool get isDiary => false;

  @override
  InventoryReceiptManualProductAction get initialManualProductAction =>
      InventoryReceiptManualProductAction.addToInventory;

  @override
  Future<ProductSearchHubCompletionResult> completeResult({
    required BuildContext context,
    required ProviderContainer container,
    required AppLocalizations l10n,
    required ProductSearchHubRouteArgs args,
    required String sourceKey,
    required InventoryReceiptManualProductResult result,
    bool continueDiaryBatch = false,
  }) async {
    return const ProductSearchHubCompletionResult.none();
  }
}
