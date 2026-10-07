import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart'
    show InventoryReceiptManualProductConfig;
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_state.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_editor_page/'
    'manual_product_search_editor_support.dart';

const _complete = InventoryReceiptManualProductState(
  nameText: 'Skyr',
  weightAmount: '500',
  selectedWeightUnit: InventoryAmountUnit.gram,
  kcalText: '63',
  carbsText: '4',
  proteinText: '11',
  fatText: '0.2',
  saturatedFatText: '0.1',
  sugarText: '4',
  saltText: '0.1',
  barcode: '4006381333931',
);

void main() {
  test('saving needs name, unit, barcode, and every EU label value', () {
    expect(
      canSaveManualProduct(
        state: _complete,
        selectedAction: InventoryReceiptManualProductAction.addToInventory,
      ),
      isTrue,
    );

    for (final missing in <InventoryReceiptManualProductState>[
      _complete.copyWith(nameText: ' '),
      InventoryReceiptManualProductState(
        nameText: _complete.nameText,
        kcalText: _complete.kcalText,
        carbsText: _complete.carbsText,
        proteinText: _complete.proteinText,
        fatText: _complete.fatText,
        saturatedFatText: _complete.saturatedFatText,
        sugarText: _complete.sugarText,
        saltText: _complete.saltText,
      ),
      _complete.copyWith(kcalText: ''),
      _complete.copyWith(carbsText: ''),
      _complete.copyWith(proteinText: ''),
      _complete.copyWith(fatText: ''),
      _complete.copyWith(saturatedFatText: ''),
      _complete.copyWith(sugarText: ''),
      _complete.copyWith(saltText: ''),
      _complete.copyWith(barcode: ''),
    ]) {
      expect(
        canSaveManualProduct(
          state: missing,
          selectedAction: InventoryReceiptManualProductAction.eatNow,
        ),
        isFalse,
      );
    }
  });

  test('a barcode alone is not enough to save', () {
    const state = InventoryReceiptManualProductState(
      nameText: 'Skyr',
      barcode: '4006381333931',
      weightAmount: '500',
    );

    expect(
      canSaveManualProduct(
        state: state,
        selectedAction: InventoryReceiptManualProductAction.addToInventory,
      ),
      isFalse,
    );
  });

  test('inventory save also needs a package weight, eating does not', () {
    final noWeight = _complete.copyWith(weightAmount: '');

    expect(
      canSaveManualProduct(
        state: noWeight,
        selectedAction: InventoryReceiptManualProductAction.addToInventory,
      ),
      isFalse,
    );
    expect(
      canSaveManualProduct(
        state: noWeight,
        selectedAction: InventoryReceiptManualProductAction.eatNow,
      ),
      isTrue,
    );
  });

  // The editor uploads the package photos once the payload builds, and builds
  // it again with the photo address afterwards. A savable form must therefore
  // always build a payload, or the save stops with the photos already stored.
  test('a form that can be saved always builds a save payload', () {
    var savable = 0;
    for (final action in <InventoryReceiptManualProductAction>[
      InventoryReceiptManualProductAction.addToInventory,
      InventoryReceiptManualProductAction.eatNow,
    ]) {
      for (final hasBarcode in <bool>[true, false]) {
        for (final hasWeight in <bool>[true, false]) {
          for (final hasNutrition in <bool>[true, false]) {
            final container = ProviderContainer();
            addTearDown(container.dispose);
            final provider = inventoryReceiptManualProductControllerProvider(
              InventoryReceiptManualProductConfig(
                item: InventoryItem.create(
                  id: 'item-1',
                  name: 'Unknown',
                  entryDate: DateTime(2026, 4, 2),
                  storeName: 'Store',
                  quantity: 1,
                ),
              ),
            );
            final controller = container.read(provider.notifier)
              ..updateNameText('Skyr')
              ..updateWeightUnit(InventoryAmountUnit.gram);
            if (hasNutrition) {
              controller
                ..updateKcalText('63')
                ..updateFatText('0.2')
                ..updateSaturatedFatText('0.1')
                ..updateCarbsText('4')
                ..updateSugarText('4')
                ..updateProteinText('11')
                ..updateSaltText('0.1');
            }
            if (hasBarcode) {
              controller.updateBarcode('4006381333931');
            } else {
              controller.updateHasNoBarcode(value: true);
            }
            if (hasWeight) {
              controller.updateWeightAmount('500');
            }
            if (canSaveManualProduct(
              state: container.read(provider),
              selectedAction: action,
            )) {
              savable++;
              expect(
                controller.buildSavePayload(action: action),
                isNotNull,
                reason:
                    '$action, barcode: $hasBarcode, weight: $hasWeight, '
                    'nutrition: $hasNutrition',
              );
            }
          }
        }
      }
    }
    expect(savable, greaterThan(0));
  });
}
