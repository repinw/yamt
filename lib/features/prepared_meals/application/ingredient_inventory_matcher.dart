import 'package:yamt/features/inventory/domain/inventory_item.dart';

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

List<InventoryItem> matchInventoryItemsForIngredient({
  required String ingredient,
  required List<InventoryItem> inventoryItems,
}) {
  return rankInventoryItemsForIngredient(
        ingredient: ingredient,
        inventoryItems: inventoryItems,
      )
      .where(
        (item) =>
            ingredientInventoryMatchScore(ingredient: ingredient, item: item) >
            0,
      )
      .toList(growable: false);
}

List<InventoryItem> rankInventoryItemsForIngredient({
  required String ingredient,
  required List<InventoryItem> inventoryItems,
}) {
  final candidates = inventoryItems
      .where((item) => !item.isFullyConsumed)
      .toList(growable: false);
  if (candidates.isEmpty) {
    return const <InventoryItem>[];
  }

  final sortedCandidates = List<InventoryItem>.from(candidates);
  sortedCandidates.sort((left, right) {
    final rightScore = ingredientInventoryMatchScore(
      ingredient: ingredient,
      item: right,
    );
    final leftScore = ingredientInventoryMatchScore(
      ingredient: ingredient,
      item: left,
    );
    if (rightScore != leftScore) {
      return rightScore.compareTo(leftScore);
    }
    return left.name.toLowerCase().compareTo(right.name.toLowerCase());
  });
  return sortedCandidates;
}

int ingredientInventoryMatchScore({
  required String ingredient,
  required InventoryItem item,
}) {
  final normalizedIngredient = _normalizeMatchText(ingredient);
  final normalizedItem = _normalizeMatchText(
    '${item.name} ${item.brand ?? ''}',
  );
  if (normalizedIngredient.isEmpty || normalizedItem.isEmpty) {
    return 0;
  }

  var score = 0;
  if (normalizedItem == normalizedIngredient) {
    score += 100;
  }
  if (normalizedItem.contains(normalizedIngredient)) {
    score += 60;
  }
  if (normalizedIngredient.contains(normalizedItem)) {
    score += 30;
  }

  final ingredientTokens = _matchTokens(normalizedIngredient);
  final itemTokens = _matchTokens(normalizedItem);
  for (final token in ingredientTokens) {
    if (itemTokens.contains(token)) {
      score += token.length >= 5 ? 15 : 10;
      continue;
    }
    if (normalizedItem.contains(token)) {
      score += 4;
    }
  }
  return score;
}

String _normalizeMatchText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9äöüß]+'), ' ').trim();
}

Set<String> _matchTokens(String value) {
  const stopWords = <String>{
    'and',
    'fresh',
    'frisch',
    'frische',
    'frischer',
    'frisches',
    'large',
    'klein',
    'kleine',
    'kleiner',
    'little',
    'gross',
    'grosse',
    'grosses',
    'groß',
    'große',
    'großes',
    'small',
    'etwas',
    'zum',
    'zur',
    'und',
    'with',
  };
  return value
      .split(RegExp(r'\s+'))
      .map((token) => token.trim())
      .where((token) => token.length >= 3 && !stopWords.contains(token))
      .toSet();
}
