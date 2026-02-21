import 'package:yamt/features/inventory/domain/fridge_item.dart';

enum ReceiptWeightUnitFallbackOption {
  auto,
  gram,
  milliliter,
  piece;

  FridgeAmountUnit? resolve({required FridgeAmountUnit? autoFallback}) {
    return switch (this) {
      ReceiptWeightUnitFallbackOption.auto => autoFallback,
      ReceiptWeightUnitFallbackOption.gram => FridgeAmountUnit.gram,
      ReceiptWeightUnitFallbackOption.milliliter => FridgeAmountUnit.milliliter,
      ReceiptWeightUnitFallbackOption.piece => FridgeAmountUnit.piece,
    };
  }

  static ReceiptWeightUnitFallbackOption fromUnit(FridgeAmountUnit? unit) {
    return switch (unit) {
      FridgeAmountUnit.gram => ReceiptWeightUnitFallbackOption.gram,
      FridgeAmountUnit.milliliter => ReceiptWeightUnitFallbackOption.milliliter,
      FridgeAmountUnit.piece => ReceiptWeightUnitFallbackOption.piece,
      null => ReceiptWeightUnitFallbackOption.auto,
    };
  }
}
