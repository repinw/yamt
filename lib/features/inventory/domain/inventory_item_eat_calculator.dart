import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';

const _wholeNumberTolerance = 0.001;

/// Parsed portion input of the eat sheet.
class InventoryItemEatPortionInput {
  /// Creates parsed portion input.
  const new({
    required this.count,
    required this.baseAmount,
    required this.totalAmount,
    required this.unit,
  });

  /// Portion count.
  final double count;

  /// Amount in one portion.
  final double baseAmount;

  /// Total consumed amount.
  final double totalAmount;

  /// Portion unit.
  final ConsumedUnit unit;
}

/// Amount and portion rules for eating an inventory item.
class InventoryItemEatCalculator {
  /// Creates the calculator for [item] with at most [maxAmount] to eat.
  const new({required this.item, required this.maxAmount});

  /// Item being eaten.
  final InventoryItem item;

  /// Maximum inventory amount that may be eaten.
  final int maxAmount;

  /// Whether the item needs a manually entered calorie portion.
  bool get requiresManualCaloriePortion {
    return inventoryItemRequiresManualCaloriePortion(item);
  }

  /// Whether a non-edible amount can reduce calories for this item.
  bool get supportsInedibleAmountAdjustment {
    return inventoryItemUsesFixedCalorieUnit(item);
  }

  /// Consumed unit for fixed-unit calorie items.
  ConsumedUnit? get fixedCalorieUnit {
    return inventoryItemConsumedUnit(item);
  }

  /// Units the portion amount can use.
  List<ConsumedUnit> get availablePortionUnits {
    final fixedUnit = inventoryItemConsumedUnit(item);
    if (fixedUnit != null) {
      return <ConsumedUnit>[fixedUnit];
    }
    return const <ConsumedUnit>[ConsumedUnit.grams, ConsumedUnit.milliliters];
  }

  /// Inventory unit used by the item.
  InventoryAmountUnit get inventoryAmountUnit {
    if (item.usesAmountProgress && item.amountUnit != null) {
      return item.amountUnit!;
    }
    return InventoryAmountUnit.piece;
  }

  /// Inventory amount scale used by the item.
  int get inventoryAmountScale {
    if (item.usesAmountProgress) {
      return item.amountScale;
    }
    return 1;
  }

  /// Whether fractional inventory amount input is allowed.
  bool get allowsFractionalInventoryAmount {
    return inventoryAmountAllowsFractionalInput(
      unit: inventoryAmountUnit,
      scale: inventoryAmountScale,
    );
  }

  /// Default inventory amount for the current item.
  int defaultInventoryAmount(int? initialInventoryAmount) {
    final defaultAmount = allowsFractionalInventoryAmount
        ? inventoryAmountScale
        : 1;
    final amount = initialInventoryAmount;
    if (amount == null || amount < 1) {
      if (defaultAmount > maxAmount) {
        return maxAmount;
      }
      return defaultAmount;
    }
    if (amount > maxAmount) {
      return maxAmount;
    }
    return amount;
  }

  /// Formats an inventory amount in this item's unit.
  String formatInventoryAmount(int amount) {
    return formatInventoryAmountValue(
      amount: amount,
      unit: inventoryAmountUnit,
      scale: inventoryAmountScale,
    );
  }

  /// Parses an inventory amount in this item's unit.
  int? parseInventoryAmount(String rawValue) {
    return parseInventoryAmountInput(
      rawValue: rawValue,
      unit: inventoryAmountUnit,
      scale: inventoryAmountScale,
    );
  }

  /// Parses the current portion input.
  InventoryItemEatPortionInput? parsePortionInput({
    required bool usesPortionMode,
    required String countText,
    required String amountText,
    required ConsumedUnit unit,
  }) {
    if (!usesPortionMode) {
      return null;
    }
    final count = parsePositiveDecimalInput(countText);
    final baseAmount = parsePositiveDecimalInput(amountText);
    if (count == null || baseAmount == null) {
      return null;
    }
    return InventoryItemEatPortionInput(
      count: count,
      baseAmount: baseAmount,
      totalAmount: count * baseAmount,
      unit: unit,
    );
  }

  /// Resolves the inventory amount that portion input takes from stock.
  int? resolveInventoryAmountFromPortion({
    required double count,
    required double totalAmount,
    required ConsumedUnit unit,
  }) {
    if (inventoryItemUsesFixedCalorieUnit(item)) {
      if (_inventoryUnitForConsumedUnit(unit) != inventoryAmountUnit) {
        return null;
      }
      return _ceilPositiveAmountWithinRemainingStock(totalAmount);
    }

    return parseInventoryAmount(_formatPortionCount(count));
  }

  /// Resolves the inventory amount from the current portion input.
  int? inventoryAmountFromPortionInput({
    required bool usesPortionMode,
    required String countText,
    required String amountText,
    required ConsumedUnit unit,
  }) {
    final portion = parsePortionInput(
      usesPortionMode: usesPortionMode,
      countText: countText,
      amountText: amountText,
      unit: unit,
    );
    if (portion == null) {
      return null;
    }
    return resolveInventoryAmountFromPortion(
      count: portion.count,
      totalAmount: portion.totalAmount,
      unit: portion.unit,
    );
  }

  /// Normalizes a selected portion unit against the available units.
  ConsumedUnit normalizePortionUnit(ConsumedUnit unit) {
    final units = availablePortionUnits;
    if (units.contains(unit)) {
      return unit;
    }
    return units.first;
  }

  /// Whether [value] is effectively a whole number.
  bool isWholeNumber(double value) {
    return (value - value.roundToDouble()).abs() < _wholeNumberTolerance;
  }

  int? _ceilPositiveAmountWithinRemainingStock(double value) {
    if (!value.isFinite || value <= 0) {
      return null;
    }
    final rounded = value.round();
    final amount = (value - rounded).abs() <= _wholeNumberTolerance
        ? rounded
        : value.ceil();
    if (amount < 1) {
      return null;
    }
    if (amount > maxAmount && value - maxAmount < 1) {
      return maxAmount;
    }
    return amount;
  }
}

InventoryAmountUnit _inventoryUnitForConsumedUnit(ConsumedUnit unit) {
  return switch (unit) {
    ConsumedUnit.grams => InventoryAmountUnit.gram,
    ConsumedUnit.milliliters => InventoryAmountUnit.milliliter,
  };
}

/// Rounds a portion count to one decimal, as the count field shows it.
String _formatPortionCount(double count) {
  return count % 1 != 0 ? count.toStringAsFixed(1) : count.toStringAsFixed(0);
}
