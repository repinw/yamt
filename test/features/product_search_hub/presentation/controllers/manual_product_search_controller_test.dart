import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_nutrition/data/'
    'nutrition_label_ocr_repository.dart';
import 'package:yamt/features/product_nutrition/domain/'
    'nutrition_label_ocr_models.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_state.dart';

class _FakeNutritionOcrRepository implements NutritionLabelOcrRepository {
  new({required this.onScanNutritionLabel});

  final Future<NutritionLabelOcrResult> Function(String barcode)
  onScanNutritionLabel;

  @override
  Future<NutritionLabelOcrResult> scanNutritionLabel({
    required String barcode,
    NutritionLabelImageCaptured? onImageCaptured,
  }) {
    return onScanNutritionLabel(barcode);
  }
}

InventoryItem _item({
  String name = 'Unknown',
  String storeName = 'Kaufland',
  String? weight,
  InventoryAmountUnit? amountUnit,
  InventoryItemOrigin origin = InventoryItemOrigin.standard,
  String? ocrName,
}) {
  return InventoryItem.create(
    id: 'item-1',
    name: name,
    entryDate: DateTime.parse('2026-04-02T10:00:00Z'),
    storeName: storeName,
    quantity: 1,
    weight: weight,
    amountUnit: amountUnit,
    origin: origin,
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
  test('config equality compares selected product content', () {
    final first = InventoryReceiptManualProductConfig(
      item: _item(),
      selectedProduct: const OffProductSearchResult(
        code: '4311596490202',
        name: 'Booster Absolute Zero',
        brand: 'Booster',
        packageWeight: '330 ml',
        score: 100,
      ),
    );
    final second = InventoryReceiptManualProductConfig(
      item: _item(),
      selectedProduct: const OffProductSearchResult(
        code: '4311596490202',
        name: 'Booster Absolute Zero',
        brand: 'Booster',
        packageWeight: '330 ml',
        score: 100,
      ),
    );
    final changedWeight = InventoryReceiptManualProductConfig(
      item: _item(),
      selectedProduct: const OffProductSearchResult(
        code: '4311596490202',
        name: 'Booster Absolute Zero',
        brand: 'Booster',
        packageWeight: '500 ml',
        score: 100,
      ),
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first, isNot(changedWeight));
  });

  test('state exposes optional nutrition availability and copy clearing', () {
    const state = InventoryReceiptManualProductState(
      showPolyunsaturatedFatField: true,
      showFiberField: true,
      selectedProduct: InventoryReceiptManualProductSelection(
        source: InventoryReceiptManualProductSelectionSource.externalSearch,
        name: 'Milk',
        barcode: '4006381333931',
      ),
      error: InventoryReceiptManualProductError.requiredPackageWeight,
    );

    expect(state.availableOptionalNutritionTypes, isEmpty);
    expect(state.canAddOptionalNutrition, isFalse);
    expect(state.resolvedOptionalNutritionType, isNull);

    final cleared = state.copyWith(selectedProduct: null, error: null);
    expect(cleared.selectedProduct, isNull);
    expect(cleared.error, isNull);
  });

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

  test('buildSavePayload marks entered nutrition complete but unverified', () {
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
    final controller = container.read(provider.notifier)
      ..updateKcalText('2')
      ..updateFatText('0')
      ..updateSaturatedFatText('0')
      ..updateCarbsText('0.01')
      ..updateSugarText('0.01')
      ..updateProteinText('0.02')
      ..updateSaltText('0.01');

    final payload = controller.buildSavePayload();

    expect(payload, isNotNull);
    expect(
      payload?.item.nutrition?.qualityStatus,
      GlobalFoodNutritionQualityStatus.unverified,
    );
    expect(payload?.item.nutrition?.hasEuMandatoryNutritionDeclaration, isTrue);
  });

  test('buildSavePayload keeps verified nutrition with tiny float drift', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const selectedProduct = OffProductSearchResult(
      code: '4311596490202',
      name: 'Booster Absolute Zero',
      brand: 'Booster',
      packageWeight: '330 ml',
      score: 100,
      nutrition: GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 2.0000004,
        per100Protein: 0,
        per100Carbs: 0.0100004,
        per100Fat: 0,
      ),
    );
    final config = InventoryReceiptManualProductConfig(
      item: _item(),
      selectedProduct: selectedProduct,
    );
    final provider = inventoryReceiptManualProductControllerProvider(config);
    final controller = container.read(provider.notifier)
      ..updateKcalText('2')
      ..updateFatText('0')
      ..updateCarbsText('0.01')
      ..updateProteinText('0');

    final payload = controller.buildSavePayload();

    expect(payload, isNotNull);
    expect(
      payload?.item.nutrition?.qualityStatus,
      GlobalFoodNutritionQualityStatus.verified,
    );
  });

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

  test('buildDirectSearchResultPayload normalizes fractional piece amount'
      ' for inventory storage', () {
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
  });

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
    'buildDirectSearchResultPayload returns null when core macros are missing',
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
            qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
            per100Kcal: 100,
            per100Protein: 10,
            per100Fat: 3,
          ),
        ),
        action: InventoryReceiptManualProductAction.eatNow,
      );

      expect(payload, isNull);
    },
  );

  test('buildDirectSearchResultPayload returns null when barcode is blank', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final config = InventoryReceiptManualProductConfig(item: _item());
    final provider = inventoryReceiptManualProductControllerProvider(config);
    final controller = container.read(provider.notifier);

    final payload = controller.buildDirectSearchResultPayload(
      product: const OffProductSearchResult(
        code: '',
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

    expect(payload, isNull);
  });

  test('buildPreviewData uses manual text with matched product media', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const selectedProduct = OffProductSearchResult(
      code: '4311596490202',
      name: 'Booster Absolute Zero',
      brand: 'Booster',
      imageUrl: 'https://example.com/image.png',
      packageWeight: '330 ml',
      score: 100,
    );
    final config = InventoryReceiptManualProductConfig(
      item: _item(),
      selectedProduct: selectedProduct,
    );
    final provider = inventoryReceiptManualProductControllerProvider(config);
    final controller = container.read(provider.notifier)
      ..updateNameText('  Custom Zero  ')
      ..updateBrandText('  Custom Brand  ');

    final preview = controller.buildPreviewData();

    expect(preview?.name, 'Custom Zero');
    expect(preview?.brand, 'Custom Brand');
    expect(preview?.weight, '330 ml');
    expect(preview?.imageUrl, 'https://example.com/image.png');
  });

  test(
    'no barcode mark clears the barcode and allows the label scan',
    () async {
      String? scannedBarcode;
      final container = ProviderContainer(
        overrides: [
          nutritionLabelOcrRepositoryProvider.overrideWithValue(
            _FakeNutritionOcrRepository(
              onScanNutritionLabel: (barcode) async {
                scannedBarcode = barcode;
                return NutritionLabelOcrResult.succeeded(
                  draft: NutritionLabelOcrDraft(
                    barcode: barcode,
                    per100Kcal: 88,
                  ),
                );
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final provider = inventoryReceiptManualProductControllerProvider(
        InventoryReceiptManualProductConfig(
          item: _item().copyWith(barcode: '4006381333931'),
        ),
      );
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      final notifier = container.read(provider.notifier)
        ..updateHasNoBarcode(value: true);

      expect(container.read(provider).barcode, isEmpty);
      expect(container.read(provider).canScanNutritionLabel, isTrue);

      final outcome = await notifier.scanNutritionLabel();

      expect(
        outcome,
        InventoryReceiptManualProductNutritionScanOutcome.applied,
      );
      expect(scannedBarcode, isEmpty);
      expect(container.read(provider).kcalText, '88');
    },
  );

  test('an empty draft starts without a unit until the user picks one', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = inventoryReceiptManualProductControllerProvider(
      InventoryReceiptManualProductConfig(item: _item(name: '')),
    );
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    expect(container.read(provider).selectedWeightUnit, isNull);

    container
        .read(provider.notifier)
        .updateWeightUnit(InventoryAmountUnit.milliliter);

    expect(
      container.read(provider).selectedWeightUnit,
      InventoryAmountUnit.milliliter,
    );
  });

  test('updateBarcode enables the nutrition label scan', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final provider = inventoryReceiptManualProductControllerProvider(
      InventoryReceiptManualProductConfig(item: _item().copyWith(barcode: '')),
    );
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    expect(container.read(provider).canScanNutritionLabel, isFalse);

    container.read(provider.notifier).updateBarcode('4006381333931');

    final state = container.read(provider);
    expect(state.barcode, '4006381333931');
    expect(state.canScanNutritionLabel, isTrue);
  });

  test(
    'applyScannedBarcodeOnly keeps entered values and drops the product',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const selectedProduct = OffProductSearchResult(
        code: '4311596490202',
        name: 'Booster Absolute Zero',
        brand: 'Booster',
        packageWeight: '330 ml',
        score: 100,
        nutrition: GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.verified,
          per100Kcal: 2,
          per100Protein: 0,
          per100Carbs: 0,
          per100Fat: 0,
          per100Fiber: 1,
        ),
      );
      final config = InventoryReceiptManualProductConfig(
        item: _item(),
        selectedProduct: selectedProduct,
      );
      final provider = inventoryReceiptManualProductControllerProvider(config);
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      container.read(provider.notifier)
        ..updateNameText('Mein Booster')
        ..applyScannedBarcodeOnly('4006381333931');
      final state = container.read(provider);

      expect(state.barcode, '4006381333931');
      expect(state.nameText, 'Mein Booster');
      expect(state.brandText, 'Booster');
      expect(state.selectedProduct, isNull);
      expect(state.kcalText, '2');
      expect(state.fiberText, '1');
      expect(state.showFiberField, isTrue);
    },
  );

  test('buildSavePayload stores normalized manual piece amount for inventory'
      ' and global payload', () {
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
        .applyScannedProduct(
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

  test('invalid weight clears amount and leaves the unit to the user', () {
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
    expect(state.selectedWeightUnit, isNull);
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

      final notifier = container.read(provider.notifier)..updateKcalText('700');

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

    final notifier = container.read(provider.notifier)
      ..updateNameText('Mein Oel')
      ..updateBrandText('Hausmarke');

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

    final notifier = container.read(provider.notifier)
      ..updateKcalText('0')
      ..updateSaturatedFatText('0')
      ..updateProteinText('0')
      ..updateCarbsText('0')
      ..updateSugarText('0')
      ..updateFatText('0')
      ..updateSaltText('0');

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

    container.read(provider.notifier).startAddingOptionalNutrition();
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
          nutritionLabelOcrRepositoryProvider.overrideWithValue(
            _FakeNutritionOcrRepository(
              onScanNutritionLabel: (barcode) async {
                return NutritionLabelOcrResult.succeeded(
                  draft: NutritionLabelOcrDraft(
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
      expect(state.nameText, 'Olivenoel');
      expect(state.brandText, 'Gut Bio');

      notifier
        ..startAddingOptionalNutrition()
        ..updateOptionalNutritionValueText('0')
        ..applyOptionalNutrition();
      final polyState = container.read(provider);
      expect(polyState.showPolyunsaturatedFatField, isTrue);
      expect(polyState.polyunsaturatedFatText, '0');
      expect(polyState.showFiberField, isFalse);

      notifier
        ..startAddingOptionalNutrition()
        ..updateOptionalNutritionValueText('1')
        ..applyOptionalNutrition();
      final fiberState = container.read(provider);
      expect(fiberState.showFiberField, isTrue);
      expect(fiberState.fiberText, '1');
    },
  );

  test('scanNutritionLabel maps App Check throttling outcome', () async {
    final config = _config(
      selectedProduct: const OffProductSearchResult(
        code: '4061462542046',
        name: 'Olivenoel',
        score: 100,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        nutritionLabelOcrRepositoryProvider.overrideWithValue(
          _FakeNutritionOcrRepository(
            onScanNutritionLabel: (_) async {
              return const NutritionLabelOcrResult.failed(
                errorCode: NutritionLabelOcrErrorCodes.appCheckThrottled,
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

    final outcome = await container
        .read(provider.notifier)
        .scanNutritionLabel();

    expect(
      outcome,
      InventoryReceiptManualProductNutritionScanOutcome.appCheckThrottled,
    );
  });
}
