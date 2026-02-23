import 'package:yamt/features/inventory/domain/fridge_item.dart';

class InventoryItemProgress {
  const InventoryItemProgress({
    required this.remainingRatio,
    required this.remainingLabel,
    required this.segmentedByUnits,
    required this.totalUnits,
    required this.remainingUnits,
  });

  final double remainingRatio;
  final String remainingLabel;
  final bool segmentedByUnits;
  final int totalUnits;
  final int remainingUnits;
}

class InventoryItemProgressCalculator {
  const InventoryItemProgressCalculator();

  InventoryItemProgress fromItem(FridgeItem item) {
    if (_hasAmountProgress(item)) {
      return _fromAmount(item);
    }
    return _fromQuantity(item);
  }

  bool _hasAmountProgress(FridgeItem item) {
    return item.amountUnit != null && item.initialAmount > 0;
  }

  InventoryItemProgress _fromAmount(FridgeItem item) {
    final unit = item.amountUnit!;
    final initialAmount = item.initialAmount;
    final totalUnits = _safeTotalUnits(item.initialQuantity);
    final remainingAmount = item.currentAmount.clamp(0, initialAmount);
    final remainingUnits = item.quantity.clamp(0, totalUnits);

    return InventoryItemProgress(
      remainingRatio: remainingAmount / initialAmount,
      remainingLabel:
          '${_formatAmount(remainingAmount, unit)} / '
          '${_formatAmount(initialAmount, unit)}',
      segmentedByUnits: totalUnits > 1,
      totalUnits: totalUnits,
      remainingUnits: remainingUnits,
    );
  }

  InventoryItemProgress _fromQuantity(FridgeItem item) {
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

  String _formatAmount(int value, FridgeAmountUnit unit) {
    final safeValue = value < 0 ? 0 : value;
    return '$safeValue${_unitSuffix(unit)}';
  }

  String _unitSuffix(FridgeAmountUnit unit) {
    return switch (unit) {
      FridgeAmountUnit.gram => 'g',
      FridgeAmountUnit.milliliter => 'ml',
      FridgeAmountUnit.piece => 'pc',
    };
  }
}
