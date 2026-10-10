import 'package:yamt/features/inventory/domain/ingredient_match_lexicon.dart';

final _nonMatchCharacters = RegExp('[^a-z0-9äöüß]+');
final _whitespace = RegExp(r'\s+');
final _quantityPrefix = RegExp(
  r'^(\d+\s+\d+/\d+|\d+/\d+|\d+(?:[.,]\d+)?)\s*(.+)$',
);

/// [value] in lower case, with every character that is not a letter or a
/// digit as a space.
String normalizeIngredientMatchText(String value) {
  return value.toLowerCase().replaceAll(_nonMatchCharacters, ' ').trim();
}

/// The words of the normalized [value] that can name a food, singular and
/// aliased by [lexicon].
Set<String> ingredientMatchTokens(
  String value,
  IngredientMatchLexicon lexicon,
) {
  return value
      .split(_whitespace)
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

/// [ingredient] without its amount and the [lexicon] prefix words before
/// its food.
String stripIngredientMatchPrefix(
  String ingredient,
  IngredientMatchLexicon lexicon,
) {
  final quantityMatch = _quantityPrefix.firstMatch(ingredient);
  final tail = quantityMatch?.group(2)?.trim() ?? ingredient.trim();
  if (tail.isEmpty) {
    return ingredient;
  }

  final tokens = tail.split(_whitespace).toList(growable: true);
  while (tokens.isNotEmpty) {
    final normalizedToken = normalizeIngredientMatchText(tokens.first)
        .replaceAll(' ', '');
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

String _canonicalMatchToken(String token, IngredientMatchLexicon lexicon) {
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

// Words of a recipe text that never name a food, in all languages.
const _functionWords = {
  'a',
  'an',
  'auf',
  'aus',
  'bei',
  'black',
  'das',
  'dem',
  'den',
  'der',
  'des',
  'die',
  'ein',
  'eine',
  'einem',
  'einen',
  'einer',
  'for',
  'freshly',
  'gelb',
  'gelbe',
  'grün',
  'grüne',
  'ground',
  'gemahlen',
  'gemahlener',
  'in',
  'mit',
  'nach',
  'of',
  'oder',
  'or',
  'rot',
  'rote',
  'roter',
  'rotes',
  'schwarz',
  'schwarzer',
  'the',
  'to',
  'vom',
  'von',
  'weiß',
  'weiße',
};

/// The words of [text] that can name foods, as ingredient matching sees
/// them in every language: without a leading amount, units, numbers, and
/// function words, singular, and aliased. Two texts name the same food
/// when their words share one.
Set<String> ingredientFoodWords(String text) {
  const lexicon = fallbackIngredientMatchLexicon;
  return {
    for (final word in ingredientMatchTokens(
      normalizeIngredientMatchText(
        stripIngredientMatchPrefix(text.trim(), lexicon),
      ),
      lexicon,
    ))
      if (!_functionWords.contains(word) && int.tryParse(word) == null) word,
  };
}
