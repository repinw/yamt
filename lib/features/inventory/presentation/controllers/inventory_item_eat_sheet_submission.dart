import 'package:yamt/features/inventory/domain/inventory_item_eat_draft.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_portion_count.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_state.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_eat_sheet_result.dart';

/// Result of pressing a confirm button in the item eat sheet.
sealed class InventoryItemEatSubmitOutcome {
  const new();
}

/// The input is valid; the sheet closes with [result].
final class InventoryItemEatSubmitted extends InventoryItemEatSubmitOutcome {
  /// Creates the submitted outcome.
  const new(this.result);

  /// Result to close the sheet with.
  final InventoryItemEatSheetResult result;
}

/// The input has errors, which the state now shows.
final class InventoryItemEatRejected extends InventoryItemEatSubmitOutcome {
  /// Creates the rejected outcome.
  const new();
}

/// Validates the input of [state].
InventoryItemEatSubmissionDraft buildInventoryItemEatDraft(
  InventoryItemEatSheetState state,
) {
  return state.calculator.buildSubmissionDraft(
    usesPortionMode: state.usesPortionMode,
    inventoryAmountText: state.inventoryAmountText,
    portionCountText: state.portionCountText,
    portionAmountText: state.portionAmountText,
    portionUnit: state.portionUnit,
    inedibleAmountText: state.inedibleAmountText,
  );
}

/// Shows the errors of an invalid [draft].
InventoryItemEatSheetState applyInventoryItemEatDraftErrors(
  InventoryItemEatSheetState state,
  InventoryItemEatSubmissionDraft draft,
) {
  final inedibleError =
      draft.hasInvalidInedibleAmount || draft.hasTooLargeInedibleAmount;
  return state.copyWith(
    errors: {
      ...state.errors,
      if (draft.hasInvalidInventoryAmount)
        InventoryItemEatSheetError.invalidInventoryAmount,
      if (draft.hasInvalidInedibleAmount)
        InventoryItemEatSheetError.invalidInedibleAmount
      else if (draft.hasTooLargeInedibleAmount)
        InventoryItemEatSheetError.inedibleTooLarge,
      if (draft.hasInvalidPortionCount)
        InventoryItemEatSheetError.invalidPortionCount,
      if (draft.hasInvalidPortionAmount)
        InventoryItemEatSheetError.invalidPortionAmount,
    },
    isInedibleExpanded: inedibleError ? true : null,
  );
}

/// Builds the eat request for a validated [draft].
///
/// Outside portion mode, an amount that is a whole multiple of one of
/// [namedPortions] is logged as that many portions, so the portion name is
/// learned with the food. A counted named portion is logged with its count,
/// whole or not; a counted portion without a name as the plain amount.
InventoryItemEatRequest buildInventoryItemEatRequest(
  InventoryItemEatSheetState state,
  InventoryItemEatSubmissionDraft draft, {
  List<InventoryItemEatPortion> namedPortions = const [],
  bool isPlan = false,
}) {
  final calculator = state.calculator;
  final manual = calculator.requiresManualCaloriePortion;
  final fixedAmount = draft.fixedUnitCalorieAmount;
  final portionMode = state.usesPortionMode;
  if (!portionMode && !manual) {
    final amount = draft.inventoryAmount!;
    final exactAmount =
        calculator.parseEatenAmount(state.inventoryAmountText) ??
        amount.toDouble();
    // A counted named portion is logged with any count, such as 1.5.
    if ((state.countedPortion, calculator.fixedCalorieUnit)
        case (final counted?, final unit?)
        when counted.counts && counted.label != null && counted.value >= 1) {
      return InventoryItemEatRequest(
        inventoryAmount: amount,
        loggedAt: state.loggedAt,
        mealType: state.mealType,
        calorieAmount: fixedAmount,
        calorieUnit: fixedAmount == null ? null : calculator.fixedCalorieUnit,
        portionBaseAmount: counted.value,
        portionBaseUnit: unit,
        portionCount: eatenCount(state),
        portionLabel: counted.label,
        isPlan: isPlan,
      );
    }
    // A portion counted without a name is logged as the plain amount, not
    // as another portion the sum happens to be a multiple of.
    for (final portion
        in state.countedPortion == null
            ? namedPortions
            : const <InventoryItemEatPortion>[]) {
      final count = exactAmount / portion.amount;
      if (count >= 1 && calculator.isWholeNumber(count)) {
        return InventoryItemEatRequest(
          inventoryAmount: amount,
          loggedAt: state.loggedAt,
          mealType: state.mealType,
          calorieAmount: fixedAmount,
          calorieUnit: fixedAmount == null ? null : calculator.fixedCalorieUnit,
          portionBaseAmount: portion.amount,
          portionBaseUnit: portion.unit,
          portionCount: count.roundToDouble(),
          portionLabel: portion.label,
          isPlan: isPlan,
        );
      }
    }
  }
  return InventoryItemEatRequest(
    inventoryAmount: draft.inventoryAmount!,
    loggedAt: state.loggedAt,
    mealType: state.mealType,
    calorieAmount: manual ? draft.portionTotalAmount : fixedAmount,
    calorieUnit: manual
        ? state.portionUnit
        : fixedAmount == null
        ? null
        : calculator.fixedCalorieUnit,
    portionBaseAmount: portionMode ? draft.portionBaseAmount : null,
    portionBaseUnit: portionMode ? state.portionUnit : null,
    portionCount: portionMode ? draft.portionCount : null,
    portionLabel: portionMode ? state.portionLabel : null,
    isPlan: isPlan,
  );
}
