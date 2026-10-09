import 'package:collection/collection.dart';
import 'package:yamt/features/inventory/application/ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/application/recipe_ingredient_assignment_support.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// The best Vorrat match for [requirement] of the ingredient [text], or
/// `null` when no item fits. Only an amount can be taken from the Vorrat, so
/// an ingredient without one never has a match.
InventoryItem? bestIngredientStockMatch({
  required String text,
  required TemplateIngredientRequirement? requirement,
  required List<InventoryItem> items,
  required String localeCode,
}) {
  if (requirement == null) {
    return null;
  }
  return _matches(
    text,
    items,
    localeCode,
  ).firstWhereOrNull((item) => _fits(item, requirement));
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

bool _fits(InventoryItem item, TemplateIngredientRequirement requirement) =>
    resolveEffectiveRequirementForItems(
      requirement: requirement,
      assignedItems: [item],
      amountConversion: null,
    ) !=
    null;
