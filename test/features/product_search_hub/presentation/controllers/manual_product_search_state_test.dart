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

/// Oat milk in stock: 1 l, a barcode, and a full EU label.
final _config = InventoryReceiptManualProductConfig(
  item: InventoryItem.create(
    id: 'oat-milk',
    name: 'Oat milk',
    brand: 'Oatly',
    barcode: '7394376616037',
    entryDate: DateTime.parse('2026-10-01T10:00:00Z'),
    storeName: 'Rewe',
    quantity: 1,
    weight: '1000 ml',
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 46,
      per100Fat: 1.5,
      per100SaturatedFat: 0.2,
      per100Carbs: 6.7,
      per100Sugar: 4,
      per100Protein: 1,
      per100Salt: 0.1,
    ),
  ),
);

({
  InventoryReceiptManualProductController controller,
  InventoryReceiptManualProductState Function() state,
})
_openEditor() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final provider = inventoryReceiptManualProductControllerProvider(_config);
  final subscription = container.listen(provider, (_, _) {});
  addTearDown(subscription.close);
  return (
    controller: container.read(provider.notifier),
    state: () => container.read(provider),
  );
}

void main() {
  test('an opened editor is unchanged', () {
    final editor = _openEditor();

    expect(editor.state().initial, isNotNull);
    expect(editor.state().isChanged, isFalse);
  });

  test('values that read the same do not count as a change', () {
    final editor = _openEditor();

    editor.controller
      ..updateNameText('  Oat milk ')
      ..updateBrandText('Oatly ')
      ..updateBarcode(' 7394376616037')
      ..updateWeightAmount('1000.0')
      ..updateFatText('1,50')
      ..updateSugarText('4.0')
      // An empty optional row shows no value.
      ..showOptionalNutrition(InventoryReceiptOptionalNutritionType.fiber);

    expect(editor.state().isChanged, isFalse);
  });

  test('a changed value counts until it is changed back', () {
    final editor = _openEditor();

    editor.controller.updateSaltText('0,2');
    expect(editor.state().isChanged, isTrue);

    editor.controller.updateSaltText('0.1');
    expect(editor.state().isChanged, isFalse);
  });

  test('text that is no number counts as a change', () {
    final editor = _openEditor();

    editor.controller.updatePieceWeightText('abc');

    expect(editor.state().isChanged, isTrue);
  });

  for (final (name, change)
      in <(String, void Function(InventoryReceiptManualProductController))>[
        ('the name', (c) => c.updateNameText('Barista oat milk')),
        ('the brand', (c) => c.updateBrandText('')),
        ('the package size', (c) => c.updateWeightAmount('500')),
        ('the unit', (c) => c.updateWeightUnit(InventoryAmountUnit.gram)),
        ('the grams per piece', (c) => c.updatePieceWeightText('30')),
        ('an optional value', (c) => c.updateFiberText('0.8')),
        ('the barcode', (c) => c.updateBarcode('4006381333931')),
        ('the "has none" mark', (c) => c.updateHasNoBarcode(value: true)),
        (
          'a scanned product',
          (c) => c.applyScannedProduct(
            const OffProductSearchResult(
              code: '7394376616037',
              name: 'Oat milk',
              score: 1,
            ),
          ),
        ),
      ]) {
    test('$name counts as a change', () {
      final editor = _openEditor();

      change(editor.controller);

      expect(editor.state().isChanged, isTrue);
    });
  }

  test('the same product scanned again is no change', () {
    final product = OffProductSearchResult(
      code: '7394376616037',
      name: 'Oat milk',
      brand: 'Oatly',
      packageWeight: '1000 ml',
      nutrition: _config.item.nutrition,
      score: 1,
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = inventoryReceiptManualProductControllerProvider(
      InventoryReceiptManualProductConfig(
        item: _config.item,
        selectedProduct: product,
      ),
    );
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    container.read(provider.notifier).applyScannedProduct(product);

    expect(container.read(provider).isChanged, isFalse);
  });

  test('a state that no editor opened counts as changed', () {
    expect(const InventoryReceiptManualProductState().isChanged, isTrue);
  });
}
