import 'dart:math' as math;

import 'package:yamt/features/inventory/application/serving_suggestion_resolver.dart';

import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_options.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_state.dart';
import 'package:yamt/features/inventory/presentation/formatters/inventory_nutrition_format.dart';

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
    // The same amount typed again still is the counted portion.
    countedPortion: () =>
        state.calculator.parseEatenAmount(text) == state.enteredAmount
        ? state.countedPortion
        : null,
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
  final picked = withAmountText(state, formatMarkerAmount(state, marker));
  if (state.usesPortionMode || !marker.counts || marker.value < 1) {
    return picked;
  }
  return picked.copyWith(countedPortion: () => marker);
}

/// Applies learned defaults the user has not overridden. Outside portion
/// mode the page starts with what was eaten last time, else one of the
/// smallest named portion, else one package or what is left of it.
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
  if (state.didEditInventoryAmount || state.usesPortionMode) {
    return next;
  }
  final start = _startPortion(state, resolution);
  if (start != null) {
    return next.copyWith(
      inventoryAmountText: formatEatenAmount(next, start.value),
      countedPortion: () => start.label == null ? null : start,
    );
  }
  final inventoryDefault = resolution.inventoryDefaultAmount;
  return inventoryDefault == null
      ? next
      : next.copyWith(
          inventoryAmountText: calculator.formatInventoryAmount(
            inventoryDefault,
          ),
        );
}

InventoryItemEatMarker? _startPortion(
  InventoryItemEatSheetState state,
  ServingSuggestionResolution resolution,
) {
  final calculator = state.calculator;
  if (!calculator.takesDecimalWeight || calculator.maxAmount < 1) {
    return null;
  }
  // More than is left starts with the rest, which is no longer the portion.
  InventoryItemEatMarker mark(double amount, String? label) {
    final rest = calculator.maxAmount.toDouble();
    return amount > rest
        ? InventoryItemEatMarker(value: rest)
        : InventoryItemEatMarker(
            value: calculator.roundEatenAmount(amount),
            label: normalizePortionLabel(label),
          );
  }

  final recent = resolution.recentSuggestion;
  if (recent != null && recent.unit == calculator.fixedCalorieUnit) {
    return mark(recent.amount, recent.portionLabel);
  }
  final named = namedPortions(state, resolution);
  if (named.isNotEmpty) {
    final smallest = named.reduce((a, b) => b.amount < a.amount ? b : a);
    return mark(smallest.amount, smallest.label);
  }
  final package = packageSizeOf(calculator);
  return package == null ? null : mark(package.toDouble(), null);
}

/// [state] with [value] from the ruler. With a named portion counted, the
/// amount snaps to half portions and stays counted; else it is free.
InventoryItemEatSheetState withRulerAmount(
  InventoryItemEatSheetState state,
  double value,
) {
  final counted = state.countedPortion;
  if (state.usesPortionMode) {
    return withAmountText(state, formatPieceCount(state, value));
  }
  if (counted == null ||
      counted.label == null ||
      counted.value < 1 ||
      !state.calculator.takesDecimalWeight) {
    return withAmountText(state, _format(state, value.round()));
  }
  final half = counted.value / 2;
  final halves = math.min(
    math.max(1, (value / half).round()),
    (state.calculator.maxAmount / half).floor(),
  );
  return withAmountText(
    state,
    formatEatenAmount(state, halves * half),
  ).copyWith(countedPortion: () => counted);
}

/// [state] with one counted portion more, or one less when [up] is false,
/// or null when no portion is counted or the stock has no room. The amount
/// never drops below zero.
InventoryItemEatSheetState? withSteppedPortions(
  InventoryItemEatSheetState state, {
  required bool up,
}) {
  final marker = state.countedPortion;
  if (marker == null || state.portionCount == null) {
    return null;
  }
  final size = marker.value;
  final count = state.enteredAmount / size;
  final next = up
      ? ((count + 0.001).floor() + 1) * size
      : math.max(0, (count - 0.001).ceil() - 1) * size;
  if (next > state.calculator.maxAmount) {
    return null;
  }
  return withAmountText(
    state,
    formatEatenAmount(state, next),
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
  final amount = state.enteredAmount;
  final next = up
      ? ((amount + 0.001) / package).floor() + 1
      : math.max(0, ((amount - 0.001) / package).ceil() - 1);
  return withAmountText(state, _format(state, next * package));
}

String _format(InventoryItemEatSheetState state, int amount) {
  return state.calculator.formatInventoryAmount(amount);
}

/// [count] pieces as the stock keeps them: to a thousandth of a piece for a
/// stock that keeps parts, such as "1.25", else whole, such as "2". A count
/// over the stock is all of it, so rounding never takes more than is left.
String formatPieceCount(InventoryItemEatSheetState state, double count) {
  final calculator = state.calculator;
  final amount = math.min(
    count * calculator.inventoryAmountScale,
    calculator.maxAmount.toDouble(),
  );
  return _format(state, amount.round());
}

/// The amount of [marker] as the amount field shows it: in pieces in
/// portion mode, else as [formatEatenAmount] does.
String formatMarkerAmount(
  InventoryItemEatSheetState state,
  InventoryItemEatMarker marker,
) => state.usesPortionMode
    ? formatPieceCount(state, marker.value)
    : formatEatenAmount(state, marker.value);

/// [amount] as the amount field shows it: grams and milliliters with one
/// decimal, other units in stock units.
String formatEatenAmount(InventoryItemEatSheetState state, double amount) {
  if (state.calculator.takesDecimalWeight) {
    return formatInventoryNutritionValue(amount);
  }
  return _format(state, amount.round());
}

/// Whether the inedible part is open or holds an entry. A page that offers
/// it from a menu shows it only then.
bool hasInedibleInput(InventoryItemEatSheetState state) =>
    state.isInedibleExpanded || state.inedibleAmountText.trim().isNotEmpty;
