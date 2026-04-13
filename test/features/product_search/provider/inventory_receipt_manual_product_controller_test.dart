import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/provider/'
    'inventory_receipt_manual_product_controller.dart';

InventoryItem _item() {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Unknown',
    entryDate: DateTime.parse('2026-04-02T10:00:00Z'),
    storeName: 'Kaufland',
    quantity: 1,
  );
}

void main() {
  test('buildSavePayload requires package weight when barcode is present', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const selectedProduct = OffProductSearchResult(
      code: '4311596490202',
      name: 'Booster Absolute Zero',
      brand: 'Booster',
      score: 100,
    );
    final config = InventoryReceiptManualProductConfig(
      item: _item(),
      selectedProduct: selectedProduct,
    );
    final provider = inventoryReceiptManualProductControllerProvider(config);
    final controller = container.read(provider.notifier);

    final payload = controller.buildSavePayload();

    expect(payload, isNull);
    expect(
      container.read(provider).error,
      InventoryReceiptManualProductError.requiredPackageWeight,
    );
  });

  test(
    'buildSavePayload allows barcode-only save when package weight exists',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const selectedProduct = OffProductSearchResult(
        code: '4311596490202',
        name: 'Booster Absolute Zero',
        brand: 'Booster',
        packageWeight: '330 ml',
        score: 100,
      );
      final config = InventoryReceiptManualProductConfig(
        item: _item(),
        selectedProduct: selectedProduct,
      );
      final provider = inventoryReceiptManualProductControllerProvider(config);
      final controller = container.read(provider.notifier);

      final payload = controller.buildSavePayload();

      expect(payload, isNotNull);
      expect(payload?.item.weight, '330 ml');
      expect(payload?.item.barcode, '4311596490202');
      expect(payload?.item.nutrition, isNull);
    },
  );
}
