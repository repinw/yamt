import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/application/serving_suggestion_resolver.dart';
import 'package:yamt/features/inventory/domain/eat_nutrition.dart';
import 'package:yamt/features/inventory/domain/global_food_serving_suggestion.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_draft.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_state.dart';
import 'package:yamt/features/inventory/presentation/formatters/inventory_nutrition_format.dart';

/// Recomputes the ruler marks and nutrition of [state].
InventoryItemEatSheetState deriveInventoryItemEatSheetState(
  InventoryItemEatSheetState state,
  ServingSuggestionResolution resolution,
) {
  return state.copyWith(
    nutrition: () => _nutrition(state),
    markers: _markers(state, resolution),
    pieceSizes: _pieceSizes(state, resolution),
  );
}

/// Known weights of one piece: the sizes named in this sheet first, then
/// the learned and product ones. Each weight shows once, with a name when
/// one of its entries has one.
List<InventoryItemEatPortion> _pieceSizes(
  InventoryItemEatSheetState state,
  ServingSuggestionResolution resolution,
) {
  if (!state.usesPortionMode) {
    return const [];
  }
  final units = state.calculator.availablePortionUnits;
  final sizes = <InventoryItemEatPortion>[];
  void add(InventoryItemEatPortion size) {
    final index = sizes.indexWhere(
      (known) =>
          known.unit == size.unit &&
          buildServingSuggestionAmountKey(known.amount) ==
              buildServingSuggestionAmountKey(size.amount),
    );
    if (index < 0) {
      sizes.add(size);
    } else if (sizes[index].label == null && size.label != null) {
      sizes[index] = size;
    }
  }

  state.rememberedPortions.forEach(add);
  for (final suggestion in resolution.portionSuggestions) {
    if (suggestion.amount > 0 && units.contains(suggestion.unit)) {
      add(
        InventoryItemEatPortion(
          amount: suggestion.amount,
          unit: suggestion.unit,
          label: normalizePortionLabel(suggestion.portionLabel),
        ),
      );
    }
  }
  return sizes;
}

/// Named portions of a fixed-unit item: the ones named in this sheet first,
/// then the learned ones with a name.
List<InventoryItemEatPortion> namedPortions(
  InventoryItemEatSheetState state,
  ServingSuggestionResolution resolution,
) {
  final unit = state.calculator.fixedCalorieUnit;
  if (unit == null) {
    return const [];
  }
  return [
    ...state.rememberedPortions,
    for (final suggestion in resolution.portionSuggestions)
      if (suggestion.unit == unit &&
          normalizePortionLabel(suggestion.portionLabel) != null)
        InventoryItemEatPortion(
          amount: suggestion.amount,
          unit: unit,
          label: normalizePortionLabel(suggestion.portionLabel),
        ),
  ];
}

List<InventoryItemEatMarker> _markers(
  InventoryItemEatSheetState state,
  ServingSuggestionResolution resolution,
) {
  final hasOpenStock = state.calculator.hasOpenStock;
  if (state.usesPortionMode) {
    return [
      if (!hasOpenStock)
        InventoryItemEatMarker(value: state.amountMax, isAll: true),
    ];
  }
  final maxAmount = state.calculator.rulerMax;
  final amounts = <int>{};
  final candidates = [
    for (final portion in namedPortions(state, resolution))
      (amount: portion.amount.round(), label: portion.label),
    for (final serving in resolution.inventoryServingOptions)
      (amount: serving.value, label: null),
  ];
  return [
    for (final (:amount, :label) in candidates)
      if (amount >= 1 && amount < maxAmount && amounts.add(amount))
        InventoryItemEatMarker(value: amount.toDouble(), label: label),
    if (!hasOpenStock)
      InventoryItemEatMarker(value: maxAmount.toDouble(), isAll: true),
  ];
}

EatNutrition? _nutrition(InventoryItemEatSheetState state) {
  final nutrition = state.calculator.item.nutrition;
  if (nutrition == null || !nutrition.hasAnyNutritionValue) {
    return null;
  }
  final amount = state.calculator.resolvedNutritionAmount(
    usesPortionMode: state.usesPortionMode,
    portionCountText: state.portionCountText,
    portionAmountText: state.portionAmountText,
    portionUnit: state.portionUnit,
    inventoryAmountText: state.inventoryAmountText,
    inedibleAmountText: state.inedibleAmountText,
  );
  return amount == null
      ? EatNutrition.per100Only(nutrition)
      : EatNutrition.fromPer100(nutrition, amount);
}

/// Removes surrounding space and turns an empty [label] into null.
String? normalizePortionLabel(String? label) {
  final trimmed = label?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// Moves the inventory amount along with the portion input.
InventoryItemEatSheetState withPortionAmounts(
  InventoryItemEatSheetState state,
) {
  final amount = state.calculator.inventoryAmountFromPortionInput(
    usesPortionMode: state.usesPortionMode,
    countText: state.portionCountText,
    amountText: state.portionAmountText,
    unit: state.portionUnit,
  );
  if (amount == null) {
    return state;
  }
  return state.copyWith(
    inventoryAmountText: state.calculator.formatInventoryAmount(amount),
  );
}

/// Applies learned defaults the user has not overridden.
InventoryItemEatSheetState withLearnedDefaults(
  InventoryItemEatSheetState state,
  ServingSuggestionResolution resolution,
) {
  var next = state;
  final calculator = state.calculator;
  final portion = resolution.portionDefaultSuggestion;
  if (!state.didEditPortion && state.usesPortionMode && portion != null) {
    next = withPortionAmounts(
      next.copyWith(
        portionAmountText: formatInventoryNutritionValue(portion.amount),
        portionUnit: calculator.normalizePortionUnit(portion.unit),
        portionLabel: () => normalizePortionLabel(portion.portionLabel),
        portionCountText: next.portionCountText.trim().isEmpty
            ? '1'
            : next.portionCountText,
      ),
    );
  }
  final inventoryDefault = resolution.inventoryDefaultAmount;
  if (!state.didEditInventoryAmount && inventoryDefault != null) {
    next = next.copyWith(
      inventoryAmountText: calculator.formatInventoryAmount(inventoryDefault),
    );
  }
  return next;
}

/// Mark on the amount ruler.
@immutable
class InventoryItemEatMarker {
  /// Creates a mark at [value].
  const new({required this.value, this.label, this.isAll = false});

  /// Position in the unit of the amount field: inventory units, or pieces
  /// in portion mode.
  final double value;

  /// Name of the portion at this mark, or null for a plain amount.
  final String? label;

  /// Whether the mark stands for the whole stock.
  final bool isAll;
}
