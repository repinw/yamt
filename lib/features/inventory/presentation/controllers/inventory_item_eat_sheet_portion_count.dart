import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_amounts.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_options.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_state.dart';

/// Whether the page counts portions of a weight: grams or milliliters
/// outside portion mode, shown as count × weight of one portion.
bool countsWeightPortions(InventoryItemEatSheetState state) =>
    !state.usesPortionMode && state.calculator.takesDecimalWeight;

/// Weight of one portion: the counted one, or else the whole amount. A
/// cleared amount shows an empty field, also with a counted portion.
String portionWeightText(InventoryItemEatSheetState state) {
  final counted = state.countedPortion;
  return counted == null || state.inventoryAmountText.trim().isEmpty
      ? state.inventoryAmountText
      : formatEatenAmount(state, counted.value);
}

/// [state] with [count] of the current portion: the counted one, or else
/// the entered amount as one portion without a name.
InventoryItemEatSheetState withCount(
  InventoryItemEatSheetState state,
  double count,
) {
  final portion =
      state.countedPortion ??
      InventoryItemEatMarker(value: state.enteredAmount);
  if (count <= 0 || portion.value <= 0) {
    // A new state moves the wheel back to the count it showed.
    return state.copyWith();
  }
  return withAmountText(
    state,
    formatEatenAmount(state, count * portion.value),
  ).copyWith(countedPortion: () => portion, portionCountText: '$count');
}

/// The count of the counted portion: as last set on the wheel while it
/// still gives the amount, else worked out from the amount; 1 without one.
double eatenCount(InventoryItemEatSheetState state) {
  final counted = state.countedPortion;
  final set = parsePositiveDecimalInput(state.portionCountText);
  if (counted != null &&
      set != null &&
      (state.enteredAmount == 0 ||
          (set * counted.value - state.enteredAmount).abs() <= 0.05 + 0.001)) {
    return set;
  }
  return state.portionCount ?? 1;
}

/// [state] with [text] as the weight of one portion. The count stays; a
/// name stays only while the weight is a named portion's own and comes back
/// with it, so a slice is never saved with another weight. Without a counted
/// portion, [text] is the whole amount.
InventoryItemEatSheetState withPortionWeightText(
  InventoryItemEatSheetState state,
  String text,
) {
  final counted = state.countedPortion;
  if (counted == null) {
    return withAmountText(state, text);
  }
  final weight = state.calculator.parseExactWeightAmount(text);
  if (weight == null || weight <= 0) {
    // An empty field is no amount, but the portion and count stay for the
    // weight typed next.
    return withAmountText(state, '').copyWith(
      countedPortion: () => counted,
      portionCountText: '${eatenCount(state)}',
    );
  }
  final count = eatenCount(state);
  final label = [counted, ...state.markers]
      .where((marker) => marker.label != null && marker.value == weight)
      .firstOrNull
      ?.label;
  return withAmountText(
    state,
    formatEatenAmount(state, count * weight),
  ).copyWith(
    countedPortion: () => InventoryItemEatMarker(value: weight, label: label),
    portionCountText: '$count',
  );
}

/// Weight of one portion: the counted one, or else the whole amount. This
/// is what "remember as portion" names.
double portionWeight(InventoryItemEatSheetState state) {
  return state.countedPortion?.value ?? state.enteredAmount;
}

/// Most portions the stock holds, for the count wheel; 1 without a weight.
double wheelMaxCount(InventoryItemEatSheetState state) {
  final weight = portionWeight(state);
  return weight <= 0 ? 1 : state.calculator.maxAmount / weight;
}

/// [state] with the entered amount named [label] as a portion, or the
/// entered piece weight as a piece size in portion mode; null when there
/// is nothing to name.
InventoryItemEatSheetState? withRememberedPortion(
  InventoryItemEatSheetState state,
  String? label,
) {
  final name = normalizePortionLabel(label);
  if (state.usesPortionMode) {
    final weight = parsePositiveDecimalInput(state.portionAmountText);
    if (weight == null) {
      return null;
    }
    return state.copyWith(
      portionLabel: () => name,
      rememberedPortions: [
        ...state.rememberedPortions,
        InventoryItemEatPortion(
          amount: weight,
          unit: state.portionUnit,
          label: name,
        ),
      ],
    );
  }
  final amount = portionWeight(state);
  final unit = state.calculator.fixedCalorieUnit;
  if (amount < 1 || unit == null) {
    return null;
  }
  // The count stays, now of the named portion.
  return state.copyWith(
    countedPortion: () => InventoryItemEatMarker(value: amount, label: name),
    portionCountText: '${eatenCount(state)}',
    rememberedPortions: [
      ...state.rememberedPortions,
      InventoryItemEatPortion(amount: amount, unit: unit, label: name),
    ],
  );
}
