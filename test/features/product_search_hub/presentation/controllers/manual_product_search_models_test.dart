import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';

void main() {
  final item = InventoryItem.create(
    id: 'oat-milk',
    name: 'Oat milk',
    entryDate: DateTime.parse('2026-10-01T10:00:00Z'),
    storeName: 'Rewe',
    quantity: 1,
  );
  const product = OffProductSearchResult(
    code: '7394376616037',
    name: 'Oat milk',
    score: 100,
  );
  final InventoryReceiptManualProductSavePayload payload = (
    item: item,
    selectedProduct: product,
    selectedGlobalFoodItemId: 'global-1',
    requiresGlobalPersistence: false,
    globalPackageWeight: '1000 ml',
  );

  test('a save payload becomes the result with every field', () {
    final result = payload.toResult(
      InventoryReceiptManualProductAction.eatNow,
      skipMissingBarcodePrompt: true,
    );

    expect(result.item, same(item));
    expect(result.action, InventoryReceiptManualProductAction.eatNow);
    expect(result.selectedProduct, product);
    expect(result.selectedGlobalFoodItemId, 'global-1');
    expect(result.requiresGlobalPersistence, isFalse);
    expect(result.globalPackageWeight, '1000 ml');
    expect(result.skipMissingBarcodePrompt, isTrue);
  });

  test('a result asks for a missing barcode unless told otherwise', () {
    expect(
      payload
          .toResult(InventoryReceiptManualProductAction.addToInventory)
          .skipMissingBarcodePrompt,
      isFalse,
    );
  });
}
