import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart'
    as manual_product_models;
import 'package:yamt/features/product_search_hub/presentation/'
    'models/product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_barcode_direct_result.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_barcode_scanner.dart';

void main() {
  test('inventory barcode mode selects candidates directly for inventory', () {
    final options = productSearchHubBarcodeOptionsForArgs(
      const ProductSearchHubRouteArgs.inventory(),
    );

    expect(options.showActionButtons, isFalse);
    expect(options.eatOnly, isFalse);
  });

  test('diary barcode mode shows eat-only candidate actions', () {
    final options = productSearchHubBarcodeOptionsForArgs(
      const ProductSearchHubRouteArgs.diary(),
    );

    expect(options.showActionButtons, isTrue);
    expect(options.eatOnly, isTrue);
  });

  test('selection barcode mode behaves like inventory selection', () {
    final options = productSearchHubBarcodeOptionsForArgs(
      ProductSearchHubRouteArgs.selection(item: _draftItem()),
    );

    expect(options.showActionButtons, isFalse);
    expect(options.eatOnly, isFalse);
  });

  test('diary barcode mode explains missing eat nutrition', () {
    final needsMessage = productSearchHubBarcodeNeedsEatNutritionMessage(
      args: const ProductSearchHubRouteArgs.diary(),
      nutrition: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
        per100Kcal: 100,
      ),
    );

    expect(needsMessage, isTrue);
  });

  test('diary barcode mode skips message for complete nutrition', () {
    final needsMessage = productSearchHubBarcodeNeedsEatNutritionMessage(
      args: const ProductSearchHubRouteArgs.diary(),
      nutrition: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
        per100Kcal: 100,
        per100Carbs: 10,
        per100Protein: 5,
        per100Fat: 2,
      ),
    );

    expect(needsMessage, isFalse);
  });

  test('inventory barcode mode skips eat nutrition message', () {
    final needsMessage = productSearchHubBarcodeNeedsEatNutritionMessage(
      args: const ProductSearchHubRouteArgs.inventory(),
      nutrition: null,
    );

    expect(needsMessage, isFalse);
  });

  test('diary barcode direct result builds from complete OFF product', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final result = productSearchHubDirectBarcodeProductResult(
      container: container,
      draftItem: _draftItem(),
      args: const ProductSearchHubRouteArgs.diary(),
      product: const OffProductSearchResult(
        code: '4006381333931',
        name: 'Muesli',
        score: 1,
        brand: 'Brand',
        packageWeight: '500 g',
        nutrition: _completeNutrition,
      ),
      action: manual_product_models.InventoryReceiptManualProductAction.eatNow,
    );

    expect(result, isNotNull);
    expect(
      result!.action,
      manual_product_models.InventoryReceiptManualProductAction.eatNow,
    );
    expect(result.item.name, 'Muesli');
    expect(result.item.normalizedBarcode, '4006381333931');
    expect(result.selectedProduct?.code, '4006381333931');
  });

  test('barcode direct result is diary eat-only', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    for (final args in [
      const ProductSearchHubRouteArgs.inventory(),
      ProductSearchHubRouteArgs.selection(item: _draftItem()),
    ]) {
      final result = productSearchHubDirectBarcodeProductResult(
        container: container,
        draftItem: _draftItem(),
        args: args,
        product: const OffProductSearchResult(
          code: '4006381333931',
          name: 'Muesli',
          score: 1,
          nutrition: _completeNutrition,
        ),
        action: manual_product_models
            .InventoryReceiptManualProductAction
            .addToInventory,
      );

      expect(result, isNull);
    }
  });

  test('diary barcode direct result needs complete nutrition', () {
    final result = productSearchHubDirectBarcodeInventoryItemResult(
      args: const ProductSearchHubRouteArgs.diary(),
      item: _draftItem(
        nutrition: const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
          per100Kcal: 100,
        ),
      ),
      action: manual_product_models.InventoryReceiptManualProductAction.eatNow,
      selectedGlobalFoodItemId: 'global-food',
      globalPackageWeight: '500 g',
    );

    expect(result, isNull);
  });

  test('diary barcode direct result builds from learned item', () {
    final result = productSearchHubDirectBarcodeInventoryItemResult(
      args: const ProductSearchHubRouteArgs.diary(),
      item: _draftItem(nutrition: _completeNutrition),
      action: manual_product_models.InventoryReceiptManualProductAction.eatNow,
      selectedGlobalFoodItemId: 'global-food',
      globalPackageWeight: '500 g',
    );

    expect(result, isNotNull);
    expect(result!.selectedGlobalFoodItemId, 'global-food');
    expect(result.requiresGlobalPersistence, isFalse);
    expect(result.globalPackageWeight, '500 g');
  });
}

const _completeNutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
  per100Kcal: 100,
  per100Carbs: 10,
  per100Protein: 5,
  per100Fat: 2,
);

InventoryItem _draftItem({GlobalFoodNutrition? nutrition}) {
  return InventoryItem.create(
    id: 'draft-item',
    name: 'Draft',
    entryDate: DateTime(2024),
    storeName: 'Manual',
    quantity: 1,
    barcode: '4006381333931',
    weight: '500 g',
    nutrition: nutrition,
  );
}
