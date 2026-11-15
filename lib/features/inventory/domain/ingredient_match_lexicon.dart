final _localeSeparator = RegExp('[-_]');

/// The words that ingredient matching skips, strips, rewrites, or keeps
/// although they are short, in one language.
class IngredientMatchLexicon {
  /// Creates the lexicon.
  const new({
    required this.stopWords,
    required this.prefixTokens,
    required this.tokenAliases,
    required this.kindWords,
    this.shortIngredientTokens = const <String>{},
  });

  /// Words that never name a food, such as units.
  final Set<String> stopWords;

  /// Words that an ingredient may start with before its food.
  final Set<String> prefixTokens;

  /// The common word per word, such as "karotte" for "möhre".
  final Map<String, String> tokenAliases;

  /// Adjectives for a colour or kind that name no food by themselves, such
  /// as "schwarz", without an ending ("schwarzer" is the same word).
  final Set<String> kindWords;

  /// Foods with names shorter than three letters, such as "ei".
  final Set<String> shortIngredientTokens;
}

/// The lexicon for [localeCode], or the one of all languages.
IngredientMatchLexicon ingredientMatchLexiconForLocale(String? localeCode) {
  return switch (_normalizedLocaleCode(localeCode)) {
    'de' => _germanIngredientMatcherLexicon,
    'en' => _englishIngredientMatcherLexicon,
    _ => fallbackIngredientMatchLexicon,
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
  return trimmed.split(_localeSeparator).first;
}

/// The lexicon of all languages.
const fallbackIngredientMatchLexicon = IngredientMatchLexicon(
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
  kindWords: {'mild', ..._germanKindWords, ..._englishKindWords},
  shortIngredientTokens: {
    ..._commonShortIngredientTokens,
    ..._germanShortIngredientTokens,
    ..._englishShortIngredientTokens,
  },
);

const _germanIngredientMatcherLexicon = IngredientMatchLexicon(
  stopWords: {..._commonIngredientStopWords, ..._germanIngredientStopWords},
  prefixTokens: {
    ..._commonIngredientPrefixTokens,
    ..._germanIngredientPrefixTokens,
  },
  tokenAliases: {
    ..._commonIngredientTokenAliases,
    ..._germanIngredientTokenAliases,
  },
  kindWords: {'mild', ..._germanKindWords},
  shortIngredientTokens: {
    ..._commonShortIngredientTokens,
    ..._germanShortIngredientTokens,
  },
);

const _englishIngredientMatcherLexicon = IngredientMatchLexicon(
  stopWords: {..._commonIngredientStopWords, ..._englishIngredientStopWords},
  prefixTokens: {
    ..._commonIngredientPrefixTokens,
    ..._englishIngredientPrefixTokens,
  },
  tokenAliases: {
    ..._commonIngredientTokenAliases,
    ..._englishIngredientTokenAliases,
  },
  kindWords: {'mild', ..._englishKindWords},
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

// "frisch", "bio" and "fresh" are stop words, so never a shared word.
const _germanKindWords = <String>{
  'braun',
  'dunkel',
  'fein',
  'gelb',
  'gemahlen',
  'getrocknet',
  'griechisch',
  'grob',
  'grün',
  'hell',
  'italienisch',
  'natur',
  'rot',
  'sauer',
  'scharf',
  'schwarz',
  'süß',
  'weiss',
  'weiß',
};

const _englishKindWords = <String>{
  'black',
  'brown',
  'coarse',
  'dark',
  'dried',
  'fine',
  'greek',
  'green',
  'ground',
  'hot',
  'italian',
  'light',
  'plain',
  'red',
  'sour',
  'sweet',
  'white',
  'yellow',
};
