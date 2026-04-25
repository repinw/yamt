import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Defines receipt weight unit fallback option.
enum ReceiptWeightUnitFallbackOption {
  /// Documented member.
  auto,

  /// Documented member.
  gram,

  /// Documented member.
  milliliter,

  /// Documented member.
  piece
  ;

  /// Resolve.
  InventoryAmountUnit? resolve({required InventoryAmountUnit? autoFallback}) {
    return switch (this) {
      ReceiptWeightUnitFallbackOption.auto => autoFallback,
      ReceiptWeightUnitFallbackOption.gram => InventoryAmountUnit.gram,
      ReceiptWeightUnitFallbackOption.milliliter =>
        InventoryAmountUnit.milliliter,
      ReceiptWeightUnitFallbackOption.piece => InventoryAmountUnit.piece,
    };
  }

  /// From unit.
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
