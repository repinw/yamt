import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_state.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_editor_page/'
    'manual_product_search_editor_support.dart';

const _complete = InventoryReceiptManualProductState(
  nameText: 'Skyr',
  weightAmount: '500',
  kcalText: '63',
  carbsText: '4',
  proteinText: '11',
  fatText: '0.2',
);

void main() {
  test('saving needs name, kcal, carbs, protein and fat', () {
    expect(
      canSaveManualProduct(
        state: _complete,
        selectedAction: InventoryReceiptManualProductAction.addToInventory,
      ),
      isTrue,
    );

    for (final missing in <InventoryReceiptManualProductState>[
      _complete.copyWith(nameText: ' '),
      _complete.copyWith(kcalText: ''),
      _complete.copyWith(carbsText: ''),
      _complete.copyWith(proteinText: ''),
      _complete.copyWith(fatText: ''),
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
}
