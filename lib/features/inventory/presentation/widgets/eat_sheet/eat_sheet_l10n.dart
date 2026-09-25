import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_eat_calculator.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_options.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_state.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meal_eat_sheet_controller.dart';
import 'package:yamt/features/inventory/presentation/formatters/inventory_nutrition_format.dart';
import 'package:yamt/features/inventory/presentation/inventory_amount_unit_l10n.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _quarterGlyphs = ['¼', '½', '¾'];
const _quartersPerUnit = 4;
const _quarterTolerance = 0.000001;

/// Formats an amount with a fraction glyph, for example "1½".
///
/// Amounts without a quarter step use [formatNumber].
String formatQuickChipAmount(num value, String Function(num) formatNumber) {
  final whole = value.floor();
  final quarters = (value - whole) * _quartersPerUnit;
  final quarter = quarters.round();
  if (quarter < 1 ||
      quarter >= _quartersPerUnit ||
      (quarters - quarter).abs() > _quarterTolerance) {
    return formatNumber(value);
  }
  final glyph = _quarterGlyphs[quarter - 1];
  return whole == 0 ? glyph : '$whole$glyph';
}

/// Short unit symbol of a consumed amount, for example "g".
String consumedUnitSymbol(AppLocalizations l10n, ConsumedUnit unit) {
  return switch (unit) {
    ConsumedUnit.grams => l10n.caloriesUnitGram,
    ConsumedUnit.milliliters => l10n.caloriesUnitMilliliter,
  };
}

/// Texts of the inventory item eat page.
extension InventoryItemEatSheetTexts on InventoryItemEatSheetState {
  /// Name of a portion without its own name.
  String defaultPortionLabel(AppLocalizations l10n) {
    if (calculator.requiresManualCaloriePortion &&
        calculator.inventoryAmountUnit == InventoryAmountUnit.piece) {
      return l10n.inventoryItemEatSheetUnitPiece;
    }
    return l10n.inventoryItemEatSheetDefaultPortionLabel;
  }

  /// Unit after the amount: the inventory unit, such as "g" or "pc".
  String amountUnit(AppLocalizations l10n) {
    return calculator.inventoryAmountUnit.localizedName(l10n);
  }

  /// Consumable stock with its unit, such as "180 g".
  String stockLabel(AppLocalizations l10n) {
    return l10n.inventoryEatSheetAmountWithUnit(
      calculator.formatInventoryAmount(calculator.maxAmount),
      amountUnit(l10n),
    );
  }

  /// Entered amount with its unit, such as "60 g".
  String enteredAmountLabel(AppLocalizations l10n) {
    return l10n.inventoryEatSheetAmountWithUnit(
      calculator.formatInventoryAmount(enteredInventoryAmount ?? 0),
      amountUnit(l10n),
    );
  }

  /// Text of a ruler mark.
  String markLabel(AppLocalizations l10n, InventoryItemEatMarker marker) {
    if (marker.isAll) {
      return l10n.eatPageAll;
    }
    final amount = calculator.formatInventoryAmount(marker.value.round());
    final label = marker.label;
    if (label == null) {
      return l10n.inventoryEatSheetAmountWithUnit(amount, amountUnit(l10n));
    }
    return l10n.eatPageMark(label, amount);
  }

  /// Text of a piece size chip, such as "L 68 g".
  String pieceSizeLabel(AppLocalizations l10n, InventoryItemEatPortion size) {
    final weight = l10n.inventoryEatSheetAmountWithUnit(
      formatInventoryNutritionValue(size.amount),
      consumedUnitSymbol(l10n, size.unit),
    );
    final label = size.label;
    return label == null ? weight : l10n.eatPageMark(label, weight);
  }

  /// Entered weight of one piece, such as "68 g", or null without one.
  String? pieceWeightLabel(AppLocalizations l10n) {
    final weight = parsePositiveDecimalInput(portionAmountText);
    if (weight == null) {
      return null;
    }
    return l10n.inventoryEatSheetAmountWithUnit(
      formatInventoryNutritionValue(weight),
      consumedUnitSymbol(l10n, portionUnit),
    );
  }

  /// Note beside the amount: the portions it makes up, or the total weight
  /// of the pieces.
  String? amountHint(AppLocalizations l10n) {
    if (usesPortionMode) {
      final portion = portionInput;
      if (portion == null) {
        return null;
      }
      return l10n.eatPageTotal(
        l10n.inventoryEatSheetAmountWithUnit(
          formatInventoryNutritionValue(portion.totalAmount),
          consumedUnitSymbol(l10n, portion.unit),
        ),
      );
    }
    final amount = enteredInventoryAmount;
    if (amount == null || amount < 1) {
      return null;
    }
    for (final marker in markers) {
      final label = marker.label;
      final size = marker.value.round();
      if (label != null && !marker.isAll && amount % size == 0) {
        return l10n.eatPagePortionMultiple('${amount ~/ size}', label);
      }
    }
    return null;
  }

  /// Unit the nutrition table is calculated in.
  String nutritionUnit(AppLocalizations l10n) {
    final unit = usesPortionMode
        ? portionUnit
        : calculator.fixedCalorieUnit ?? portionUnit;
    return consumedUnitSymbol(l10n, unit);
  }

  /// Text of the inedible part link.
  String inedibleSummary(AppLocalizations l10n) {
    if ((inedibleAmount ?? 0) <= 0) {
      return l10n.inventoryItemEatSheetInedibleAmountLabel;
    }
    return l10n.inventoryItemEatSheetInedibleAmountSummary(
      l10n.inventoryEatSheetAmountWithUnit(
        formatInventoryNutritionValue(inedibleAmount ?? 0),
        amountUnit(l10n),
      ),
    );
  }

  /// Error text of the amount field.
  String? amountError(AppLocalizations l10n) {
    if (usesPortionMode &&
        errors.contains(InventoryItemEatSheetError.invalidPortionCount)) {
      return l10n.caloriesPositiveNumberValidation;
    }
    final countsFromPortion = !usesPortionMode || portionInput != null;
    if (countsFromPortion &&
        errors.contains(InventoryItemEatSheetError.invalidInventoryAmount)) {
      return l10n.inventoryReceiptReviewInvalidNumber;
    }
    return null;
  }

  /// Error text of the piece weight field.
  String? portionAmountError(AppLocalizations l10n) {
    if (errors.contains(InventoryItemEatSheetError.invalidPortionAmount)) {
      return l10n.caloriesPositiveNumberValidation;
    }
    return null;
  }

  /// Error text of the inedible field.
  String? inedibleError(AppLocalizations l10n) {
    if (errors.contains(InventoryItemEatSheetError.invalidInedibleAmount)) {
      return l10n.caloriesNonNegativeNumberValidation;
    }
    if (errors.contains(InventoryItemEatSheetError.inedibleTooLarge)) {
      return l10n.inventoryItemEatSheetInedibleAmountError;
    }
    return null;
  }
}

/// Texts of the prepared meal eat page.
extension PreparedMealEatSheetTexts on PreparedMealEatSheetState {
  /// Unit after the amount.
  String amountUnit(AppLocalizations l10n) {
    return switch (mode) {
      PreparedMealEatAmountMode.portions => l10n.eatPagePortionsUnit,
      PreparedMealEatAmountMode.grams => l10n.inventoryUnitGram,
    };
  }

  /// Portions left, such as "3½ Port.".
  String stockLabel(AppLocalizations l10n) {
    return l10n.inventoryEatSheetAmountWithUnit(
      _portions(calculator.meal.remainingPortions),
      l10n.eatPagePortionsUnit,
    );
  }

  /// Text of the ruler mark at [index] with [value]. The first mark is
  /// everything left.
  String markLabel(AppLocalizations l10n, int index, num value) {
    if (index == 0) {
      return l10n.eatPageAll;
    }
    return switch (mode) {
      PreparedMealEatAmountMode.portions => _portions(value),
      PreparedMealEatAmountMode.grams => _grams(l10n, value),
    };
  }

  /// Note beside the amount: the same amount in the other unit.
  String? amountHint(AppLocalizations l10n) {
    final entered = amount;
    if (entered == null || !calculator.canUseGrams) {
      return null;
    }
    final other = calculator.convertAmount(
      entered,
      from: mode,
      to: mode == PreparedMealEatAmountMode.portions
          ? PreparedMealEatAmountMode.grams
          : PreparedMealEatAmountMode.portions,
    );
    if (other == null) {
      return null;
    }
    return l10n.eatPageApprox(
      mode == PreparedMealEatAmountMode.portions
          ? _grams(l10n, other)
          : l10n.inventoryEatSheetAmountWithUnit(
              _portions(other),
              l10n.eatPagePortionsUnit,
            ),
    );
  }

  /// Header of the nutrition table: the eaten portions.
  String portionsHeader(AppLocalizations l10n) {
    final portions = portionsOrOne;
    return l10n.inventoryEatSheetPortionsHeader(portions, _portions(portions));
  }

  String _portions(num value) {
    return formatQuickChipAmount(
      value,
      (number) => formatPreparedMealPortions(number, localeName: localeName),
    );
  }

  String _grams(AppLocalizations l10n, num grams) {
    return l10n.inventoryEatSheetAmountWithUnit(
      formatInventoryAmountValue(
        amount: grams.round(),
        unit: InventoryAmountUnit.gram,
      ),
      l10n.inventoryUnitGram,
    );
  }
}
