import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fuzzywuzzy;
import 'package:yamt/features/inventory/domain/ingredient_match_lexicon.dart';
import 'package:yamt/features/inventory/domain/ingredient_match_tokens.dart';
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

/// Whether [inventoryItems] hold a food that matches [ingredient]: the same
/// answer as [matchInventoryItemsForIngredient] being non-empty, without
/// ranking every item.
bool hasInventoryItemForIngredient({
  required String ingredient,
  required List<InventoryItem> inventoryItems,
  String? localeCode,
}) {
  return inventoryItems.any(
    (item) =>
        !item.isFullyConsumed &&
        ingredientInventoryMatchScore(
              ingredient: ingredient,
              item: item,
              localeCode: localeCode,
            ) >
            0,
  );
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

  return List<InventoryItem>.from(candidates)..sort((left, right) {
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
}

/// Ingredient inventory match score.
int ingredientInventoryMatchScore({
  required String ingredient,
  required InventoryItem item,
  String? localeCode,
}) {
  final primaryLexicon = ingredientMatchLexiconForLocale(localeCode);
  final primaryScore = _ingredientInventoryMatchScoreWithLexicon(
    ingredient: ingredient,
    item: item,
    lexicon: primaryLexicon,
  );
  if (identical(primaryLexicon, fallbackIngredientMatchLexicon)) {
    return primaryScore;
  }

  final fallbackScore = _ingredientInventoryMatchScoreWithLexicon(
    ingredient: ingredient,
    item: item,
    lexicon: fallbackIngredientMatchLexicon,
  );
  return fallbackScore > primaryScore ? fallbackScore : primaryScore;
}

int _ingredientInventoryMatchScoreWithLexicon({
  required String ingredient,
  required InventoryItem item,
  required IngredientMatchLexicon lexicon,
}) {
  final normalizedItem = normalizeIngredientMatchText(
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
  required IngredientMatchLexicon lexicon,
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

  final ingredientTokens = ingredientMatchTokens(normalizedIngredient, lexicon);
  final itemTokens = ingredientMatchTokens(normalizedItem, lexicon);
  for (final token in ingredientTokens) {
    if (itemTokens.contains(token)) {
      score += token.length >= 5 ? 15 : 10;
      continue;
    }
    if (normalizedItem.contains(token)) {
      score += 4;
    }
  }
  for (final token in itemTokens) {
    if (token.length >= _minimumIngredientCompoundTokenLength &&
        normalizedIngredient.contains(token)) {
      score += token.length >= 5 ? 12 : 8;
    }
  }
  final shingleScore = _tokenShingleContainmentScore(
    leftTokens: ingredientTokens,
    rightTokens: itemTokens,
  );
  if (shingleScore >= _ingredientShingleContainmentThreshold) {
    score += (shingleScore / 2).round();
  }
  final fuzzyScore = _ingredientFuzzyMatchScore(
    normalizedIngredient: normalizedIngredient,
    normalizedItem: normalizedItem,
  );
  if (fuzzyScore >= _ingredientFuzzyMatchThreshold) {
    score += fuzzyScore;
  }
  return score;
}

int _ingredientFuzzyMatchScore({
  required String normalizedIngredient,
  required String normalizedItem,
}) {
  final partialScore = fuzzywuzzy.partialRatio(
    normalizedIngredient,
    normalizedItem,
  );
  final tokenScore = fuzzywuzzy.tokenSetPartialRatio(
    normalizedIngredient,
    normalizedItem,
  );
  return partialScore > tokenScore ? partialScore : tokenScore;
}

int _tokenShingleContainmentScore({
  required Set<String> leftTokens,
  required Set<String> rightTokens,
}) {
  var bestScore = 0;
  for (final leftToken in leftTokens) {
    for (final rightToken in rightTokens) {
      final score = _shingleContainmentScore(leftToken, rightToken);
      if (score > bestScore) {
        bestScore = score;
      }
    }
  }
  return bestScore;
}

int _shingleContainmentScore(String leftToken, String rightToken) {
  if (leftToken.length < _minimumIngredientCompoundTokenLength ||
      rightToken.length < _minimumIngredientCompoundTokenLength) {
    return 0;
  }
  final leftShingles = _characterShingles(leftToken);
  final rightShingles = _characterShingles(rightToken);
  if (leftShingles.isEmpty || rightShingles.isEmpty) {
    return 0;
  }
  final commonCount = leftShingles.intersection(rightShingles).length;
  if (commonCount == 0) {
    return 0;
  }
  final smallerCount = leftShingles.length < rightShingles.length
      ? leftShingles.length
      : rightShingles.length;
  return ((commonCount / smallerCount) * 100).round();
}

Set<String> _characterShingles(String token) {
  final shingles = <String>{};
  for (final size in _ingredientShingleSizes) {
    if (token.length < size) {
      continue;
    }
    for (var index = 0; index <= token.length - size; index++) {
      shingles.add(token.substring(index, index + size));
    }
  }
  return shingles;
}

Set<String> _ingredientMatchCandidates(
  String ingredient,
  IngredientMatchLexicon lexicon,
) {
  final trimmed = ingredient.trim();
  if (trimmed.isEmpty) {
    return const <String>{};
  }

  final normalizedIngredient = normalizeIngredientMatchText(trimmed);
  if (normalizedIngredient.isEmpty) {
    return const <String>{};
  }

  final candidates = <String>{normalizedIngredient};
  final strippedIngredient = stripIngredientMatchPrefix(trimmed, lexicon);
  final normalizedStrippedIngredient = normalizeIngredientMatchText(
    strippedIngredient,
  );
  if (normalizedStrippedIngredient.isNotEmpty) {
    candidates.add(normalizedStrippedIngredient);
  }
  return candidates;
}

const _ingredientFuzzyMatchThreshold = 80;
const _ingredientShingleContainmentThreshold = 75;
const _minimumIngredientCompoundTokenLength = 4;
const _ingredientShingleSizes = <int>{3, 4, 5};
