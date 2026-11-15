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
