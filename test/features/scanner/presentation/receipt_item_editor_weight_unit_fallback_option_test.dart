import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'receipt_item_editor_weight_unit_fallback_option.dart';

void main() {
  test('resolve maps every fallback option to expected unit', () {
    expect(
      ReceiptWeightUnitFallbackOption.auto.resolve(
        autoFallback: FridgeAmountUnit.piece,
      ),
      FridgeAmountUnit.piece,
    );
    expect(
      ReceiptWeightUnitFallbackOption.gram.resolve(autoFallback: null),
      FridgeAmountUnit.gram,
    );
    expect(
      ReceiptWeightUnitFallbackOption.milliliter.resolve(autoFallback: null),
      FridgeAmountUnit.milliliter,
    );
    expect(
      ReceiptWeightUnitFallbackOption.piece.resolve(autoFallback: null),
      FridgeAmountUnit.piece,
    );
  });

  test('fromUnit maps nullable amount unit to fallback option', () {
    expect(
      ReceiptWeightUnitFallbackOption.fromUnit(FridgeAmountUnit.gram),
      ReceiptWeightUnitFallbackOption.gram,
    );
    expect(
      ReceiptWeightUnitFallbackOption.fromUnit(FridgeAmountUnit.milliliter),
      ReceiptWeightUnitFallbackOption.milliliter,
    );
    expect(
      ReceiptWeightUnitFallbackOption.fromUnit(FridgeAmountUnit.piece),
      ReceiptWeightUnitFallbackOption.piece,
    );
    expect(
      ReceiptWeightUnitFallbackOption.fromUnit(null),
      ReceiptWeightUnitFallbackOption.auto,
    );
  });
}
