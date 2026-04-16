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

/// Match inventory items for ingredient.
List<InventoryItem> matchInventoryItemsForIngredient({
  required String ingredient,
  required List<InventoryItem> inventoryItems,
  String? localeCode,
}) {
  return rankInventoryItemsForIngredient(
        ingredient: ingredient,
        inventoryItems: inventoryItems,
        localeCode: localeCode,
      )
      .where(
        (item) =>
            ingredientInventoryMatchScore(
              ingredient: ingredient,
              item: item,
              localeCode: localeCode,
            ) >
            0,
      )
      .toList(growable: false);
}

/// Rank inventory items for ingredient.
List<InventoryItem> rankInventoryItemsForIngredient({
  required String ingredient,
  required List<InventoryItem> inventoryItems,
  String? localeCode,
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
      localeCode: localeCode,
    );
    final leftScore = ingredientInventoryMatchScore(
      ingredient: ingredient,
      item: left,
      localeCode: localeCode,
    );
    if (rightScore != leftScore) {
      return rightScore.compareTo(leftScore);
    }
    return left.name.toLowerCase().compareTo(right.name.toLowerCase());
  });
  return sortedCandidates;
}

/// Ingredient inventory match score.
int ingredientInventoryMatchScore({
  required String ingredient,
  required InventoryItem item,
  String? localeCode,
}) {
  final primaryLexicon = _ingredientMatcherLexiconForLocale(localeCode);
  final primaryScore = _ingredientInventoryMatchScoreWithLexicon(
    ingredient: ingredient,
    item: item,
    lexicon: primaryLexicon,
  );
  if (identical(primaryLexicon, _fallbackIngredientMatcherLexicon)) {
    return primaryScore;
  }

  final fallbackScore = _ingredientInventoryMatchScoreWithLexicon(
    ingredient: ingredient,
    item: item,
    lexicon: _fallbackIngredientMatcherLexicon,
  );
  return fallbackScore > primaryScore ? fallbackScore : primaryScore;
}

int _ingredientInventoryMatchScoreWithLexicon({
  required String ingredient,
  required InventoryItem item,
  required _IngredientMatcherLexicon lexicon,
}) {
  final normalizedItem = _normalizeMatchText(
    '${item.name} ${item.brand ?? ''}',
  );
  final ingredientCandidates = _ingredientMatchCandidates(ingredient, lexicon);
  if (ingredientCandidates.isEmpty || normalizedItem.isEmpty) {
    return 0;
  }

  var bestScore = 0;
  for (final normalizedIngredient in ingredientCandidates) {
    final score = _scoreMatchTexts(
      normalizedIngredient: normalizedIngredient,
      normalizedItem: normalizedItem,
      lexicon: lexicon,
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
  required _IngredientMatcherLexicon lexicon,
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

  final ingredientTokens = _matchTokens(normalizedIngredient, lexicon);
  final itemTokens = _matchTokens(normalizedItem, lexicon);
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

Set<String> _ingredientMatchCandidates(
  String ingredient,
  _IngredientMatcherLexicon lexicon,
) {
  final trimmed = ingredient.trim();
  if (trimmed.isEmpty) {
    return const <String>{};
  }

  final normalizedIngredient = _normalizeMatchText(trimmed);
  if (normalizedIngredient.isEmpty) {
    return const <String>{};
  }

  final candidates = <String>{normalizedIngredient};
  final strippedIngredient = _stripIngredientPrefix(trimmed, lexicon);
  final normalizedStrippedIngredient = _normalizeMatchText(strippedIngredient);
  if (normalizedStrippedIngredient.isNotEmpty) {
    candidates.add(normalizedStrippedIngredient);
  }
  return candidates;
}

String _normalizeMatchText(String value) {
  return value.toLowerCase().replaceAll(RegExp('[^a-z0-9äöüß]+'), ' ').trim();
}

Set<String> _matchTokens(String value, _IngredientMatcherLexicon lexicon) {
  return value
      .split(RegExp(r'\s+'))
      .map((token) => _canonicalMatchToken(token.trim(), lexicon))
      .where(
        (token) =>
            token.isNotEmpty &&
            !lexicon.stopWords.contains(token) &&
            (token.length >= 3 ||
                lexicon.shortIngredientTokens.contains(token)),
      )
      .toSet();
}

String _stripIngredientPrefix(
  String ingredient,
  _IngredientMatcherLexicon lexicon,
) {
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
    if (!lexicon.prefixTokens.contains(normalizedToken)) {
      break;
    }
    tokens.removeAt(0);
  }

  if (tokens.isEmpty) {
    return tail;
  }
  return tokens.join(' ');
}

String _canonicalMatchToken(String token, _IngredientMatcherLexicon lexicon) {
  if (token.isEmpty) {
    return token;
  }

  final directAlias = lexicon.tokenAliases[token];
  if (directAlias != null) {
    return directAlias;
  }

  final singularToken = _singularizeMatchToken(token);
  return lexicon.tokenAliases[singularToken] ?? singularToken;
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

class _IngredientMatcherLexicon {
  const _IngredientMatcherLexicon({
    required this.stopWords,
    required this.prefixTokens,
    required this.tokenAliases,
    this.shortIngredientTokens = const <String>{},
  });

  final Set<String> stopWords;
  final Set<String> prefixTokens;
  final Map<String, String> tokenAliases;
  final Set<String> shortIngredientTokens;
}

_IngredientMatcherLexicon _ingredientMatcherLexiconForLocale(
  String? localeCode,
) {
  return switch (_normalizedLocaleCode(localeCode)) {
    'de' => _germanIngredientMatcherLexicon,
    'en' => _englishIngredientMatcherLexicon,
    _ => _fallbackIngredientMatcherLexicon,
  };
}

String _normalizedLocaleCode(String? localeCode) {
  if (localeCode == null) {
    return '';
  }
  final trimmed = localeCode.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return '';
  }
  return trimmed.split(RegExp('[-_]')).first;
}

const _fallbackIngredientMatcherLexicon = _IngredientMatcherLexicon(
  stopWords: {
    ..._commonIngredientStopWords,
    ..._germanIngredientStopWords,
    ..._englishIngredientStopWords,
  },
  prefixTokens: {
    ..._commonIngredientPrefixTokens,
    ..._germanIngredientPrefixTokens,
    ..._englishIngredientPrefixTokens,
  },
  tokenAliases: {
    ..._commonIngredientTokenAliases,
    ..._germanIngredientTokenAliases,
    ..._englishIngredientTokenAliases,
  },
  shortIngredientTokens: {
    ..._commonShortIngredientTokens,
    ..._germanShortIngredientTokens,
    ..._englishShortIngredientTokens,
  },
);

const _germanIngredientMatcherLexicon = _IngredientMatcherLexicon(
  stopWords: {..._commonIngredientStopWords, ..._germanIngredientStopWords},
  prefixTokens: {
    ..._commonIngredientPrefixTokens,
    ..._germanIngredientPrefixTokens,
  },
  tokenAliases: {
    ..._commonIngredientTokenAliases,
    ..._germanIngredientTokenAliases,
  },
  shortIngredientTokens: {
    ..._commonShortIngredientTokens,
    ..._germanShortIngredientTokens,
  },
);

const _englishIngredientMatcherLexicon = _IngredientMatcherLexicon(
  stopWords: {..._commonIngredientStopWords, ..._englishIngredientStopWords},
  prefixTokens: {
    ..._commonIngredientPrefixTokens,
    ..._englishIngredientPrefixTokens,
  },
  tokenAliases: {
    ..._commonIngredientTokenAliases,
    ..._englishIngredientTokenAliases,
  },
  shortIngredientTokens: {
    ..._commonShortIngredientTokens,
    ..._englishShortIngredientTokens,
  },
);

const _commonIngredientStopWords = <String>{
  'cl',
  'dl',
  'g',
  'gr',
  'gram',
  'gramm',
  'grams',
  'kg',
  'l',
  'liter',
  'litre',
  'ml',
  'oz',
};

const _germanIngredientStopWords = <String>{
  'becher',
  'beutel',
  'bio',
  'bund',
  'bünde',
  'dose',
  'dosen',
  'el',
  'essloeffel',
  'esslöffel',
  'etwa',
  'etwas',
  'frisch',
  'frische',
  'frischer',
  'frisches',
  'glas',
  'gross',
  'grosse',
  'grosses',
  'groß',
  'große',
  'großes',
  'klein',
  'kleine',
  'kleiner',
  'knolle',
  'knollen',
  'mittel',
  'mittlere',
  'mittleren',
  'mittlerer',
  'mittleres',
  'packung',
  'packungen',
  'prise',
  'prisen',
  'scheibe',
  'scheiben',
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
  'und',
  'wenig',
  'zehe',
  'zehen',
  'zum',
  'zur',
};

const _englishIngredientStopWords = <String>{
  'and',
  'bottle',
  'bottles',
  'bunch',
  'bunches',
  'can',
  'cans',
  'cup',
  'cups',
  'fresh',
  'jar',
  'jars',
  'large',
  'little',
  'package',
  'packages',
  'pinch',
  'pinches',
  'small',
  'tablespoon',
  'tablespoons',
  'tbsp',
  'teaspoon',
  'teaspoons',
  'tsp',
  'with',
};

const _commonIngredientPrefixTokens = <String>{..._commonIngredientStopWords};

const _germanIngredientPrefixTokens = <String>{..._germanIngredientStopWords};

const _englishIngredientPrefixTokens = <String>{..._englishIngredientStopWords};

const _commonIngredientTokenAliases = <String, String>{
  'ei': 'ei',
  'eier': 'ei',
};

const _germanIngredientTokenAliases = <String, String>{
  'frühlingszwiebel': 'frühlingszwiebel',
  'frühlingszwiebeln': 'frühlingszwiebel',
  'karotte': 'karotte',
  'karotten': 'karotte',
  'lauchzwiebel': 'frühlingszwiebel',
  'lauchzwiebeln': 'frühlingszwiebel',
  'möhre': 'karotte',
  'möhren': 'karotte',
};

const _englishIngredientTokenAliases = <String, String>{
  'aubergine': 'eggplant',
  'aubergines': 'eggplant',
  'cilantro': 'coriander',
  'courgette': 'zucchini',
  'courgettes': 'zucchini',
  'garbanzo': 'chickpea',
  'garbanzos': 'chickpea',
  'scallion': 'spring',
  'scallions': 'spring',
};

const _commonShortIngredientTokens = <String>{'ei'};
const _germanShortIngredientTokens = <String>{'öl'};
const _englishShortIngredientTokens = <String>{};
