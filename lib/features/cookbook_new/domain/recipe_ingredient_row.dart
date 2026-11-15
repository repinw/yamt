import 'dart:math' show max;

import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// One ingredient row of a recipe on the recipe page.
@immutable
class RecipeIngredientRow {
  /// Creates a row for [text] with its parsed [requirement] and the Vorrat
  /// items [stockItems] that supply it.
  const new({
    required this.text,
    this.requirement,
    this.stockItems = const <InventoryItem>[],
  });

  /// The ingredient as written, for example "500 g Hähnchen".
  final String text;

  /// The amount, unit, and food read from [text], or `null` when the row has
  /// no amount ("Salz").
  final TemplateIngredientRequirement? requirement;

  /// The Vorrat items the cook took for the line in the cook run; empty
  /// without a run or a take.
  final List<InventoryItem> stockItems;

  /// The food name without the amount.
  String get foodName => requirement?.name ?? text;

  /// The amount left in [stockItems] for this cooking in the unit of the
  /// first, in grams, milliliters, or pieces, as the Kochmodus says what is
  /// there: each item's stock less what other cook runs and the run's other
  /// lines hold of it ([held], by item id, in the item's unit and scale),
  /// added up over the items kept like the first, where grams and
  /// milliliters count 1:1.
  ({int amount, InventoryAmountUnit unit})? stockLeft(Map<String, int> held) {
    final amounts = [
      for (final item in stockItems) _amountLeft(item, held[item.id] ?? 0),
    ];
    final first = amounts.firstOrNull;
    if (first == null) {
      return null;
    }
    return (
      amount: amounts
          .where((left) => _keptAlike(left.unit, first.unit))
          .fold(0, (sum, left) => sum + left.amount),
      unit: first.unit,
    );
  }

  static bool _keptAlike(InventoryAmountUnit a, InventoryAmountUnit b) =>
      a == b ||
      (a != InventoryAmountUnit.piece && b != InventoryAmountUnit.piece);

  static ({int amount, InventoryAmountUnit unit}) _amountLeft(
    InventoryItem item,
    int held,
  ) {
    final left = max(0, item.availableAmount - held);
    final unit = item.amountUnit;
    if (!item.usesAmountProgress || unit == null) {
      return (amount: left, unit: InventoryAmountUnit.piece);
    }
    if (unit == InventoryAmountUnit.piece) {
      return (amount: (left / inventoryPieceAmountScale).floor(), unit: unit);
    }
    return (amount: left, unit: unit);
  }
}
