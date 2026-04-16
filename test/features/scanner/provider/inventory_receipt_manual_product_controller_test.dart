import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/'
    'calorie_nutrition_ocr_repository.dart';
import 'package:yamt/features/calories/data/'
    'calorie_nutrition_ocr_repository_contract.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/provider/'
    'inventory_receipt_manual_product_controller.dart';

class _FakeNutritionOcrRepository
    implements CalorieNutritionOcrRepositoryContract {
  _FakeNutritionOcrRepository({required this.onScanNutritionLabel});

  final Future<CalorieNutritionOcrResult> Function(String barcode)
  onScanNutritionLabel;

  @override
  Future<CalorieNutritionOcrResult> scanNutritionLabel({
    required String barcode,
  }) {
    return onScanNutritionLabel(barcode);
  }
}

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

class _RecordingOffProductSearchRepository
    implements OffProductSearchRepository {
  int searchCallCount = 0;

  @override
  Future<List<OffProductSearchResult>> search({
    required String query,
    String? store,
    String? brand,
    String? weight,
    int limit = 15,
  }) async {
    searchCallCount++;
    return const <OffProductSearchResult>[];
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
  String storeName = 'Netto',
  InventoryItemOrigin origin = InventoryItemOrigin.standard,
  String? ocrName,
}) {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Unbekannt',
    entryDate: DateTime.parse('2026-04-02T10:00:00Z'),
    storeName: storeName,
    origin: origin,
    quantity: 1,
    weight: weight,
    amountUnit: amountUnit,
    ocrName: ocrName,
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

    container
        .read(provider.notifier)
        .applySearchResult(
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

  test('manual add origin omits store from initial search query', () {
    final query = buildManualProductInitialSearchQuery(
      InventoryReceiptManualProductConfig(
        item: _item(
          storeName: 'Ajout manuel',
          origin: InventoryItemOrigin.manualAdd,
        ).copyWith(name: 'Olivenoel'),
      ),
    );

    expect(query, 'Olivenoel');
  });

  test('ocr name is preferred for the initial search query', () {
    final query = buildManualProductInitialSearchQuery(
      InventoryReceiptManualProductConfig(
        item: _item(ocrName: 'H-MILCH 3,5%').copyWith(name: 'Milch'),
      ),
    );

    expect(query, 'H-MILCH 3,5% Netto');
  });

  test('applyRecentItem cancels a pending debounced search', () async {
    final repository = _RecordingOffProductSearchRepository();
    final config = _config();
    final container = ProviderContainer(
      overrides: [
        offProductSearchRepositoryProvider.overrideWithValue(repository),
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
    container
        .read(provider.notifier)
        .applyRecentItem(
          InventoryItem.create(
            id: 'recent-1',
            name: 'Olivenoel',
            entryDate: DateTime.parse('2026-04-03T10:00:00Z'),
            storeName: 'Ajout manuel',
            origin: InventoryItemOrigin.manualAdd,
            quantity: 1,
            barcode: '4061462542046',
          ),
        );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await Future<void>.delayed(Duration.zero);

    expect(repository.searchCallCount, 0);
  });

  test('applySearchResult cancels a pending debounced search', () async {
    final repository = _RecordingOffProductSearchRepository();
    final config = _config();
    final container = ProviderContainer(
      overrides: [
        offProductSearchRepositoryProvider.overrideWithValue(repository),
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
    container
        .read(provider.notifier)
        .applySearchResult(
          const OffProductSearchResult(
            code: '4311596490202',
            name: 'Booster Absolute Zero',
            score: 100,
          ),
        );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await Future<void>.delayed(Duration.zero);

    expect(repository.searchCallCount, 0);
  });

  test(
    'buildSavePayload keeps matched product metadata after nutrition edit',
    () {
      final config = _config(
        itemWeight: '500 g',
        selectedProduct: const OffProductSearchResult(
          code: '4061462542046',
          name: 'Olivenoel',
          score: 100,
          brand: 'Gut Bio',
          imageUrl: 'https://example.com/olive-oil.png',
          servingSize: '15 ml',
          servingQuantity: 15,
          servingQuantityUnit: 'ml',
          nutrition: GlobalFoodNutrition(
            qualityStatus: GlobalFoodNutritionQualityStatus.verified,
            per100Kcal: 824,
            per100Protein: 0,
            per100Carbs: 0,
            per100Fat: 91.6,
            per100SaturatedFat: 14,
            per100Sugar: 0,
            per100Salt: 0,
          ),
        ),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final provider = inventoryReceiptManualProductControllerProvider(config);
      final subscription = container.listen(
        provider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final notifier = container.read(provider.notifier);
      notifier.updateKcalText('700');

      final payload = notifier.buildSavePayload();

      expect(payload, isNotNull);
      expect(payload!.selectedProduct, isNull);
      expect(payload.item.name, 'Olivenoel');
      expect(payload.item.brand, 'Gut Bio');
      expect(payload.item.imageUrl, 'https://example.com/olive-oil.png');
      expect(payload.item.servingSize, '15 ml');
      expect(payload.item.servingQuantity, 15);
      expect(payload.item.servingQuantityUnit, 'ml');
      expect(payload.item.nutrition?.per100Kcal, 700);
    },
  );

  test('buildSavePayload uses manual name and brand overrides', () {
    final config = _config(
      itemWeight: '500 g',
      selectedProduct: const OffProductSearchResult(
        code: '4061462542046',
        name: 'Olivenoel',
        score: 100,
        brand: 'Gut Bio',
        imageUrl: 'https://example.com/olive-oil.png',
        nutrition: GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.verified,
          per100Kcal: 824,
          per100Protein: 0,
          per100Carbs: 0,
          per100Fat: 91.6,
          per100SaturatedFat: 14,
          per100Sugar: 0,
          per100Salt: 0,
        ),
      ),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final provider = inventoryReceiptManualProductControllerProvider(config);
    final subscription = container.listen(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final notifier = container.read(provider.notifier);
    notifier.updateNameText('Mein Oel');
    notifier.updateBrandText('Hausmarke');

    final payload = notifier.buildSavePayload();

    expect(payload, isNotNull);
    expect(payload!.selectedProduct, isNull);
    expect(payload.selectedGlobalFoodItemId, isNull);
    expect(payload.item.name, 'Mein Oel');
    expect(payload.item.brand, 'Hausmarke');
    expect(payload.item.imageUrl, 'https://example.com/olive-oil.png');
  });

  test('buildSavePayload returns null without barcode or nutrition', () {
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

    expect(container.read(provider.notifier).buildSavePayload(), isNull);
  });

  test('buildSavePayload keeps explicit zero nutrition values', () {
    final config = _config(itemWeight: '500 g');
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final provider = inventoryReceiptManualProductControllerProvider(config);
    final subscription = container.listen(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final notifier = container.read(provider.notifier);
    notifier.updateKcalText('0');
    notifier.updateSaturatedFatText('0');
    notifier.updateProteinText('0');
    notifier.updateCarbsText('0');
    notifier.updateSugarText('0');
    notifier.updateFatText('0');
    notifier.updateSaltText('0');

    final payload = notifier.buildSavePayload();

    expect(payload, isNotNull);
    expect(payload!.item.nutrition?.per100Kcal, 0);
    expect(payload.item.nutrition?.per100SaturatedFat, 0);
    expect(payload.item.nutrition?.per100Protein, 0);
    expect(payload.item.nutrition?.per100Carbs, 0);
    expect(payload.item.nutrition?.per100Sugar, 0);
    expect(payload.item.nutrition?.per100Fat, 0);
    expect(payload.item.nutrition?.per100Salt, 0);
  });

  test('optional nutrition picker offers only missing nutrients', () {
    final config = _config(
      selectedProduct: const OffProductSearchResult(
        code: '4061462542046',
        name: 'Olivenoel',
        score: 100,
        nutrition: GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.verified,
          per100Kcal: 824,
          per100Protein: 0,
          per100Carbs: 0,
          per100Fat: 91.6,
          per100SaturatedFat: 14,
          per100Sugar: 0,
          per100Salt: 0,
          per100Fiber: 2,
        ),
      ),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final provider = inventoryReceiptManualProductControllerProvider(config);
    final subscription = container.listen(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final notifier = container.read(provider.notifier);
    notifier.startAddingOptionalNutrition();
    final state = container.read(provider);

    expect(state.availableOptionalNutritionTypes, const [
      InventoryReceiptOptionalNutritionType.polyunsaturatedFat,
    ]);
    expect(
      state.resolvedOptionalNutritionType,
      InventoryReceiptOptionalNutritionType.polyunsaturatedFat,
    );
  });

  test(
    'scanNutritionLabel applies partial OCR and keeps missing blank',
    () async {
      final config = _config(
        selectedProduct: const OffProductSearchResult(
          code: '4061462542046',
          name: 'Olivenoel',
          score: 100,
          brand: 'Gut Bio',
          imageUrl: 'https://example.com/olive-oil.png',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          calorieNutritionOcrRepositoryProvider.overrideWithValue(
            _FakeNutritionOcrRepository(
              onScanNutritionLabel: (barcode) async {
                return CalorieNutritionOcrResult.succeeded(
                  draft: CalorieNutritionOcrDraft(
                    barcode: barcode,
                    quantityLabel: '500 ml',
                    servingSizeLabel: '15 ml',
                    per100Kcal: 120,
                    per100Carbs: 5,
                    per100Fat: 3,
                  ),
                );
              },
            ),
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

      final notifier = container.read(provider.notifier);
      final outcome = await notifier.scanNutritionLabel();
      final state = container.read(provider);

      expect(
        outcome,
        InventoryReceiptManualProductNutritionScanOutcome.applied,
      );
      expect(state.kcalText, '120');
      expect(state.saturatedFatText, isEmpty);
      expect(state.polyunsaturatedFatText, isEmpty);
      expect(state.showPolyunsaturatedFatField, isFalse);
      expect(state.proteinText, isEmpty);
      expect(state.carbsText, '5');
      expect(state.sugarText, isEmpty);
      expect(state.fiberText, isEmpty);
      expect(state.showFiberField, isFalse);
      expect(state.fatText, '3');
      expect(state.saltText, isEmpty);
      expect(state.weightAmount, '500');
      expect(state.selectedWeightUnit, InventoryAmountUnit.milliliter);
      expect(state.hasCompleteNutritionInput, isFalse);
      expect(state.nameText, 'Olivenoel');
      expect(state.brandText, 'Gut Bio');

      notifier.startAddingOptionalNutrition();
      notifier.updateOptionalNutritionValueText('0');
      notifier.applyOptionalNutrition();
      final polyState = container.read(provider);
      expect(polyState.showPolyunsaturatedFatField, isTrue);
      expect(polyState.polyunsaturatedFatText, '0');
      expect(polyState.showFiberField, isFalse);

      notifier.startAddingOptionalNutrition();
      notifier.updateOptionalNutritionValueText('1');
      notifier.applyOptionalNutrition();
      final fiberState = container.read(provider);
      expect(fiberState.showFiberField, isTrue);
      expect(fiberState.fiberText, '1');
    },
  );
}
