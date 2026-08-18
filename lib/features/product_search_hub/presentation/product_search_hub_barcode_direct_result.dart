import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_receipt_manual_product_models.dart'
    as inventory_models;
import 'package:yamt/features/product_search/domain/'
    'manual_product_eat_now_nutrition.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart'
    as manual_product_models;
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';

/// Whether barcode editor should explain missing nutrition for diary eat flow.
bool productSearchHubBarcodeNeedsEatNutritionMessage({
  required ProductSearchHubRouteArgs args,
  required GlobalFoodNutrition? nutrition,
}) {
  return args.mode == ProductSearchHubMode.diary &&
      !hasRequiredEatNowNutrition(nutrition);
}

/// Builds old barcode direct-eat result for selected OFF products.
inventory_models.InventoryReceiptManualProductResult?
productSearchHubDirectBarcodeProductResult({
  required ProviderContainer container,
  required InventoryItem draftItem,
  required ProductSearchHubRouteArgs args,
  required OffProductSearchResult product,
  required manual_product_models.InventoryReceiptManualProductAction action,
}) {
  if (!_canUseDirectEatResult(args: args, action: action)) {
    return null;
  }
  return productSearchHubDirectProductResult(
    container: container,
    draftItem: draftItem,
    product: product,
    action: action,
  );
}

/// Builds a direct diary eat result for selected OFF products.
inventory_models.InventoryReceiptManualProductResult?
productSearchHubDirectDiaryProductResult({
  required ProviderContainer container,
  required InventoryItem draftItem,
  required ProductSearchHubRouteArgs args,
  required OffProductSearchResult product,
}) {
  return productSearchHubDirectBarcodeProductResult(
    container: container,
    draftItem: draftItem,
    args: args,
    product: product,
    action: manual_product_models.InventoryReceiptManualProductAction.eatNow,
  );
}

/// Builds a direct result for selected OFF products.
inventory_models.InventoryReceiptManualProductResult?
productSearchHubDirectProductResult({
  required ProviderContainer container,
  required InventoryItem draftItem,
  required OffProductSearchResult product,
  required manual_product_models.InventoryReceiptManualProductAction action,
}) {
  final config = manual_product_models.InventoryReceiptManualProductConfig(
    item: draftItem,
    selectedProduct: product,
  );
  final controller = container.read(
    inventoryReceiptManualProductControllerProvider(config).notifier,
  );
  final payload = controller.buildDirectSearchResultPayload(
    product: product,
    action: action,
  );
  if (payload == null) {
    return null;
  }
  return inventory_models.InventoryReceiptManualProductResult(
    item: payload.item,
    action: action,
    selectedProduct: payload.selectedProduct,
    selectedGlobalFoodItemId: payload.selectedGlobalFoodItemId,
    requiresGlobalPersistence: payload.requiresGlobalPersistence,
    globalPackageWeight: payload.globalPackageWeight,
  );
}

/// Builds old barcode direct-eat result for learned/global candidates.
inventory_models.InventoryReceiptManualProductResult?
productSearchHubDirectBarcodeInventoryItemResult({
  required ProductSearchHubRouteArgs args,
  required InventoryItem item,
  required manual_product_models.InventoryReceiptManualProductAction action,
  required String? selectedGlobalFoodItemId,
  required String? globalPackageWeight,
}) {
  if (!_canUseDirectEatResult(args: args, action: action) ||
      !hasRequiredEatNowNutrition(item.nutrition)) {
    return null;
  }
  return productSearchHubDirectInventoryItemResult(
    item: item,
    action: action,
    selectedGlobalFoodItemId: selectedGlobalFoodItemId,
    globalPackageWeight: globalPackageWeight,
  );
}

/// Builds a direct diary eat result for inventory-backed items.
inventory_models.InventoryReceiptManualProductResult?
productSearchHubDirectDiaryInventoryItemResult({
  required ProductSearchHubRouteArgs args,
  required InventoryItem item,
  required String? selectedGlobalFoodItemId,
  required String? globalPackageWeight,
}) {
  return productSearchHubDirectBarcodeInventoryItemResult(
    args: args,
    item: item,
    action: manual_product_models.InventoryReceiptManualProductAction.eatNow,
    selectedGlobalFoodItemId: selectedGlobalFoodItemId,
    globalPackageWeight: globalPackageWeight,
  );
}

/// Builds a direct result for inventory-backed items.
inventory_models.InventoryReceiptManualProductResult?
productSearchHubDirectInventoryItemResult({
  required InventoryItem item,
  required manual_product_models.InventoryReceiptManualProductAction action,
  required String? selectedGlobalFoodItemId,
  required String? globalPackageWeight,
}) {
  return inventory_models.InventoryReceiptManualProductResult(
    item: item,
    action: action,
    selectedGlobalFoodItemId: selectedGlobalFoodItemId,
    requiresGlobalPersistence: false,
    globalPackageWeight: globalPackageWeight,
    skipMissingBarcodePrompt:
        action ==
        manual_product_models.InventoryReceiptManualProductAction.eatNow,
  );
}

bool _canUseDirectEatResult({
  required ProductSearchHubRouteArgs args,
  required manual_product_models.InventoryReceiptManualProductAction action,
}) {
  return args.mode == ProductSearchHubMode.diary &&
      action ==
          manual_product_models.InventoryReceiptManualProductAction.eatNow;
}
