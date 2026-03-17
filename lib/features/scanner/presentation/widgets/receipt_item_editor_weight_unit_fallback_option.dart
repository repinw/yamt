import 'package:yamt/features/inventory/domain/inventory_item.dart';

enum ReceiptWeightUnitFallbackOption {
  auto,
  gram,
  milliliter,
  piece;

  InventoryAmountUnit? resolve({required InventoryAmountUnit? autoFallback}) {
    return switch (this) {
      ReceiptWeightUnitFallbackOption.auto => autoFallback,
      ReceiptWeightUnitFallbackOption.gram => InventoryAmountUnit.gram,
      ReceiptWeightUnitFallbackOption.milliliter =>
        InventoryAmountUnit.milliliter,
      ReceiptWeightUnitFallbackOption.piece => InventoryAmountUnit.piece,
    };
  }

  static ReceiptWeightUnitFallbackOption fromUnit(InventoryAmountUnit? unit) {
    return switch (unit) {
      InventoryAmountUnit.gram => ReceiptWeightUnitFallbackOption.gram,
      InventoryAmountUnit.milliliter =>
        ReceiptWeightUnitFallbackOption.milliliter,
      InventoryAmountUnit.piece => ReceiptWeightUnitFallbackOption.piece,
      null => ReceiptWeightUnitFallbackOption.auto,
    };
  }
}
