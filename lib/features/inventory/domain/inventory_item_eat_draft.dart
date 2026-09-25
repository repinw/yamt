import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_calculator.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';

/// Validated input of the eat sheet, ready to become an eat request.
class InventoryItemEatSubmissionDraft {
  /// Creates the submit validation data.
  const new({
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

  /// Calorie amount for fixed-unit items after the non-edible adjustment.
  final double? fixedUnitCalorieAmount;

  /// Whether the inventory amount is invalid.
  final bool hasInvalidInventoryAmount;

  /// Whether the non-edible amount cannot be parsed.
  final bool hasInvalidInedibleAmount;

  /// Whether the non-edible amount is not smaller than the eaten amount.
  final bool hasTooLargeInedibleAmount;

  /// Whether the portion count is invalid.
  final bool hasInvalidPortionCount;

  /// Whether the portion base amount is invalid.
  final bool hasInvalidPortionAmount;

  /// Whether submit has validation errors.
  bool get hasValidationErrors {
    return hasInvalidInventoryAmount ||
        hasInvalidPortionCount ||
        hasInvalidPortionAmount ||
        hasInvalidInedibleAmount ||
        hasTooLargeInedibleAmount;
  }
}

/// Validation and nutrition amounts of the eat sheet input.
extension InventoryItemEatDraftRules on InventoryItemEatCalculator {
  /// Amount the nutrition preview is calculated for, or null without one.
  double? resolvedNutritionAmount({
    required bool usesPortionMode,
    required String portionCountText,
    required String portionAmountText,
    required ConsumedUnit portionUnit,
    required String inventoryAmountText,
    required String inedibleAmountText,
  }) {
    if (usesPortionMode) {
      final portion = parsePortionInput(
        usesPortionMode: usesPortionMode,
        countText: portionCountText,
        amountText: portionAmountText,
        unit: portionUnit,
      );
      if (portion == null) {
        return null;
      }
      if (supportsInedibleAmountAdjustment) {
        final inedibleAmount = parseNonNegativeDecimalInput(inedibleAmountText);
        if (inedibleAmountText.trim().isNotEmpty && inedibleAmount == null) {
          return null;
        }
        final consumedAmount = portion.totalAmount - (inedibleAmount ?? 0);
        return consumedAmount <= 0 ? null : consumedAmount;
      }
      return portion.totalAmount;
    }

    if (requiresManualCaloriePortion) {
      return null;
    }

    final inventoryAmount = parseInventoryAmount(inventoryAmountText);
    if (inventoryAmount == null || inventoryAmount < 1) {
      return null;
    }

    final inedibleAmount = parseNonNegativeDecimalInput(inedibleAmountText);
    if (inedibleAmountText.trim().isNotEmpty && inedibleAmount == null) {
      return null;
    }

    return _consumedAmount(
      inventoryAmount: inventoryAmount,
      inedibleAmount: inedibleAmount,
    );
  }

  /// Validates the input and builds the submission draft.
  InventoryItemEatSubmissionDraft buildSubmissionDraft({
    required bool usesPortionMode,
    required String inventoryAmountText,
    required String portionCountText,
    required String portionAmountText,
    required ConsumedUnit portionUnit,
    required String inedibleAmountText,
  }) {
    final rawInventoryAmount = parseInventoryAmount(inventoryAmountText);
    final portion = parsePortionInput(
      usesPortionMode: usesPortionMode,
      countText: portionCountText,
      amountText: portionAmountText,
      unit: portionUnit,
    );
    final portionInventoryAmount = portion == null
        ? null
        : resolveInventoryAmountFromPortion(
            count: portion.count,
            totalAmount: portion.totalAmount,
            unit: portion.unit,
          );
    final inventoryAmount = usesPortionMode
        ? portionInventoryAmount
        : rawInventoryAmount;
    final inedibleAmount = parseNonNegativeDecimalInput(inedibleAmountText);
    final hasInvalidInedibleAmount =
        inedibleAmountText.trim().isNotEmpty && inedibleAmount == null;
    final baseAmountForCalories = _baseAmountForFixedUnitCalories(
      usesPortionMode: usesPortionMode,
      portionTotalAmount: portion?.totalAmount,
      inventoryAmount: inventoryAmount,
    );
    final hasTooLargeInedibleAmount =
        baseAmountForCalories != null &&
        inedibleAmount != null &&
        inedibleAmount >= baseAmountForCalories;

    return InventoryItemEatSubmissionDraft(
      inventoryAmount: inventoryAmount,
      portionCount: portion?.count,
      portionBaseAmount: portion?.baseAmount,
      portionTotalAmount: portion?.totalAmount,
      inedibleAmount: inedibleAmount,
      fixedUnitCalorieAmount: _fixedUnitDraftCalorieAmount(
        usesPortionMode: usesPortionMode,
        baseAmountForCalories: baseAmountForCalories,
        inedibleAmount: inedibleAmount,
      ),
      hasInvalidInventoryAmount:
          inventoryAmount == null ||
          inventoryAmount < 1 ||
          inventoryAmount > maxAmount,
      hasInvalidInedibleAmount: hasInvalidInedibleAmount,
      hasTooLargeInedibleAmount: hasTooLargeInedibleAmount,
      hasInvalidPortionCount:
          usesPortionMode &&
          parsePositiveDecimalInput(portionCountText) == null,
      hasInvalidPortionAmount:
          usesPortionMode &&
          parsePositiveDecimalInput(portionAmountText) == null,
    );
  }

  double? _consumedAmount({
    required int inventoryAmount,
    required double? inedibleAmount,
  }) {
    final consumedAmount = inventoryAmount - (inedibleAmount ?? 0);
    if (consumedAmount <= 0) {
      return null;
    }
    return consumedAmount.toDouble();
  }

  double? _baseAmountForFixedUnitCalories({
    required bool usesPortionMode,
    required double? portionTotalAmount,
    required int? inventoryAmount,
  }) {
    if (!inventoryItemUsesFixedCalorieUnit(item)) {
      return null;
    }
    if (usesPortionMode) {
      return portionTotalAmount;
    }
    return inventoryAmount?.toDouble();
  }

  double? _fixedUnitDraftCalorieAmount({
    required bool usesPortionMode,
    required double? baseAmountForCalories,
    required double? inedibleAmount,
  }) {
    if (baseAmountForCalories == null) {
      return null;
    }
    final consumedAmount = baseAmountForCalories - (inedibleAmount ?? 0);
    if (consumedAmount <= 0) {
      return null;
    }
    if (usesPortionMode || (inedibleAmount ?? 0) > 0) {
      return consumedAmount;
    }
    return null;
  }
}
