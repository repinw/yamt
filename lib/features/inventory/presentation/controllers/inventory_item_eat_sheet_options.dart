import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/application/serving_suggestion_resolver.dart';
import 'package:yamt/features/inventory/domain/eat_nutrition.dart';
import 'package:yamt/features/inventory/domain/global_food_serving_suggestion.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_calculator.dart';
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

/// Named portions of a fixed-unit item, in the order of the chips: the
/// last and the product serving when they have a name, the ones named in
/// this sheet, then the other learned ones. The hint and the logged entry
/// both take the first that fits, so they name the same portion.
List<InventoryItemEatPortion> namedPortions(
  InventoryItemEatSheetState state,
  ServingSuggestionResolution resolution,
) {
  final unit = state.calculator.fixedCalorieUnit;
  if (unit == null) {
    return const [];
  }
  List<InventoryItemEatPortion> named(List<PortionSuggestion> suggestions) => [
    for (final suggestion in suggestions)
      if (suggestion.unit == unit &&
          normalizePortionLabel(suggestion.portionLabel) != null)
        InventoryItemEatPortion(
          amount: suggestion.amount,
          unit: unit,
          label: normalizePortionLabel(suggestion.portionLabel),
        ),
  ];
  final first = [?resolution.recentSuggestion, ?resolution.productServing];
  return [
    ...named(first),
    ...state.rememberedPortions,
    ...named(resolution.portionSuggestions),
  ];
}

/// The chips under the ruler, in this order: what was eaten last time, the
/// product's serving, named portions, other learned amounts, a quarter and
/// a half package, and everything. Each amount shows once.
List<InventoryItemEatMarker> _markers(
  InventoryItemEatSheetState state,
  ServingSuggestionResolution resolution,
) {
  final calculator = state.calculator;
  final hasOpenStock = calculator.hasOpenStock;
  if (state.usesPortionMode) {
    return [
      if (!hasOpenStock)
        InventoryItemEatMarker(value: state.amountMax, isAll: true),
    ];
  }
  final unit = calculator.fixedCalorieUnit;
  final package = calculator.packageAmount ?? _packageSize(calculator);
  final named = namedPortions(state, resolution);
  // An unnamed amount the user also named shows under that name.
  final namedAmounts = {
    for (final portion in named) calculator.roundEatenAmount(portion.amount),
  };
  InventoryItemEatMarker? suggested(
    PortionSuggestion? suggestion,
    EatMarkKind kind,
  ) {
    if (suggestion == null ||
        suggestion.unit != unit ||
        !calculator.takesDecimalWeight) {
      return null;
    }
    final label = normalizePortionLabel(suggestion.portionLabel);
    if (label == null &&
        namedAmounts.contains(calculator.roundEatenAmount(suggestion.amount))) {
      return null;
    }
    return InventoryItemEatMarker(
      value: suggestion.amount,
      label: label,
      kind: label == null ? kind : EatMarkKind.amount,
    );
  }

  final maxAmount = calculator.rulerMax;
  final amounts = <double>{};
  final candidates = [
    ?suggested(resolution.recentSuggestion, EatMarkKind.recent),
    ?suggested(resolution.productServing, EatMarkKind.serving),
    for (final portion in named)
      InventoryItemEatMarker(value: portion.amount, label: portion.label),
    for (final serving in resolution.inventoryServingOptions)
      InventoryItemEatMarker(value: serving.value.toDouble()),
    if (package != null && calculator.takesDecimalWeight) ...[
      InventoryItemEatMarker(value: package / 4, kind: EatMarkKind.quarter),
      InventoryItemEatMarker(value: package / 2, kind: EatMarkKind.half),
    ],
  ];
  return [
    for (final candidate in candidates)
      if (calculator.roundEatenAmount(candidate.value) case final amount
          when amount >= 1 && amount < maxAmount && amounts.add(amount))
        InventoryItemEatMarker(
          value: amount,
          label: candidate.label,
          kind: candidate.kind,
        ),
    if (!hasOpenStock)
      InventoryItemEatMarker(value: maxAmount.toDouble(), isAll: true),
  ];
}

/// Size of one package from the product's package weight, in the stock
/// unit, or null without one.
int? _packageSize(InventoryItemEatCalculator calculator) {
  final parsed = const InventoryAmountParser().tryParse(
    rawWeight: calculator.item.weight,
    quantity: 1,
  );
  return parsed?.unit == calculator.inventoryAmountUnit &&
          calculator.inventoryAmountScale == 1
      ? parsed!.amount
      : null;
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
  const new({
    required this.value,
    this.label,
    this.isAll = false,
    this.kind = EatMarkKind.amount,
  });

  /// Position in the unit of the amount field: inventory units, or pieces
  /// in portion mode.
  final double value;

  /// Name of the portion at this mark, or null for a plain amount.
  final String? label;

  /// Whether the mark stands for the whole stock.
  final bool isAll;

  /// Where the amount of the mark comes from, for its text.
  final EatMarkKind kind;

  /// Whether picking the mark counts it as a portion.
  bool get counts => !isAll && kind == EatMarkKind.amount;
}

/// Where the amount of a ruler mark comes from.
enum EatMarkKind {
  /// A plain or named amount.
  amount,

  /// What the user ate of the food last time.
  recent,

  /// The serving the product data names, without a name of its own.
  serving,

  /// A quarter package.
  quarter,

  /// Half a package.
  half,
}
