import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';

/// German amount unit tokens.
const Set<String> germanAmountUnitTokens = <String>{
  ...commonAmountUnitTokens,
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
};

/// German piece unit tokens.
const Set<String> germanPieceUnitTokens = <String>{
  ...commonPieceUnitTokens,
  'st',
  'stk',
  'stück',
  'stueck',
};

/// German stop words for instruction text matching.
const Set<String> germanFuzzyInstructionStopWords = <String>{
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
};

/// Short German ingredient tokens that are still meaningful.
const Set<String> germanFuzzyShortIngredientTokens = <String>{
  'ei',
  'öl',
  'pilz',
  'kohl',
  'reis',
  'mais',
  'senf',
  'hefe',
  'brot',
};

/// Irregular German ingredient variants.
const Map<String, List<String>> germanIrregularIngredientVariants =
    <String, List<String>>{
      'ei': <String>['ei', 'eier'],
      'eier': <String>['eier', 'ei'],
      'knoblauch': <String>[
        'knoblauch',
        'knoblauchzehe',
        'knoblauchzehen',
      ],
      'knoblauchzehe': <String>[
        'knoblauchzehe',
        'knoblauchzehen',
        'knoblauch',
      ],
      'knoblauchzehen': <String>[
        'knoblauchzehen',
        'knoblauchzehe',
        'knoblauch',
      ],
      'apfel': <String>['apfel', 'äpfel'],
      'äpfel': <String>['äpfel', 'apfel'],
      'nuss': <String>['nuss', 'nüsse'],
      'nüsse': <String>['nüsse', 'nuss'],
      'kraut': <String>['kraut', 'kräuter'],
      'kräuter': <String>['kräuter', 'kraut'],
      'pilz': <String>['pilz', 'pilze'],
      'pilze': <String>['pilze', 'pilz'],
      'lauch': <String>['lauch', 'lauchstange', 'lauchstangen'],
      'lauchstange': <String>['lauchstange', 'lauchstangen', 'lauch'],
      'lauchstangen': <String>['lauchstangen', 'lauchstange', 'lauch'],
      'frühlingszwiebel': <String>[
        'frühlingszwiebel',
        'frühlingszwiebeln',
        'lauchzwiebel',
        'lauchzwiebeln',
      ],
      'frühlingszwiebeln': <String>[
        'frühlingszwiebeln',
        'frühlingszwiebel',
        'lauchzwiebel',
        'lauchzwiebeln',
      ],
      'paprika': <String>[
        'paprika',
        'paprikas',
        'paprikaschote',
        'paprikaschoten',
      ],
      'paprikas': <String>[
        'paprikas',
        'paprika',
        'paprikaschote',
        'paprikaschoten',
      ],
      'paprikaschote': <String>[
        'paprikaschote',
        'paprikaschoten',
        'paprika',
      ],
      'paprikaschoten': <String>[
        'paprikaschoten',
        'paprikaschote',
        'paprika',
      ],
      'hackfleisch': <String>[
        'hackfleisch',
        'hack',
        'rinderhackfleisch',
        'gemischtes hackfleisch',
      ],
      'rinderhackfleisch': <String>[
        'rinderhackfleisch',
        'hackfleisch',
        'hack',
      ],
    };
