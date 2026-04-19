import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Defines inventory item progress.
class InventoryItemProgress {
  /// The inventory item progress.
  const InventoryItemProgress({
    required this.remainingRatio,
    required this.remainingLabel,
    required this.segmentedByUnits,
    required this.totalUnits,
    required this.remainingUnits,
  });

  /// The remaining ratio.
  final double remainingRatio;

  /// The remaining label.
  final String remainingLabel;

  /// The segmented by units.
  final bool segmentedByUnits;

  /// The total units.
  final int totalUnits;

  /// The remaining units.
  final int remainingUnits;
}

/// Defines inventory item progress calculator.
class InventoryItemProgressCalculator {
  /// The inventory item progress calculator.
  const InventoryItemProgressCalculator();

  /// From item.
  InventoryItemProgress fromItem(InventoryItem item) {
    if (item.usesAmountProgress) {
      return _fromAmount(item);
    }
    return _fromQuantity(item);
  }

  InventoryItemProgress _fromAmount(InventoryItem item) {
    final unit = item.amountUnit!;
    final initialAmount = item.initialAmount;
    final totalUnits = _safeTotalUnits(item.initialQuantity);
    final remainingAmount = item.currentAmount.clamp(0, initialAmount);
    final remainingUnits = item.quantity.clamp(0, totalUnits);

    return InventoryItemProgress(
      remainingRatio: remainingAmount / initialAmount,
      remainingLabel:
          '${_formatAmount(
            remainingAmount,
            unit,
            scale: item.amountScale,
          )} / '
          '${_formatAmount(
            initialAmount,
            unit,
            scale: item.amountScale,
          )}',
      segmentedByUnits: totalUnits > 1,
      totalUnits: totalUnits,
      remainingUnits: remainingUnits,
    );
  }

  InventoryItemProgress _fromQuantity(InventoryItem item) {
    final totalUnits = _safeTotalUnits(item.initialQuantity);
    final remainingUnits = item.quantity.clamp(0, totalUnits);

    return InventoryItemProgress(
      remainingRatio: remainingUnits / totalUnits,
      remainingLabel: '$remainingUnits/$totalUnits',
      segmentedByUnits: totalUnits > 1,
      totalUnits: totalUnits,
      remainingUnits: remainingUnits,
    );
  }

  int _safeTotalUnits(int initialQuantity) {
    if (initialQuantity < 1) {
      return 1;
    }
    return initialQuantity;
  }

  String _formatAmount(
    int value,
    InventoryAmountUnit unit, {
    required int scale,
  }) {
    return '${formatInventoryAmountValue(
      amount: value,
      unit: unit,
      scale: scale,
    )}${_unitSuffix(unit)}';
  }

  String _unitSuffix(InventoryAmountUnit unit) {
    return switch (unit) {
      InventoryAmountUnit.gram => 'g',
      InventoryAmountUnit.milliliter => 'ml',
      InventoryAmountUnit.piece => 'pc',
    };
  }
}
