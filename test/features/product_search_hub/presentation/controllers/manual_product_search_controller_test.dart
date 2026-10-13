import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_state.dart';

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

  test('an edited AI food never asks for the shared catalog (#701)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final item = InventoryItem.create(
      id: 'item-ai',
      name: 'Eier mit Speck',
      entryDate: DateTime.parse('2026-04-02T10:00:00Z'),
      storeName: 'Manual',
      quantity: 1,
      weight: '300 g',
      aiEstimated: true,
      nutrition: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
        per100Kcal: 180,
        per100Fat: 12,
        per100SaturatedFat: 4,
        per100Carbs: 5,
        per100Sugar: 1,
        per100Protein: 13,
        per100Salt: 1.2,
      ),
    ).withDerivedAmount();
    final provider = inventoryReceiptManualProductControllerProvider(
      InventoryReceiptManualProductConfig(item: item),
    );
    final controller = container.read(provider.notifier)
      ..updateNameText('Eier mit Speck und Brot');

    final payload = controller.buildSavePayload();

    expect(payload?.requiresGlobalPersistence, isFalse);
    expect(payload?.item.aiEstimated, isTrue);
  });

  group('the picked food decides the AI mark (#701)', () {
    const nutrition = GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
      per100Kcal: 180,
      per100Fat: 12,
      per100SaturatedFat: 4,
      per100Carbs: 5,
      per100Sugar: 1,
      per100Protein: 13,
      per100Salt: 1.2,
    );
    InventoryItem food({required bool aiEstimated}) => InventoryItem.create(
      id: aiEstimated ? 'item-ai' : 'item-real',
      name: aiEstimated ? 'Eier mit Speck' : 'Skyr',
      entryDate: DateTime.parse('2026-04-02T10:00:00Z'),
      storeName: 'Manual',
      quantity: 1,
      weight: '300 g',
      aiEstimated: aiEstimated,
      nutrition: nutrition,
    ).withDerivedAmount();

    test('a real product picked for an AI item is no AI estimate', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = inventoryReceiptManualProductControllerProvider(
        InventoryReceiptManualProductConfig(item: food(aiEstimated: true)),
      );
      final controller = container.read(provider.notifier)
        ..applyRecentItem(food(aiEstimated: false));

      final payload = controller.buildSavePayload();

      expect(payload?.item.aiEstimated, isFalse);
    });

    test('an AI food picked from the recent items stays one', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = inventoryReceiptManualProductControllerProvider(
        InventoryReceiptManualProductConfig(item: food(aiEstimated: false)),
      );
      final controller = container.read(provider.notifier)
        ..applyRecentItem(food(aiEstimated: true))
        ..updateNameText('Eier mit Speck und Brot');

      final payload = controller.buildSavePayload();

      expect(payload?.item.aiEstimated, isTrue);
      expect(payload?.requiresGlobalPersistence, isFalse);
    });
  });

  test('editing an item keeps its package count and counts all packages', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final item = InventoryItem.create(
      id: 'item-2',
      name: 'Quark',
      entryDate: DateTime.parse('2026-04-02T10:00:00Z'),
      storeName: 'Kaufland',
      quantity: 2,
      initialQuantity: 2,
      weight: '500 g',
      barcode: '4311596490202',
    ).withDerivedAmount();
    expect(item.initialAmount, 1000);
    final provider = inventoryReceiptManualProductControllerProvider(
      InventoryReceiptManualProductConfig(item: item),
    );
    final controller = container.read(provider.notifier)
      ..updateNameText('Magerquark');

    final renamed = controller.buildSavePayload()?.item;

    expect(renamed?.name, 'Magerquark');
    expect(renamed?.quantity, 2);
    expect(renamed?.initialAmount, 1000);
    expect(renamed?.currentAmount, 1000);

    controller.updateWeightAmount('250');
    final resized = controller.buildSavePayload()?.item;

    expect(resized?.weight, '250 g');
    expect(resized?.quantity, 2);
    expect(resized?.initialAmount, 500);
    expect(resized?.currentAmount, 500);
  });

  test(
    'editing a receipt item keeps its stock however the size is written',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final item = InventoryItem.create(
        id: 'item-4',
        name: 'Joghurt',
        entryDate: DateTime.parse('2026-04-02T10:00:00Z'),
        storeName: 'Kaufland',
        quantity: 1,
        weight: '2x250g',
        barcode: '4311596490202',
      ).withDerivedAmount().copyWith(currentAmount: 300);
      final provider = inventoryReceiptManualProductControllerProvider(
        InventoryReceiptManualProductConfig(item: item),
      );
      final controller = container.read(provider.notifier)
        ..updateNameText('Naturjoghurt');

      final renamed = controller.buildSavePayload()?.item;

      expect(renamed?.name, 'Naturjoghurt');
      expect(renamed?.initialAmount, 500);
      expect(renamed?.currentAmount, 300);
    },
  );

  test('a new package size keeps the share of a partly eaten stock', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final item = InventoryItem.create(
      id: 'item-5',
      name: 'Quark',
      entryDate: DateTime.parse('2026-04-02T10:00:00Z'),
      storeName: 'Kaufland',
      quantity: 2,
      initialQuantity: 2,
      weight: '500 g',
      barcode: '4311596490202',
    ).withDerivedAmount().copyWith(quantity: 1, currentAmount: 400);
    expect(item.initialQuantity, 2);
    final provider = inventoryReceiptManualProductControllerProvider(
      InventoryReceiptManualProductConfig(item: item),
    );
    final controller = container.read(provider.notifier)
      ..updateWeightAmount('250');

    final resized = controller.buildSavePayload()?.item;

    expect(resized?.weight, '250 g');
    expect(resized?.initialAmount, 500);
    expect(resized?.currentAmount, 200);
  });

  test('a package size gives a stock counted by packages its amount', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final item = InventoryItem.create(
      id: 'item-6',
      name: 'Joghurt',
      entryDate: DateTime.parse('2026-04-02T10:00:00Z'),
      storeName: 'Kaufland',
      quantity: 1,
      initialQuantity: 3,
      barcode: '4311596490202',
    );
    expect(item.usesAmountProgress, isFalse);
    final provider = inventoryReceiptManualProductControllerProvider(
      InventoryReceiptManualProductConfig(item: item),
    );
    final controller = container.read(provider.notifier)
      ..updateWeightAmount('500');

    final weighed = controller.buildSavePayload()?.item;

    expect(weighed?.initialQuantity, 3);
    expect(weighed?.initialAmount, 1500);
    expect(weighed?.currentAmount, 500);
  });

  test('editing an item keeps an amount changed by hand', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final item = InventoryItem.create(
      id: 'item-3',
      name: 'Quark',
      entryDate: DateTime.parse('2026-04-02T10:00:00Z'),
      storeName: 'Kaufland',
      quantity: 2,
      initialQuantity: 2,
      weight: '500 g',
      barcode: '4311596490202',
    ).withDerivedAmount().copyWith(initialAmount: 1200, currentAmount: 1200);
    final provider = inventoryReceiptManualProductControllerProvider(
      InventoryReceiptManualProductConfig(item: item),
    );
    final controller = container.read(provider.notifier)
      ..updateNameText('Magerquark');

    final renamed = controller.buildSavePayload()?.item;

    expect(renamed?.name, 'Magerquark');
    expect(renamed?.quantity, 2);
    expect(renamed?.initialAmount, 1200);
    expect(renamed?.currentAmount, 1200);
  });

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

  test('the selected product matches until the barcode changes', () {
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
    final controller = container.read(provider.notifier);

    expect(
      container.read(provider).matchedProduct?.imageUrl,
      'https://example.com/image.png',
    );

    controller.updateBarcode('4006381333931');

    expect(container.read(provider).matchedProduct, isNull);
  });

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

  test('an eat-now save without package size keeps the gram unit', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = inventoryReceiptManualProductControllerProvider(
      InventoryReceiptManualProductConfig(item: _item(name: '')),
    );
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    final notifier = container.read(provider.notifier)
      ..updateNameText('Brötchen')
      ..updateWeightUnit(InventoryAmountUnit.gram)
      ..updateKcalText('270')
      ..updateCarbsText('50')
      ..updateProteinText('9')
      ..updateFatText('2');

    final payload = notifier.buildSavePayload(
      action: InventoryReceiptManualProductAction.eatNow,
    );

    expect(payload?.item.amountUnit, InventoryAmountUnit.gram);
    expect(payload?.item.usesAmountProgress, isFalse);
  });

  test('the barcode is settled when entered or marked as missing', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final provider = inventoryReceiptManualProductControllerProvider(
      InventoryReceiptManualProductConfig(item: _item().copyWith(barcode: '')),
    );
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    expect(container.read(provider).hasBarcodeDecision, isFalse);

    container.read(provider.notifier).updateBarcode('4006381333931');
    expect(container.read(provider).hasBarcodeDecision, isTrue);

    container.read(provider.notifier).updateHasNoBarcode(value: true);
    final state = container.read(provider);
    expect(state.barcode, isEmpty);
    expect(state.hasBarcodeDecision, isTrue);
  });

  test('a stored package photo becomes the image of a product without one', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = inventoryReceiptManualProductControllerProvider(
      InventoryReceiptManualProductConfig(item: _item(name: '')),
    );
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    final notifier = container.read(provider.notifier)
      ..updateNameText('Haferflocken')
      ..updateBarcode('4006381333931')
      ..updateWeightAmount('500')
      ..updateWeightUnit(InventoryAmountUnit.gram)
      ..updateKcalText('372');

    final payload = notifier.buildSavePayload(
      photoImageUrl: 'https://example.com/front.jpg',
    );

    expect(payload?.item.imageUrl, 'https://example.com/front.jpg');
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

  test('invalid weight clears amount and keeps the item unit', () {
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

    expect(container.read(provider).availableOptionalNutritionTypes, const [
      InventoryReceiptOptionalNutritionType.polyunsaturatedFat,
    ]);

    container
        .read(provider.notifier)
        .showOptionalNutrition(
          InventoryReceiptOptionalNutritionType.polyunsaturatedFat,
        );
    final state = container.read(provider);

    expect(state.showPolyunsaturatedFatField, isTrue);
    expect(state.polyunsaturatedFatText, isEmpty);
    expect(state.availableOptionalNutritionTypes, isEmpty);
  });

  test('the grams of one piece start from a serving in grams and become the '
      'serving on save', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const selectedProduct = OffProductSearchResult(
      code: '4000000000017',
      name: 'Eier',
      score: 100,
      packageWeight: '10 Stück',
      servingSize: '1 Ei (60 g)',
      servingQuantity: 60,
      servingQuantityUnit: 'g',
    );
    final config = InventoryReceiptManualProductConfig(
      item: _item(),
      selectedProduct: selectedProduct,
    );
    final provider = inventoryReceiptManualProductControllerProvider(config);
    final notifier = container.read(provider.notifier)
      ..applyScannedProduct(selectedProduct);

    expect(container.read(provider).pieceWeightText, '60');

    final payload = (notifier..updatePieceWeightText('55')).buildSavePayload();

    expect(payload?.item.amountUnit, InventoryAmountUnit.piece);
    expect(payload?.item.servingQuantity, 55);
    expect(payload?.item.servingQuantityUnit, 'g');
    expect(payload?.item.servingSize, isNull);
  });
}
