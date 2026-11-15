import 'package:yamt/features/inventory/application/ingredient_match_score.dart';
import 'package:yamt/features/inventory/domain/ingredient_compound_head.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Resolve inventory items by id.
List<InventoryItem> resolveInventoryItemsById({
  required List<String> inventoryItemIds,
  required List<InventoryItem> inventoryItems,
}) {
  if (inventoryItemIds.isEmpty || inventoryItems.isEmpty) {
    return const <InventoryItem>[];
  }

  final itemsById = <String, InventoryItem>{
    for (final item in inventoryItems) item.id: item,
  };
  return inventoryItemIds
      .map((itemId) => itemsById[itemId])
      .whereType<InventoryItem>()
      .toList(growable: false);
}

/// Whether [inventoryItems] hold a food that matches [ingredient], not only
/// weakly ([isWeakIngredientMatch]), without ranking every item.
bool hasInventoryItemForIngredient({
  required String ingredient,
  required List<InventoryItem> inventoryItems,
  String? localeCode,
}) {
  return inventoryItems.any(
    (item) =>
        !item.isFullyConsumed &&
        ingredientMatchesFully(
          ingredient: ingredient,
          item: item,
          localeCode: localeCode,
        ),
  );
}

/// Whether [item] matches [ingredient] by name, and not only weakly
/// ([isWeakIngredientMatch]), so it may supply the line.
bool ingredientMatchesFully({
  required String ingredient,
  required InventoryItem item,
  String? localeCode,
}) =>
    !isWeakIngredientMatch(ingredient: ingredient, item: item) &&
    ingredientInventoryMatchScore(
          ingredient: ingredient,
          item: item,
          localeCode: localeCode,
        ) >
        0;

/// The items not used up that match [ingredient], best first, with their
/// match score.
List<({InventoryItem item, int score})> scoreInventoryItemsForIngredient({
  required String ingredient,
  required List<InventoryItem> inventoryItems,
  String? localeCode,
}) => [
  for (final match in _rankScored(ingredient, inventoryItems, localeCode))
    if (match.score > 0) match,
];

/// The items not used up, best score first, then by name. Each score is
/// worked out once: the fuzzy match is too slow to repeat per comparison.
List<({InventoryItem item, int score})> _rankScored(
  String ingredient,
  List<InventoryItem> inventoryItems,
  String? localeCode,
) {
  return [
    for (final item in inventoryItems)
      if (!item.isFullyConsumed)
        (
          item: item,
          score: ingredientInventoryMatchScore(
            ingredient: ingredient,
            item: item,
            localeCode: localeCode,
          ),
        ),
  ]..sort((left, right) {
    if (right.score != left.score) {
      return right.score.compareTo(left.score);
    }
    return left.item.name.toLowerCase().compareTo(
      right.item.name.toLowerCase(),
    );
  });
}
