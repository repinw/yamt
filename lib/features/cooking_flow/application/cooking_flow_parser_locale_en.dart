import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';

/// English amount unit tokens.
const Set<String> englishAmountUnitTokens = <String>{
  ...commonAmountUnitTokens,
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
};

/// English piece unit tokens.
const Set<String> englishPieceUnitTokens = <String>{
  ...commonPieceUnitTokens,
  'piece',
  'pieces',
};

/// English stop words for instruction text matching.
const Set<String> englishFuzzyInstructionStopWords = <String>{
  'a',
  'an',
  'and',
  'for',
  'in',
  'of',
  'the',
  'to',
  'with',
};

/// Short English ingredient tokens that are still meaningful.
const Set<String> englishFuzzyShortIngredientTokens = <String>{
  'egg',
  'oil',
  'salt',
  'rice',
  'corn',
  'bun',
};

/// Irregular English ingredient variants.
const Map<String, List<String>> englishIrregularIngredientVariants =
    <String, List<String>>{
      'egg': <String>['egg', 'eggs'],
      'eggs': <String>['eggs', 'egg'],
      'tomato': <String>['tomato', 'tomatoes'],
      'tomatoes': <String>['tomatoes', 'tomato'],
      'potato': <String>['potato', 'potatoes'],
      'potatoes': <String>['potatoes', 'potato'],
    };
