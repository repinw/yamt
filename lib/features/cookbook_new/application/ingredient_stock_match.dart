import 'package:collection/collection.dart';
import 'package:yamt/features/inventory/application/ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/application/recipe_ingredient_assignment_support.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
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
