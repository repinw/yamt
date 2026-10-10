import 'dart:math' show max;

import 'package:meta/meta.dart';
import 'package:yamt/features/cookbook_new/domain/free_cooking_row.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// One ingredient of a recipe, sized for the chosen portions.
@immutable
class RecipeIngredientLine {
  /// Creates the line for the saved [ingredient].
  const new({
    required this.ingredient,
    required this.row,
    required this.isIgnored,
    required this.candidates,
    required this.label,
    this.items = const <InventoryItem>[],
    this.shortfall,
    this.stockedLabel,
    this.restLabel,
  });

  /// The ingredient as the recipe saves it, for the original portions.
  final String ingredient;

  /// The ingredient for the chosen portions with the first Vorrat item that
  /// supplies it.
  final FreeCookingRow row;

  /// Whether the recipe ignores the ingredient, like salt or water.
  final bool isIgnored;

  /// The Vorrat items the cook can pick for it, best match first.
  final List<InventoryItem> candidates;

  /// The Vorrat items that supply it this time, in the order they are used.
  final List<InventoryItem> items;

  /// What [items] cannot supply, or `null` when they supply all of it.
  final ({int amount, InventoryAmountUnit unit})? shortfall;

  /// The ingredient for the chosen portions as an open row of a meal names
  /// it, such as "600 g Karotten".
  final String label;

  /// The part that [items] supply, such as "400 g Karotten", when they lack
  /// some of it.
  final String? stockedLabel;

  /// The part that [items] lack, such as "200 g Karotten".
  final String? restLabel;

  /// Whether the Vorrat lacks the ingredient.
  bool get isMissing => !isIgnored && items.isEmpty;

  /// Whether the Vorrat has only part of the ingredient.
  bool get isPartial => !isIgnored && items.isNotEmpty && shortfall != null;

  /// What the cook is short of, as the shopping list names it: the missing
  /// part of a partly stocked ingredient, else the whole ingredient.
  String get shoppingLabel => restLabel ?? label;
}

/// A recipe as the recipe page shows it.
@immutable
class RecipeView {
  /// Creates the view of [recipe] for [portions].
  const new({
    required this.recipe,
    required this.portions,
    required this.lines,
  });

  /// The saved recipe.
  final PreparedMeal recipe;

  /// The portions to cook.
  final int portions;

  /// The ingredients for [portions].
  final List<RecipeIngredientLine> lines;

  /// The portions the recipe is written for; a recipe needs at least one to
  /// scale from.
  int get basePortions => max(1, recipe.totalPortions);

  /// The ingredients that count, without the ignored ones.
  Iterable<RecipeIngredientLine> get activeLines =>
      lines.where((line) => !line.isIgnored);

  /// How many of [activeLines] the Vorrat supplies.
  int get inStockCount =>
      activeLines.where((line) => line.row.isInStock).length;

  /// The Vorrat items to use up, by the saved ingredient.
  Map<String, List<String>> get assignments => {
    for (final line in activeLines)
      if (line.items.isNotEmpty)
        line.ingredient: [for (final item in line.items) item.id],
  };
}
