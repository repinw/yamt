import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'receipt_item_editor_weight_unit_fallback_option.dart';

void main() {
  test('resolve maps every fallback option to expected unit', () {
    expect(
      ReceiptWeightUnitFallbackOption.auto.resolve(
        autoFallback: InventoryAmountUnit.piece,
      ),
      InventoryAmountUnit.piece,
    );
    expect(
      ReceiptWeightUnitFallbackOption.gram.resolve(autoFallback: null),
      InventoryAmountUnit.gram,
    );
    expect(
      ReceiptWeightUnitFallbackOption.milliliter.resolve(autoFallback: null),
      InventoryAmountUnit.milliliter,
    );
    expect(
      ReceiptWeightUnitFallbackOption.piece.resolve(autoFallback: null),
      InventoryAmountUnit.piece,
    );
  });

  test('fromUnit maps nullable amount unit to fallback option', () {
    expect(
      ReceiptWeightUnitFallbackOption.fromUnit(InventoryAmountUnit.gram),
      ReceiptWeightUnitFallbackOption.gram,
    );
    expect(
      ReceiptWeightUnitFallbackOption.fromUnit(InventoryAmountUnit.milliliter),
      ReceiptWeightUnitFallbackOption.milliliter,
    );
    expect(
      ReceiptWeightUnitFallbackOption.fromUnit(InventoryAmountUnit.piece),
      ReceiptWeightUnitFallbackOption.piece,
    );
    expect(
      ReceiptWeightUnitFallbackOption.fromUnit(null),
      ReceiptWeightUnitFallbackOption.auto,
    );
  });
}
