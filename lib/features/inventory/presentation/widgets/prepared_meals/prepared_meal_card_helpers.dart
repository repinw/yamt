part of 'prepared_meal_card.dart';

List<InventoryItem> _matchingInventoryItemsForIngredient({
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
    final rightScore = _ingredientMatchScore(
      ingredient: ingredient,
      item: right,
    );
    final leftScore = _ingredientMatchScore(ingredient: ingredient, item: left);
    if (rightScore != leftScore) {
      return rightScore.compareTo(leftScore);
    }
    return left.name.toLowerCase().compareTo(right.name.toLowerCase());
  });

  return sortedCandidates
      .where(
        (item) => _ingredientMatchScore(ingredient: ingredient, item: item) > 0,
      )
      .toList(growable: false);
}

int _ingredientMatchScore({
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
    'frisch',
    'frische',
    'frischer',
    'frisches',
    'klein',
    'kleine',
    'kleiner',
    'gross',
    'grosse',
    'grosses',
    'groß',
    'große',
    'großes',
    'etwas',
    'zum',
    'zur',
    'und',
  };
  return value
      .split(RegExp(r'\s+'))
      .map((token) => token.trim())
      .where((token) => token.length >= 3 && !stopWords.contains(token))
      .toSet();
}

String _pendingIngredientInventoryAmount(InventoryItem item) {
  if (item.usesAmountProgress && item.amountUnit != null) {
    return '${item.currentAmount} ${item.amountUnit!.code}';
  }
  return '${item.quantity}x';
}
