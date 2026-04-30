import 'package:yamt/features/calories/domain/calorie_entry.dart';

/// Parsed portion input.
class InventoryItemEatPortionInput {
  /// The parsed portion input.
  const InventoryItemEatPortionInput({
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

/// Submit validation data for the eat sheet.
class InventoryItemEatSubmissionDraft {
  /// The submit validation data.
  const InventoryItemEatSubmissionDraft({
    required this.inventoryAmount,
    required this.portionCount,
    required this.portionBaseAmount,
    required this.portionTotalAmount,
    required this.inedibleAmount,
    required this.fixedUnitCalorieAmount,
    required this.hasInvalidInventoryAmount,
    required this.hasInvalidInedibleAmount,
    required this.hasTooLargeInedibleAmount,
    required this.hasInvalidPortionCount,
    required this.hasInvalidPortionAmount,
    required this.needsManualCalorieAmount,
  });

  /// Inventory amount to deduct.
  final int? inventoryAmount;

  /// Portion count.
  final double? portionCount;

  /// Amount in one portion.
  final double? portionBaseAmount;

  /// Total calorie amount from portions.
  final double? portionTotalAmount;

  /// Non-edible amount.
  final double? inedibleAmount;

  /// Calorie amount for fixed-unit items after non-edible adjustment.
  final double? fixedUnitCalorieAmount;

  /// Whether inventory amount is invalid.
  final bool hasInvalidInventoryAmount;

  /// Whether non-edible amount cannot be parsed.
  final bool hasInvalidInedibleAmount;

  /// Whether non-edible amount is not smaller than eaten amount.
  final bool hasTooLargeInedibleAmount;

  /// Whether portion count is invalid.
  final bool hasInvalidPortionCount;

  /// Whether portion base amount is invalid.
  final bool hasInvalidPortionAmount;

  /// Whether a manual calorie portion must be collected first.
  final bool needsManualCalorieAmount;

  /// Whether submit has validation errors.
  bool get hasValidationErrors {
    return hasInvalidInventoryAmount ||
        hasInvalidPortionCount ||
        hasInvalidPortionAmount ||
        hasInvalidInedibleAmount ||
        hasTooLargeInedibleAmount;
  }
}
