import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// One ingredient row of a meal cooked without a recipe.
@immutable
class FreeCookingRow {
  /// Creates a row for [text] with its parsed [requirement], the Vorrat
  /// items [stockItems] that supply it, and the [candidates] to pick from.
  const new({
    required this.text,
    this.requirement,
    this.stockItems = const <InventoryItem>[],
    this.candidates = const <InventoryItem>[],
  });

  /// The row as spoken or typed, for example "500 g Hähnchen".
  final String text;

  /// The amount, unit, and food read from [text], or `null` when the row has
  /// no amount ("Salz").
  final TemplateIngredientRequirement? requirement;

  /// The best Vorrat match or the cook's picks, in the order cooking takes
  /// from them; empty when the Vorrat does not supply the food.
  final List<InventoryItem> stockItems;

  /// The first of [stockItems], or `null`.
  InventoryItem? get stockItem => stockItems.firstOrNull;

  /// The Vorrat items the cook can pick for the row, best first.
  final List<InventoryItem> candidates;

  /// Whether the Vorrat holds the food.
  bool get isInStock => stockItem != null;

  /// The food name without the amount.
  String get foodName => requirement?.name ?? text;

  /// The amount left in [stockItems] that count in the unit of the first,
  /// in grams, milliliters, or pieces.
  ({int amount, InventoryAmountUnit unit})? get stockAmount {
    final amounts = stockItems.map(_amountLeft);
    final first = amounts.firstOrNull;
    if (first == null) {
      return null;
    }
    return (
      amount: amounts
          .where((left) => left.unit == first.unit)
          .fold(0, (sum, left) => sum + left.amount),
      unit: first.unit,
    );
  }

  static ({int amount, InventoryAmountUnit unit}) _amountLeft(
    InventoryItem item,
  ) {
    final unit = item.amountUnit;
    if (!item.usesAmountProgress || unit == null) {
      return (amount: item.quantity, unit: InventoryAmountUnit.piece);
    }
    if (unit == InventoryAmountUnit.piece) {
      return (
        amount: (item.currentAmount / inventoryPieceAmountScale).floor(),
        unit: unit,
      );
    }
    return (amount: item.currentAmount, unit: unit);
  }
}

/// Counts over the rows of a free-cooking meal.
extension FreeCookingRowCounts on List<FreeCookingRow> {
  /// Number of rows that the Vorrat supplies.
  int get inStockCount => where((row) => row.isInStock).length;

  /// A name for the dish from its first three foods, for example
  /// "Reis, Hähnchen, Brokkoli", or `null` without rows. Rows with an
  /// amount come before seasonings, and a row the Vorrat supplies takes
  /// the item's name.
  String? get suggestedName {
    final foods = <String, String>{};
    for (final row in [
      ...where((row) => row.requirement != null),
      ...where((row) => row.requirement == null),
    ]) {
      final food = (row.stockItem?.name ?? row.foodName).trim();
      if (food.isNotEmpty) {
        foods.putIfAbsent(food.toLowerCase(), () => food);
      }
    }
    return foods.isEmpty ? null : foods.values.take(3).join(', ');
  }
}
