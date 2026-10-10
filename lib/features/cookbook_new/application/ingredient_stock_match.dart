import 'package:collection/collection.dart';
import 'package:yamt/features/inventory/application/ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/application/recipe_ingredient_assignment_support.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// The best Vorrat match for [requirement] of the ingredient [text], or
/// `null` when no item fits. Only an amount can be taken from the Vorrat, so
/// an ingredient without one never has a match. A recipe's saved
/// [amountConversion] lets pieces come from an item kept in grams or
/// milliliters.
InventoryItem? bestIngredientStockMatch({
  required String text,
  required TemplateIngredientRequirement? requirement,
  required List<InventoryItem> items,
  required String localeCode,
  RecipeIngredientAmountConversion? amountConversion,
}) {
  if (requirement == null) {
    return null;
  }
  return _matches(
    text,
    items,
    localeCode,
  ).firstWhereOrNull((item) => _fits(item, requirement, amountConversion));
}

/// The Vorrat items that can supply [requirement] of the ingredient [text]:
/// the matches by name first, best first, then every other item in a fitting
/// unit by name. [amountConversion] works as in [bestIngredientStockMatch].
List<InventoryItem> ingredientStockCandidates({
  required String text,
  required TemplateIngredientRequirement? requirement,
  required List<InventoryItem> items,
  required String localeCode,
  RecipeIngredientAmountConversion? amountConversion,
}) {
  if (requirement == null) {
    return const <InventoryItem>[];
  }
  final matches = _matches(
    text,
    items,
    localeCode,
  ).where((item) => _fits(item, requirement, amountConversion)).toList();
  final matchIds = {for (final item in matches) item.id};
  final others =
      items
          .where(
            (item) =>
                !matchIds.contains(item.id) &&
                !item.isFullyConsumed &&
                _fits(item, requirement, amountConversion),
          )
          .toList()
        ..sort(
          (left, right) =>
              left.name.toLowerCase().compareTo(right.name.toLowerCase()),
        );
  return [...matches, ...others];
}

/// How much of [requirement] the [items] cannot supply, in the unit the
/// Vorrat counts it in, or `null` when they supply all of it or the
/// ingredient has no amount. [amountConversion] works as in
/// [bestIngredientStockMatch].
({int amount, InventoryAmountUnit unit})? ingredientShortfall({
  required TemplateIngredientRequirement? requirement,
  required List<InventoryItem> items,
  RecipeIngredientAmountConversion? amountConversion,
}) {
  if (requirement == null) {
    return null;
  }
  final effective = resolveEffectiveRequirementForItems(
    requirement: requirement,
    assignedItems: items,
    amountConversion: amountConversion,
  );
  // ponytail: pieces count as supplied; add per-piece math when recipes
  // need more pieces than the Vorrat holds.
  if (effective == null || effective.unit == InventoryAmountUnit.piece) {
    return null;
  }
  final missing =
      effective.amount - ingredientStockedAmount(items, effective.unit);
  return missing > 0 ? (amount: missing, unit: effective.unit) : null;
}

/// What [items] hold in [unit], or 0 without a unit.
int ingredientStockedAmount(
  List<InventoryItem> items,
  InventoryAmountUnit? unit,
) => unit == null
    ? 0
    : items
          .where((item) => item.amountUnit == unit)
          .fold(0, (sum, item) => sum + item.availableAmount);

List<InventoryItem> _matches(
  String text,
  List<InventoryItem> items,
  String localeCode,
) => matchInventoryItemsForIngredient(
  ingredient: text,
  inventoryItems: items,
  localeCode: localeCode,
);

bool _fits(
  InventoryItem item,
  TemplateIngredientRequirement requirement,
  RecipeIngredientAmountConversion? amountConversion,
) =>
    resolveEffectiveRequirementForItems(
      requirement: requirement,
      assignedItems: [item],
      amountConversion: amountConversion,
    ) !=
    null;
