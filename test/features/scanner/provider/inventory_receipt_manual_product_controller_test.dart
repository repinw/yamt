import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/provider/'
    'inventory_receipt_manual_product_controller.dart';

class _ThrowingOffProductSearchRepository
    implements OffProductSearchRepository {
  @override
  Future<List<OffProductSearchResult>> search({
    required String query,
    String? store,
    String? brand,
    String? weight,
    int limit = 15,
  }) async {
    throw StateError('search failed');
  }

  @override
  Future<List<OffProductSearchResult>> lookupCandidatesByBarcode({
    required String barcode,
  }) async {
    return const <OffProductSearchResult>[];
  }
}

InventoryItem _item({
  String? weight,
  InventoryAmountUnit? amountUnit,
}) {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Unbekannt',
    entryDate: DateTime.parse('2026-04-02T10:00:00Z'),
    storeName: 'Netto',
    quantity: 1,
    weight: weight,
    amountUnit: amountUnit,
  );
}

InventoryReceiptManualProductConfig _config({
  String? itemWeight,
  InventoryAmountUnit? itemAmountUnit,
  OffProductSearchResult? selectedProduct,
}) {
  return InventoryReceiptManualProductConfig(
    item: _item(weight: itemWeight, amountUnit: itemAmountUnit),
    selectedProduct: selectedProduct,
  );
}

void main() {
  test('search failure clears loading state and keeps error null', () async {
    final config = _config();
    final container = ProviderContainer(
      overrides: [
        offProductSearchRepositoryProvider.overrideWithValue(
          _ThrowingOffProductSearchRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final provider = inventoryReceiptManualProductControllerProvider(config);
    final subscription = container.listen(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    container.read(provider.notifier).updateSearchQuery('Zero');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await Future<void>.delayed(Duration.zero);

    final state = container.read(provider);
    expect(state.isSearching, isFalse);
    expect(state.error, isNull);
    expect(state.searchResults, isEmpty);
  });

  test('build converts kilogram weight to grams', () {
    final config = _config(itemWeight: '1,5 kg');
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(
      inventoryReceiptManualProductControllerProvider(config),
    );

    expect(state.weightAmount, '1500');
    expect(state.selectedWeightUnit, InventoryAmountUnit.gram);
  });

  test('build parses compact milliliter values', () {
    final config = _config(itemWeight: '500ml');
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(
      inventoryReceiptManualProductControllerProvider(config),
    );

    expect(state.weightAmount, '500');
    expect(state.selectedWeightUnit, InventoryAmountUnit.milliliter);
  });

  test('selected product parsing supports piece units with umlauts', () {
    final config = _config();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final provider = inventoryReceiptManualProductControllerProvider(config);
    final subscription = container.listen(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    container.read(provider.notifier).applySearchResult(
      const OffProductSearchResult(
        code: '4311596490202',
        name: 'Brötchen',
        score: 100,
        packageWeight: '2 Stück',
      ),
    );

    final state = container.read(provider);
    expect(state.weightAmount, '2');
    expect(state.selectedWeightUnit, InventoryAmountUnit.piece);
  });

  test('invalid weight keeps fallback unit and clears amount', () {
    final config = _config(
      itemWeight: 'unbekannt',
      itemAmountUnit: InventoryAmountUnit.piece,
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(
      inventoryReceiptManualProductControllerProvider(config),
    );

    expect(state.weightAmount, isEmpty);
    expect(state.selectedWeightUnit, InventoryAmountUnit.piece);
  });
}
