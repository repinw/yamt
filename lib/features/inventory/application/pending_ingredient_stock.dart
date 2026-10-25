import 'package:yamt/features/inventory/application/ingredient_stock_match.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

/// What [findPendingIngredientStock] finds for an open row.
typedef PendingIngredientStock = ({
  InventoryItem? best,
  List<InventoryItem> candidates,
  bool hidesByUnit,
});

/// The Vorrat items that can fill the open row [ingredient] with the row's
/// own amount, or the items of its name for a row that names no amount, by
/// the same rule as the recipe page: the `best` one, `null` when no matching
/// item fits, and all `candidates`, best first. `hidesByUnit` tells whether
/// some item in the Vorrat cannot supply the row in its unit.
PendingIngredientStock findPendingIngredientStock({
  required String ingredient,
  required List<InventoryItem> inventoryItems,
  required TemplateIngredientParser ingredientParser,
  required String localeCode,
}) {
  final requirement = ingredientParser.parseRequirement(
    ingredient: ingredient,
    selectedPortions: 1,
    basePortions: 1,
  );
  final (:matches, :others) = ingredientStockCandidates(
    text: ingredient,
    requirement: requirement,
    items: inventoryItems,
    localeCode: localeCode,
  );
  return (
    best: matches.firstOrNull,
    candidates: [...matches, ...others],
    hidesByUnit:
        requirement != null &&
        inventoryItems.any(
          (item) =>
              !item.isFullyConsumed && !ingredientItemFits(item, requirement),
        ),
  );
}
