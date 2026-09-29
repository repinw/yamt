import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// One ingredient row of a meal cooked without a recipe.
@immutable
class FreeCookingRow {
  /// Creates a row for [text] with its parsed [requirement] and the Vorrat
  /// item [stockItem] that supplies it.
  const new({required this.text, this.requirement, this.stockItem});

  /// The row as spoken or typed, for example "500 g Hähnchen".
  final String text;

  /// The amount, unit, and food read from [text], or `null` when the row has
  /// no amount ("Salz").
  final TemplateIngredientRequirement? requirement;

  /// The best Vorrat match, or `null` when the Vorrat does not hold the food.
  final InventoryItem? stockItem;

  /// Whether the Vorrat holds the food.
  bool get isInStock => stockItem != null;

  /// The food name without the amount.
  String get foodName => requirement?.name ?? text;

  /// The amount left in [stockItem], in grams, milliliters, or pieces.
  ({int amount, InventoryAmountUnit unit})? get stockAmount {
    final item = stockItem;
    if (item == null) {
      return null;
    }
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
}
