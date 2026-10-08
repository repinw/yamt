import 'package:intl/intl.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_amounts.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_options.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_state.dart';
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

/// The snack bar after a plan was saved for [day]: "Für heute geplant",
/// "Für morgen geplant", or the date.
String planSavedMessage(
  AppLocalizations l10n, {
  required DateTime day,
  required DateTime today,
}) {
  final days = diaryDaysBetween(dateOnly(today), dateOnly(day));
  return l10n.diaryPlanSavedFor(switch (days) {
    0 => l10n.diaryPlanSavedToday,
    1 => l10n.diaryPlanSavedTomorrow,
    _ => DateFormat.MMMEd(l10n.localeName).format(day),
  });
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
      formatEatenAmount(this, enteredAmount),
      amountUnit(l10n),
    );
  }

  /// Text of a ruler mark.
  String markLabel(AppLocalizations l10n, InventoryItemEatMarker marker) {
    final amount = l10n.inventoryEatSheetAmountWithUnit(
      formatEatenAmount(this, marker.value),
      amountUnit(l10n),
    );
    final label = marker.isAll ? l10n.eatPageAll : _markName(l10n, marker);
    return label == null ? amount : l10n.eatPageMark(label, amount);
  }

  String? _markName(AppLocalizations l10n, InventoryItemEatMarker marker) {
    return marker.label ??
        switch (marker.kind) {
          EatMarkKind.amount => null,
          EatMarkKind.recent => l10n.eatPageRecentMark,
          EatMarkKind.serving => l10n.eatPageServingMark,
          EatMarkKind.quarter => l10n.eatPageQuarterMark,
          EatMarkKind.half => l10n.eatPageHalfMark,
        };
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
    final amount = enteredAmount;
    if (amount < 1) {
      return null;
    }
    if ((countedPortion?.label, portionCount) case (final label?, final count?)
        when countedPortion!.counts) {
      return l10n.eatPagePortionMultiple(formatEatCount(l10n, count), label);
    }
    // The counted portion, then named portions: the entry is logged as one
    // of them.
    for (final marker in [
      ?countedPortion,
      ...markers.where((marker) => marker.label != null),
      ...markers.where((marker) => marker.label == null),
    ]) {
      final label = _markName(l10n, marker);
      final count = (amount / marker.value).round();
      if (label != null &&
          marker.counts &&
          (amount - count * marker.value).abs() < 0.001) {
        return l10n.eatPagePortionMultiple('$count', label);
      }
    }
    return null;
  }

  /// Unit the nutrition table is calculated in.
  String nutritionUnit(AppLocalizations l10n) {
    return consumedUnitSymbol(l10n, nutritionConsumedUnit);
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

/// [count] of portions as the eat page shows it, such as "2" or "1,5".
String formatEatCount(AppLocalizations l10n, num count) {
  return (NumberFormat.decimalPattern(
    l10n.localeName,
  )..maximumFractionDigits = 2).format(count);
}
