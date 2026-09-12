import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale_de.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale_en.dart';

/// Normalized unit code for piece-counted ingredients in cooking flow parsing.
const String cookingFlowParserPieceUnitCode = 'pc';

/// Known piece unit used inside cookflow inventory and ingredient drafts.
const String cookingFlowPieceUnitCode = cookingFlowParserPieceUnitCode;

/// Base amount unit tokens common across locales.
const Set<String> commonAmountUnitTokens = <String>{
  'g',
  'kg',
  'mg',
  'ml',
  'cl',
  'dl',
  'l',
  cookingFlowParserPieceUnitCode,
};

/// Base piece unit tokens common across locales.
const Set<String> commonPieceUnitTokens = <String>{
  cookingFlowParserPieceUnitCode,
};

/// Locale-specific dictionary tokens for cooking flow ingredient matching.
class CookingFlowParserLocale {
  /// Creates a locale configuration for cooking flow parsing.
  const CookingFlowParserLocale({
    required this.amountUnitTokens,
    required this.pieceUnitTokens,
    required this.fuzzyInstructionStopWords,
    required this.fuzzyShortIngredientTokens,
    this.defaultPieceUnitLabel = 'Stück',
    this.irregularIngredientVariants = const <String, List<String>>{},
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

  /// Default localized label for piece units when no specific measure label
  /// exists.
  final String defaultPieceUnitLabel;

  /// Irregular ingredient noun forms mapping base/plural/compound forms.
  final Map<String, List<String>> irregularIngredientVariants;

  /// Regex alternation for [amountUnitTokens].
  String get amountUnitPattern {
    return amountUnitTokens.map(RegExp.escape).join('|');
  }

  /// Whether [unit] is a piece/count unit for this locale.
  bool isPieceUnit(String? unit) {
    final normalized = unit?.trim().toLowerCase();
    return normalized != null && pieceUnitTokens.contains(normalized);
  }

  /// Resolves morphological variants (singular, plural, irregular forms)
  /// for [name].
  List<String> resolveIngredientVariants(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const <String>[];
    }

    final lower = trimmed.toLowerCase();
    final results = <String>{trimmed};

    // Check irregular variants table.
    final irregulars = irregularIngredientVariants[lower];
    if (irregulars != null) {
      for (final variant in irregulars) {
        results.add(_matchCase(reference: trimmed, value: variant));
      }
    }

    // Locale-specific inflection heuristics.
    if (this == german || defaultPieceUnitLabel == 'Stück') {
      _addGermanMorphologyVariants(trimmed, results);
    } else if (this == english) {
      _addEnglishMorphologyVariants(trimmed, results);
    }

    return results.toList(growable: false);
  }

  void _addGermanMorphologyVariants(String text, Set<String> results) {
    final lower = text.toLowerCase();
    // Plural ending with -n or -en -> singular.
    if (lower.endsWith('n') && lower.length > 3) {
      if (lower.endsWith('en') && lower.length > 4) {
        // e.g. Tomaten -> Tomate, Karotten -> Karotte, Gurken -> Gurke
        results.add(text.substring(0, text.length - 1));
        // e.g. Möhren -> Möhre, Zwiebeln -> Zwiebel
        if (!lower.endsWith('eln') && !lower.endsWith('ern')) {
          results.add(text.substring(0, text.length - 2));
        }
      } else {
        // e.g. Zwiebeln -> Zwiebel, Kartoffeln -> Kartoffel
        results.add(text.substring(0, text.length - 1));
      }
    } else if (lower.endsWith('e') && lower.length > 3) {
      // e.g. Zwiebel -> Zwiebeln, Tomate -> Tomaten, Pilze -> Pilz
      results
        ..add('${text}n')
        ..add(text.substring(0, text.length - 1));
    } else if (!lower.endsWith('s') && lower.length > 2) {
      // e.g. Pilz -> Pilze
      results.add('${text}e');
    }
  }

  void _addEnglishMorphologyVariants(String text, Set<String> results) {
    final lower = text.toLowerCase();
    if (lower.endsWith('ies') && lower.length > 4) {
      results.add('${text.substring(0, text.length - 3)}y');
    } else if (lower.endsWith('es') && lower.length > 4) {
      results.add(text.substring(0, text.length - 2));
    } else if (lower.endsWith('s') && lower.length > 3) {
      results.add(text.substring(0, text.length - 1));
    } else {
      results.add('${text}s');
    }
  }

  static String _matchCase({
    required String reference,
    required String value,
  }) {
    if (reference.isEmpty || value.isEmpty) {
      return value;
    }
    final first = reference[0];
    if (first == first.toUpperCase()) {
      return value[0].toUpperCase() + value.substring(1);
    }
    return value.toLowerCase();
  }

  /// German parser data.
  static const german = CookingFlowParserLocale(
    amountUnitTokens: germanAmountUnitTokens,
    pieceUnitTokens: germanPieceUnitTokens,
    fuzzyInstructionStopWords: germanFuzzyInstructionStopWords,
    fuzzyShortIngredientTokens: germanFuzzyShortIngredientTokens,
    irregularIngredientVariants: germanIrregularIngredientVariants,
  );

  /// English parser data.
  static const english = CookingFlowParserLocale(
    amountUnitTokens: englishAmountUnitTokens,
    pieceUnitTokens: englishPieceUnitTokens,
    fuzzyInstructionStopWords: englishFuzzyInstructionStopWords,
    fuzzyShortIngredientTokens: englishFuzzyShortIngredientTokens,
    defaultPieceUnitLabel: 'pieces',
    irregularIngredientVariants: englishIrregularIngredientVariants,
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
    irregularIngredientVariants: Map.unmodifiable(<String, List<String>>{
      ...german.irregularIngredientVariants,
      ...english.irregularIngredientVariants,
    }),
  );
}
