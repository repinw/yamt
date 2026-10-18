import 'dart:math' show max;

import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

/// The Vorlage [vorlage] as a recipe: one ingredient per food, with the
/// Vorrat items it was combined from, so the page sizes and cooks it like a
/// recipe. Packs of the same food count as one ingredient.
PreparedMeal vorlageAsRecipe(
  PreparedMeal vorlage,
  TemplateIngredientParser parser,
) {
  final amounts = <(String, String), double>{};
  final itemIds = <(String, String), List<String>>{};
  for (final component in vorlage.components) {
    // Pieces go without a unit, as recipes count them ("2 Eier"), and
    // without a pack size in the name, which the parser would read as the
    // amount ("2 Mozzarella", not "2 Mozzarella 125 g").
    final isPiece = component.usedUnit == InventoryAmountUnit.piece;
    final unit = isPiece ? '' : ' ${component.usedUnit.code}';
    final name = isPiece
        ? parser
                  .parseRequirement(
                    ingredient: component.name,
                    selectedPortions: 1,
                    basePortions: 1,
                  )
                  ?.name ??
              component.name
        : component.name;
    final food = (name, unit);
    final amount = preparedMealComponentDisplayAmount(component);
    amounts.update(food, (sum) => sum + amount, ifAbsent: () => amount);
    (itemIds[food] ??= []).add(component.inventoryItemId);
  }
  // shortcut: the parser counts whole pieces, so a part of a piece counts
  // as at least one; give the parser fractional pieces when Vorlagen need
  // them.
  String amountText(String unit, double amount) =>
      preparedMealAmountText(unit.isEmpty ? max<double>(1, amount) : amount);
  final texts = {
    for (final MapEntry(key: (name, unit), :value) in amounts.entries)
      (name, unit): '${amountText(unit, value)}$unit $name',
  };
  return vorlage.copyWith(
    recipeIngredients: texts.values.toList(),
    recipeIngredientAssignments: {
      for (final MapEntry(:key, :value) in texts.entries) value: itemIds[key]!,
    },
  );
}
