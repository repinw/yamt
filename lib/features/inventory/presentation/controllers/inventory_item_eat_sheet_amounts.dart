import 'dart:math' as math;

import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_options.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_state.dart';

/// [state] with [text] in the amount field: a piece count in portion mode,
/// else the inventory amount. A typed amount stops counting a portion.
InventoryItemEatSheetState withAmountText(
  InventoryItemEatSheetState state,
  String text,
) {
  if (state.usesPortionMode) {
    return withPortionAmounts(
      state.copyWith(
        portionCountText: text,
        didEditPortion: true,
        errors: state.errors.difference(const {
          InventoryItemEatSheetError.invalidPortionCount,
          InventoryItemEatSheetError.invalidInventoryAmount,
        }),
      ),
    );
  }
  return state.copyWith(
    inventoryAmountText: text,
    didEditInventoryAmount: true,
    countedPortion: () => null,
    errors: state.errors.difference(const {
      InventoryItemEatSheetError.invalidInventoryAmount,
    }),
  );
}

/// [state] with the amount of [marker]. A portion mark is counted, so the
/// portion count can add more of it.
InventoryItemEatSheetState withMarker(
  InventoryItemEatSheetState state,
  InventoryItemEatMarker marker,
) {
  final picked = withAmountText(state, _format(state, marker.value.round()));
  if (state.usesPortionMode || marker.isAll || marker.value < 1) {
    return picked;
  }
  return picked.copyWith(countedPortion: () => marker);
}

/// [state] with one counted portion more, or one less when [up] is false,
/// or null when no portion is counted or the stock has no room. The amount
/// never drops below zero.
InventoryItemEatSheetState? withSteppedPortions(
  InventoryItemEatSheetState state, {
  required bool up,
}) {
  final marker = state.countedPortion;
  final count = state.portionCount;
  if (marker == null || count == null) {
    return null;
  }
  final size = marker.value.round();
  final amount = state.enteredInventoryAmount ?? 0;
  final next = up
      ? (count + 1) * size
      : math.max(0, (amount + size - 1) ~/ size - 1) * size;
  if (next > state.calculator.maxAmount) {
    return null;
  }
  return withAmountText(
    state,
    _format(state, next),
  ).copyWith(countedPortion: () => marker);
}

/// [state] moved to the next whole package up, or down when [up] is false,
/// or null when the item has no package to count. The amount never drops
/// below zero.
InventoryItemEatSheetState? withSteppedPackages(
  InventoryItemEatSheetState state, {
  required bool up,
}) {
  final package = state.calculator.packageAmount;
  if (package == null) {
    return null;
  }
  final amount = state.enteredInventoryAmount ?? 0;
  final packages = up
      ? amount ~/ package + 1
      : math.max(0, (amount + package - 1) ~/ package - 1);
  return withAmountText(state, _format(state, packages * package));
}

String _format(InventoryItemEatSheetState state, int amount) {
  return state.calculator.formatInventoryAmount(amount);
}
