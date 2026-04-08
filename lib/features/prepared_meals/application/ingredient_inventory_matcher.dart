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
  final normalizedItem = _normalizeMatchText(
    '${item.name} ${item.brand ?? ''}',
  );
  final ingredientCandidates = _ingredientMatchCandidates(ingredient);
  if (ingredientCandidates.isEmpty || normalizedItem.isEmpty) {
    return 0;
  }

  var bestScore = 0;
  for (final normalizedIngredient in ingredientCandidates) {
    final score = _scoreMatchTexts(
      normalizedIngredient: normalizedIngredient,
      normalizedItem: normalizedItem,
    );
    if (score > bestScore) {
      bestScore = score;
    }
  }
  return bestScore;
}

int _scoreMatchTexts({
  required String normalizedIngredient,
  required String normalizedItem,
}) {
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

Set<String> _ingredientMatchCandidates(String ingredient) {
  final trimmed = ingredient.trim();
  if (trimmed.isEmpty) {
    return const <String>{};
  }

  final normalizedIngredient = _normalizeMatchText(trimmed);
  if (normalizedIngredient.isEmpty) {
    return const <String>{};
  }

  final candidates = <String>{normalizedIngredient};
  final strippedIngredient = _stripIngredientPrefix(trimmed);
  final normalizedStrippedIngredient = _normalizeMatchText(strippedIngredient);
  if (normalizedStrippedIngredient.isNotEmpty) {
    candidates.add(normalizedStrippedIngredient);
  }
  return candidates;
}

String _normalizeMatchText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9äöüß]+'), ' ').trim();
}

Set<String> _matchTokens(String value) {
  const stopWords = <String>{
    'becher',
    'beutel',
    'bio',
    'bund',
    'bünde',
    'cl',
    'cup',
    'cups',
    'dose',
    'dosen',
    'el',
    'etwa',
    'and',
    'etwas',
    'fresh',
    'frisch',
    'frische',
    'frischer',
    'frisches',
    'g',
    'glas',
    'large',
    'kg',
    'klein',
    'kleine',
    'kleiner',
    'knolle',
    'knollen',
    'l',
    'little',
    'liter',
    'litre',
    'ml',
    'mittel',
    'mittlere',
    'mittleren',
    'mittlerer',
    'mittleres',
    'gross',
    'grosse',
    'grosses',
    'groß',
    'große',
    'großes',
    'packung',
    'packungen',
    'prise',
    'prisen',
    'scheibe',
    'scheiben',
    'small',
    'stange',
    'stangen',
    'stk',
    'stück',
    'stücke',
    'tasse',
    'tassen',
    'teeloeffel',
    'teelöffel',
    'tl',
    'zum',
    'zur',
    'und',
    'with',
    'wenig',
    'zehe',
    'zehen',
  };
  return value
      .split(RegExp(r'\s+'))
      .map((token) => _canonicalMatchToken(token.trim()))
      .where(
        (token) =>
            token.isNotEmpty &&
            !stopWords.contains(token) &&
            (token.length >= 3 || _shortIngredientTokens.contains(token)),
      )
      .toSet();
}

String _stripIngredientPrefix(String ingredient) {
  final quantityMatch = RegExp(
    r'^(\d+\s+\d+/\d+|\d+/\d+|\d+(?:[.,]\d+)?)\s*(.+)$',
  ).firstMatch(ingredient);
  final tail = quantityMatch?.group(2)?.trim() ?? ingredient.trim();
  if (tail.isEmpty) {
    return ingredient;
  }

  final tokens = tail.split(RegExp(r'\s+')).toList(growable: true);
  while (tokens.isNotEmpty) {
    final normalizedToken = _normalizeMatchText(
      tokens.first,
    ).replaceAll(' ', '');
    if (!_ingredientPrefixTokens.contains(normalizedToken)) {
      break;
    }
    tokens.removeAt(0);
  }

  if (tokens.isEmpty) {
    return tail;
  }
  return tokens.join(' ');
}

String _canonicalMatchToken(String token) {
  if (token.isEmpty) {
    return token;
  }

  final directAlias = _ingredientTokenAliases[token];
  if (directAlias != null) {
    return directAlias;
  }

  final singularToken = _singularizeMatchToken(token);
  return _ingredientTokenAliases[singularToken] ?? singularToken;
}

String _singularizeMatchToken(String token) {
  if (token == 'eier') {
    return 'ei';
  }
  if (token.endsWith('n') && token.length > 4) {
    return token.substring(0, token.length - 1);
  }
  if (token.endsWith('s') && token.length > 4) {
    return token.substring(0, token.length - 1);
  }
  return token;
}

const _ingredientPrefixTokens = <String>{
  'becher',
  'beutel',
  'bund',
  'bünde',
  'cl',
  'cup',
  'cups',
  'dl',
  'dose',
  'dosen',
  'el',
  'essloeffel',
  'esslöffel',
  'etwa',
  'etwas',
  'g',
  'glas',
  'gr',
  'gram',
  'gramm',
  'grams',
  'kg',
  'klein',
  'kleine',
  'kleiner',
  'kleines',
  'l',
  'large',
  'little',
  'liter',
  'litre',
  'mittel',
  'mittlere',
  'mittleren',
  'mittlerer',
  'mittleres',
  'ml',
  'oz',
  'packung',
  'packungen',
  'prise',
  'prisen',
  'scheibe',
  'scheiben',
  'small',
  'stange',
  'stangen',
  'stk',
  'stück',
  'stücke',
  'tasse',
  'tassen',
  'teeloeffel',
  'teelöffel',
  'tl',
  'wenig',
  'zehe',
  'zehen',
};

const _ingredientTokenAliases = <String, String>{
  'ei': 'ei',
  'eier': 'ei',
  'frühlingszwiebel': 'frühlingszwiebel',
  'frühlingszwiebeln': 'frühlingszwiebel',
  'karotte': 'karotte',
  'karotten': 'karotte',
  'lauchzwiebel': 'frühlingszwiebel',
  'lauchzwiebeln': 'frühlingszwiebel',
  'möhre': 'karotte',
  'möhren': 'karotte',
};

const _shortIngredientTokens = <String>{'ei', 'öl'};
