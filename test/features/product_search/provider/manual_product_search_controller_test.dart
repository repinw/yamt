import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/provider/'
    'manual_product_search_controller.dart';

class _RecordingOffProductSearchRepository
    implements OffProductSearchRepository {
  _RecordingOffProductSearchRepository(this.results);

  final List<OffProductSearchResult> results;

  @override
  Future<List<OffProductSearchResult>> search({
    required String query,
    String? store,
    String? brand,
    String? weight,
    int limit = 15,
  }) async {
    return results.take(limit).toList(growable: false);
  }

  @override
  Future<List<OffProductSearchResult>> lookupCandidatesByBarcode({
    required String barcode,
  }) async {
    return const <OffProductSearchResult>[];
  }
}

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

  test('buildSavePayload allows eat action without package weight', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const selectedProduct = OffProductSearchResult(
      code: '4311596490202',
      name: 'Booster Absolute Zero',
      brand: 'Booster',
      score: 100,
      nutrition: GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 2,
        per100Protein: 0,
        per100Carbs: 0,
        per100Fat: 0,
      ),
    );
    final config = InventoryReceiptManualProductConfig(
      item: _item(),
      selectedProduct: selectedProduct,
    );
    final provider = inventoryReceiptManualProductControllerProvider(config);
    final controller = container.read(provider.notifier);

    final payload = controller.buildSavePayload(
      action: InventoryReceiptManualProductAction.eatNow,
    );

    expect(payload, isNotNull);
    expect(payload?.item.weight, isNull);
    expect(payload?.item.barcode, '4311596490202');
  });

  test(
    'buildDirectSearchResultPayload builds eat payload for search result',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final config = InventoryReceiptManualProductConfig(item: _item());
      final provider = inventoryReceiptManualProductControllerProvider(config);
      final controller = container.read(provider.notifier);

      final payload = controller.buildDirectSearchResultPayload(
        product: const OffProductSearchResult(
          code: '4006381333931',
          name: 'Milk',
          brand: 'Brand',
          packageWeight: '1 l',
          score: 99,
          nutrition: GlobalFoodNutrition(
            qualityStatus: GlobalFoodNutritionQualityStatus.verified,
            per100Kcal: 100,
            per100Protein: 10,
            per100Carbs: 20,
            per100Fat: 3,
          ),
        ),
        action: InventoryReceiptManualProductAction.eatNow,
      );

      expect(payload, isNotNull);
      expect(payload?.item.name, 'Milk');
      expect(payload?.item.weight, '1000 ml');
      expect(payload?.globalPackageWeight, '1 l');
      expect(payload?.selectedProduct?.code, '4006381333931');
    },
  );

  test(
    'buildDirectSearchResultPayload allows eat payload without package size',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final config = InventoryReceiptManualProductConfig(item: _item());
      final provider = inventoryReceiptManualProductControllerProvider(config);
      final controller = container.read(provider.notifier);

      final payload = controller.buildDirectSearchResultPayload(
        product: const OffProductSearchResult(
          code: '4006381333931',
          name: 'Milk',
          brand: 'Brand',
          score: 99,
          nutrition: GlobalFoodNutrition(
            qualityStatus: GlobalFoodNutritionQualityStatus.verified,
            per100Kcal: 100,
            per100Protein: 10,
            per100Carbs: 20,
            per100Fat: 3,
          ),
        ),
        action: InventoryReceiptManualProductAction.eatNow,
      );

      expect(payload, isNotNull);
      expect(payload?.item.weight, isNull);
      expect(payload?.globalPackageWeight, isNull);
      expect(payload?.selectedProduct?.code, '4006381333931');
    },
  );

  test(
    'buildDirectSearchResultPayload normalizes fractional piece amount'
    ' for inventory storage',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final config = InventoryReceiptManualProductConfig(item: _item());
      final provider = inventoryReceiptManualProductControllerProvider(config);
      final controller = container.read(provider.notifier);

      final payload = controller.buildDirectSearchResultPayload(
        product: const OffProductSearchResult(
          code: '4006381333931',
          name: 'Apple',
          brand: 'Brand',
          packageWeight: '1.5 Stk',
          score: 99,
          nutrition: GlobalFoodNutrition(
            qualityStatus: GlobalFoodNutritionQualityStatus.verified,
            per100Kcal: 100,
            per100Protein: 1,
            per100Carbs: 20,
            per100Fat: 0,
          ),
        ),
        action: InventoryReceiptManualProductAction.eatNow,
      );

      expect(payload, isNotNull);
      expect(payload?.item.weight, '1.5 pc');
      expect(payload?.item.currentAmount, 1500);
      expect(payload?.item.amountScale, inventoryPieceAmountScale);
      expect(payload?.globalPackageWeight, '1.5 Stk');
    },
  );

  test(
    'buildDirectSearchResultPayload returns null when nutrition is missing',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final config = InventoryReceiptManualProductConfig(item: _item());
      final provider = inventoryReceiptManualProductControllerProvider(config);
      final controller = container.read(provider.notifier);

      final payload = controller.buildDirectSearchResultPayload(
        product: const OffProductSearchResult(
          code: '4006381333931',
          name: 'Milk',
          brand: 'Brand',
          packageWeight: '1 l',
          score: 99,
        ),
        action: InventoryReceiptManualProductAction.eatNow,
      );

      expect(payload, isNull);
    },
  );

  test(
    'buildSavePayload stores normalized manual piece amount for inventory'
    ' and global payload',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const selectedProduct = OffProductSearchResult(
        code: '4311596490202',
        name: 'Apple',
        brand: 'Brand',
        score: 100,
      );
      final config = InventoryReceiptManualProductConfig(
        item: _item(),
        selectedProduct: selectedProduct,
      );
      final provider = inventoryReceiptManualProductControllerProvider(config);
      final payload =
          (container.read(provider.notifier)
                ..updateWeightAmount('1,5')
                ..updateWeightUnit(InventoryAmountUnit.piece))
              .buildSavePayload();

      expect(payload, isNotNull);
      expect(payload?.item.weight, '1.5 pc');
      expect(payload?.item.currentAmount, 1500);
      expect(payload?.item.amountScale, inventoryPieceAmountScale);
      expect(payload?.globalPackageWeight, '1.5 pc');
    },
  );

  test(
    'updateSearchQuery keeps only OFF results with Germany-required'
    ' nutrition values',
    () async {
      final repository = _RecordingOffProductSearchRepository(
        const <OffProductSearchResult>[
          OffProductSearchResult(
            code: '4311596490201',
            name: 'No Nutrition',
            brand: 'Booster',
            packageWeight: '330 ml',
            score: 100,
          ),
          OffProductSearchResult(
            code: '4311596490202',
            name: 'Incomplete Zero',
            brand: 'Booster',
            packageWeight: '330 ml',
            score: 99,
            nutrition: GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: 2,
              per100Carbs: 0.01,
              per100Fat: 0,
              per100Protein: 0.02,
            ),
          ),
          OffProductSearchResult(
            code: '4311596490203',
            name: 'Complete Zero',
            brand: 'Booster',
            packageWeight: '330 ml',
            score: 98,
            nutrition: GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: 2,
              per100Fat: 0,
              per100SaturatedFat: 0,
              per100Carbs: 0.01,
              per100Sugar: 0.01,
              per100Protein: 0.02,
              per100Salt: 0.01,
            ),
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          offProductSearchRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final config = InventoryReceiptManualProductConfig(item: _item());
      final provider = inventoryReceiptManualProductControllerProvider(config);
      final subscription = container.listen(provider, (previous, next) {});
      addTearDown(subscription.close);

      container.read(provider.notifier).updateSearchQuery('Zero');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await Future<void>.delayed(Duration.zero);

      final state = container.read(provider);
      expect(
        state.searchResults.map((result) => result.name),
        <String>['Complete Zero'],
      );
    },
  );
}
