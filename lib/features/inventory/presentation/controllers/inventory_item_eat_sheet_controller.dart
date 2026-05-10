import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_item_eat_sheet_controller_models.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_nutrition_format.dart';
import 'package:yamt/l10n/app_localizations.dart';

export 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_item_eat_sheet_controller_models.dart';

/// Controls inventory eat sheet amount and portion calculations.
class InventoryItemEatSheetController {
  /// The inventory eat sheet controller.
  const InventoryItemEatSheetController({
    required this.item,
    required this.maxAmount,
  });

  /// Item being consumed.
  final InventoryItem item;

  /// Maximum inventory amount that may be consumed.
  final int maxAmount;

  /// Whether the item needs a manually entered calorie portion.
  bool get requiresManualCaloriePortion {
    return inventoryItemRequiresManualCaloriePortion(item);
  }

  /// Whether non-edible amount can reduce calories for this item.
  bool get supportsInedibleAmountAdjustment {
    return inventoryItemUsesFixedCalorieUnit(item);
  }

  /// Consumed unit for fixed-unit calorie items.
  ConsumedUnit? get fixedCalorieUnit {
    return inventoryItemConsumedUnit(item);
  }

  /// Whether portion mode can be used.
  bool get canUsePortions {
    return item.nutrition?.hasAnyNutritionValue == true;
  }

  /// Units the portion amount can use.
  List<ConsumedUnit> get availablePortionUnits {
    final fixedUnit = inventoryItemConsumedUnit(item);
    if (fixedUnit != null) {
      return <ConsumedUnit>[fixedUnit];
    }
    return const <ConsumedUnit>[
      ConsumedUnit.grams,
      ConsumedUnit.milliliters,
    ];
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

  /// Parses a positive amount.
  double? parsePositiveAmount(String rawValue) {
    final normalized = rawValue.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  /// Parses a non-negative amount.
  double? parseNonNegativeAmount(String rawValue) {
    final normalized = rawValue.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed < 0) {
      return null;
    }
    return parsed;
  }

  /// Parses the active quick amount.
  int? selectedQuickAmount({
    required bool usesPortionMode,
    required String inventoryAmountText,
    required String portionCountText,
  }) {
    if (usesPortionMode) {
      final count = parsePositiveAmount(portionCountText);
      if (count == null || !isWholeNumber(count)) {
        return null;
      }
      return count.round();
    }
    return parseInventoryAmount(inventoryAmountText);
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
    final count = parsePositiveAmount(countText);
    final baseAmount = parsePositiveAmount(amountText);
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

  /// Resolves inventory amount from portion input.
  int? resolveInventoryAmountFromPortion({
    required double count,
    required double totalAmount,
    required ConsumedUnit unit,
  }) {
    final inventoryUnit = inventoryUnitForConsumedUnit(unit);
    if (inventoryItemUsesFixedCalorieUnit(item)) {
      if (inventoryUnit != inventoryAmountUnit) {
        return null;
      }
      return _ceilPositiveAmountWithinRemainingStock(totalAmount);
    }

    return parseInventoryAmount(
      formatInventoryNutritionValue(count),
    );
  }

  /// Resolves inventory amount from current portion input.
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

  /// Maps consumed unit to inventory unit.
  InventoryAmountUnit? inventoryUnitForConsumedUnit(ConsumedUnit unit) {
    return switch (unit) {
      ConsumedUnit.grams => InventoryAmountUnit.gram,
      ConsumedUnit.milliliters => InventoryAmountUnit.milliliter,
    };
  }

  /// Default portion label.
  String defaultPortionLabel(AppLocalizations l10n) {
    if (requiresManualCaloriePortion &&
        inventoryAmountUnit == InventoryAmountUnit.piece) {
      return l10n.inventoryItemEatSheetUnitPiece;
    }
    return l10n.inventoryItemEatSheetDefaultPortionLabel;
  }

  /// Portion label for display.
  String portionLabelForDisplay({
    required AppLocalizations l10n,
    required String rawLabel,
  }) {
    final label = rawLabel.trim();
    if (label.isEmpty) {
      return defaultPortionLabel(l10n);
    }
    return label;
  }

  /// Normalized learned portion label.
  String? normalizedPortionLabel({
    required AppLocalizations l10n,
    required String rawLabel,
  }) {
    final label = rawLabel.trim();
    if (label.isEmpty ||
        label == defaultPortionLabel(l10n) ||
        label == l10n.inventoryItemEatSheetDefaultPortionLabel) {
      return null;
    }
    return label;
  }

  /// Normalizes a selected portion unit against available units.
  ConsumedUnit normalizePortionUnit(ConsumedUnit unit) {
    final units = availablePortionUnits;
    if (units.contains(unit)) {
      return unit;
    }
    return units.first;
  }

  /// Returns the inventory mode label.
  String inventoryAmountModeLabel(AppLocalizations l10n) {
    return switch (inventoryAmountUnit) {
      InventoryAmountUnit.gram => l10n.inventoryItemEatSheetUnitGram,
      InventoryAmountUnit.milliliter =>
        l10n.inventoryItemEatSheetUnitMilliliter,
      InventoryAmountUnit.piece => l10n.inventoryItemEatSheetUnitPiece,
    };
  }

  /// Resolves amount used for nutrition preview.
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
        final inedibleAmount = parseNonNegativeAmount(inedibleAmountText);
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

    final inedibleAmount = parseNonNegativeAmount(inedibleAmountText);
    if (inedibleAmountText.trim().isNotEmpty && inedibleAmount == null) {
      return null;
    }

    return resolveConsumedAmount(
      inventoryAmount: inventoryAmount,
      inedibleAmount: inedibleAmount,
    );
  }

  /// Resolves fixed-unit calorie amount.
  double? resolveFixedUnitCalorieAmount({
    required int inventoryAmount,
    required double? inedibleAmount,
  }) {
    if (inedibleAmount == null || inedibleAmount <= 0) {
      return null;
    }

    return resolveConsumedAmount(
      inventoryAmount: inventoryAmount,
      inedibleAmount: inedibleAmount,
    );
  }

  /// Resolves consumed amount after non-edible amount.
  double? resolveConsumedAmount({
    required int inventoryAmount,
    required double? inedibleAmount,
  }) {
    final consumedAmount = inventoryAmount - (inedibleAmount ?? 0);
    if (consumedAmount <= 0) {
      return null;
    }
    return consumedAmount.toDouble();
  }

  /// Builds submit validation data.
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
    final inedibleAmount = parseNonNegativeAmount(inedibleAmountText);
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
      fixedUnitCalorieAmount: _resolveFixedUnitDraftCalorieAmount(
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
          usesPortionMode && parsePositiveAmount(portionCountText) == null,
      hasInvalidPortionAmount:
          usesPortionMode && parsePositiveAmount(portionAmountText) == null,
      needsManualCalorieAmount:
          requiresManualCaloriePortion && !usesPortionMode,
    );
  }

  /// Whether a value is effectively a whole number.
  bool isWholeNumber(double value) {
    return (value - value.roundToDouble()).abs() < 0.001;
  }

  int? _ceilPositiveAmountWithinRemainingStock(double value) {
    if (!value.isFinite || value <= 0) {
      return null;
    }
    final rounded = value.round();
    final amount = (value - rounded).abs() <= 0.001 ? rounded : value.ceil();
    if (amount < 1) {
      return null;
    }
    if (amount > maxAmount && value - maxAmount < 1) {
      return maxAmount;
    }
    return amount;
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

  double? _resolveFixedUnitDraftCalorieAmount({
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
