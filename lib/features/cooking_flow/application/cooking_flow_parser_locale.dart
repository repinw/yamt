/// Normalized piece unit used inside cookflow parser output.
const String cookingFlowParserPieceUnitCode = 'pc';

/// Locale-specific parser data for cookflow ingredient text.
class CookingFlowParserLocale {
  /// Creates parser locale data.
  const CookingFlowParserLocale({
    required this.amountUnitTokens,
    required this.pieceUnitTokens,
    required this.fuzzyInstructionStopWords,
    required this.fuzzyShortIngredientTokens,
  });

  /// Resolves parser data for a locale code.
  factory CookingFlowParserLocale.forLocaleCode(String? localeCode) {
    final normalizedCode = localeCode?.toLowerCase().split('_').first;
    return switch (normalizedCode) {
      'de' => german,
      'en' => english,
      _ => allSupported,
    };
  }

  /// Amount unit tokens recognized in ingredient labels.
  final Set<String> amountUnitTokens;

  /// Tokens normalized as piece/count units.
  final Set<String> pieceUnitTokens;

  /// Stop words ignored while fuzzy-matching instruction text.
  final Set<String> fuzzyInstructionStopWords;

  /// Short ingredient tokens that are still meaningful.
  final Set<String> fuzzyShortIngredientTokens;

  /// Regex alternation for [amountUnitTokens].
  String get amountUnitPattern {
    return amountUnitTokens.map(RegExp.escape).join('|');
  }

  /// Whether [unit] is a piece/count unit for this locale.
  bool isPieceUnit(String? unit) {
    final normalized = unit?.trim().toLowerCase();
    return normalized != null && pieceUnitTokens.contains(normalized);
  }

  /// German parser data.
  static const german = CookingFlowParserLocale(
    amountUnitTokens: <String>{
      ..._commonAmountUnitTokens,
      'el',
      'tl',
      'stück',
      'stueck',
      'stk',
      'st',
      'prise',
      'prisen',
      'bund',
      'zehe',
      'zehen',
      'dose',
      'dosen',
      'packung',
      'packungen',
      'becher',
      'bechern',
      'tasse',
      'tassen',
    },
    pieceUnitTokens: <String>{
      ..._commonPieceUnitTokens,
      'st',
      'stk',
      'stück',
      'stueck',
    },
    fuzzyInstructionStopWords: <String>{
      'das',
      'den',
      'der',
      'die',
      'ein',
      'eine',
      'einem',
      'einen',
      'einer',
      'auch',
      'in',
      'mit',
      'und',
      'zu',
    },
    fuzzyShortIngredientTokens: <String>{
      'ei',
      'öl',
    },
  );

  /// English parser data.
  static const english = CookingFlowParserLocale(
    amountUnitTokens: <String>{
      ..._commonAmountUnitTokens,
      'piece',
      'pieces',
      'tbsp',
      'tablespoon',
      'tablespoons',
      'tsp',
      'teaspoon',
      'teaspoons',
      'pinch',
      'pinches',
      'bunch',
      'clove',
      'cloves',
      'can',
      'cans',
      'package',
      'packages',
      'cup',
      'cups',
    },
    pieceUnitTokens: <String>{
      ..._commonPieceUnitTokens,
      'piece',
      'pieces',
    },
    fuzzyInstructionStopWords: <String>{
      'a',
      'an',
      'and',
      'for',
      'in',
      'of',
      'the',
      'to',
      'with',
    },
    fuzzyShortIngredientTokens: <String>{},
  );

  /// Combined parser data for non-UI application paths without locale context.
  static final allSupported = CookingFlowParserLocale(
    amountUnitTokens: Set.unmodifiable(<String>{
      ...german.amountUnitTokens,
      ...english.amountUnitTokens,
    }),
    pieceUnitTokens: Set.unmodifiable(<String>{
      ...german.pieceUnitTokens,
      ...english.pieceUnitTokens,
    }),
    fuzzyInstructionStopWords: Set.unmodifiable(<String>{
      ...german.fuzzyInstructionStopWords,
      ...english.fuzzyInstructionStopWords,
    }),
    fuzzyShortIngredientTokens: Set.unmodifiable(<String>{
      ...german.fuzzyShortIngredientTokens,
      ...english.fuzzyShortIngredientTokens,
    }),
  );
}

const Set<String> _commonAmountUnitTokens = <String>{
  'g',
  'kg',
  'mg',
  'ml',
  'cl',
  'dl',
  'l',
  cookingFlowParserPieceUnitCode,
};

const Set<String> _commonPieceUnitTokens = <String>{
  cookingFlowParserPieceUnitCode,
};
