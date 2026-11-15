import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kochmodus/domain/cook_food_words.dart';

void main() {
  group('cookFoodWords', () {
    test('an accent keeps the word whole', () {
      expect(cookFoodWords('Crème fraîche'), ['creme', 'fraiche']);
      expect(cookFoodWords('CRÈME FRAÎCHE'), ['creme', 'fraiche']);
      expect(cookFoodWords('Jalapeño'), ['jalapeno']);
    });

    test('a German letter stays, as in the shared matcher', () {
      expect(cookFoodWords('Hähnchen Öl Süßkartoffel'), [
        'hähnchen',
        'öl',
        'süßkartoffel',
      ]);
    });
  });

  group('cookNameIsFood', () {
    void expectFood(String said, List<String> names) {
      for (final name in names) {
        expect(cookNameIsFood(name, said), isTrue, reason: '$said on $name');
      }
    }

    void expectNoFood(String said, List<String> names) {
      for (final name in names) {
        expect(cookNameIsFood(name, said), isFalse, reason: '$said on $name');
      }
    }

    group('"Ei" and "Eier"', () {
      const noEgg = [
        'Eis',
        'Reis',
        'Basmatireis',
        'Milchreis',
        'Jasminreis',
        'Weißwein',
        'Rotwein',
        'Schwein',
        'Reisfleisch',
        'Kleinfilet',
        'Salbei',
        'Kartoffelbrei',
      ];

      test('are no food that only holds their letters', () {
        expectNoFood('Ei', noEgg);
        expectNoFood('Eier', noEgg);
      });

      test('are every word for an egg', () {
        const eggs = ['Ei', 'Eier', 'Rührei', 'Bio-Eier', 'Hühnereier'];

        expectFood('Ei', eggs);
        expectFood('Eier', eggs);
      });
    });

    group('"Crème fraîche"', () {
      test('is not the end of a word by a part of it', () {
        expectNoFood('Crème fraîche', [
          'Hähnchen',
          'Kirschen',
          'Würstchen',
          'Pfannkuchen',
        ]);
      });

      test('is the same food with and without accents', () {
        expect(cookNameIsFood('Crème fraîche', 'Creme fraiche'), isTrue);
        expect(cookNameIsFood('Creme fraiche', 'Crème fraîche'), isTrue);
        expect(cookNameIsFood('Crème fraîche', 'Crème fraîche'), isTrue);
      });
    });

    group('a short name inside the long one', () {
      test('counts when a part of the same food follows it', () {
        expectFood('Hack', [
          'Rinderhackfleisch',
          'Schweinehackfleisch',
          'Putenhackfleisch',
        ]);
        expectFood('Hähnchen', [
          'Bio-Hähnchenbrust',
          'Maishähnchenbrust',
          'Bio Hähnchenbrustfilet',
        ]);
        expectFood('Schwein', ['Bio-Schweinefilet', 'Wildschweinkeule']);
      });

      test('counts said the long way on a name of the short way', () {
        expect(cookNameIsFood('Hack', 'Rinderhackfleisch'), isTrue);
        expect(cookNameIsFood('Hähnchen', 'Bio-Hähnchenbrust'), isTrue);
      });

      test('does not count when something else follows it', () {
        expectNoFood('Hack', ['Rinderhackbraten', 'Rinderhackbällchen']);
        expectNoFood('Hähnchen', ['Biohähnchensalat']);
        expectNoFood('Lauch', ['Knoblauchzehen', 'Bärlauchpesto']);
      });
    });

    group('a plural with an umlaut', () {
      test('is the same food, either way round', () {
        expectFood('Apfel', ['Äpfel']);
        expectFood('Äpfel', ['Apfel']);
        expectFood('Nuss', ['Nüsse', 'Walnüsse']);
        expectFood('Nüsse', ['Walnuss']);
        expectFood('Wurst', ['Würste']);
      });

      test('reaches no further than a plural', () {
        expectNoFood('Wurst', ['Würstchen']);
        expectNoFood('Öl', ['Alkohol']);
      });
    });

    group('a food that holds the letters of another by chance', () {
      test('"Wein" is no pork, whatever stands around it', () {
        expectNoFood('Wein', [
          'Schwein',
          'Schweinefilet',
          'Schweinefleisch',
          'Bio-Schweinefilet',
          'Wildschweinkeule',
        ]);
        expectNoFood('Weine', ['Schweinefilet', 'Bio-Schweinefilet']);
        expect(cookNameIsFood('Wein', 'Schweinefilet'), isFalse);
        expect(cookNameIsFood('Wein', 'Bio-Schweinefleisch'), isFalse);
      });

      test('"Wein" stays wine', () {
        expectFood('Wein', ['Wein', 'Weißwein', 'Rotwein']);
      });

      test('"Eis" is no rice', () {
        expectNoFood('Eis', ['Reis', 'Basmatireis', 'Reisfleisch']);
        expectFood('Eis', ['Eis', 'Vanilleeis']);
      });

      test('"Zucker" is no sugar snap pea', () {
        expectNoFood('Zucker', ['Zuckerschoten', 'Bio-Zuckerschoten']);
        expectFood('Zucker', ['Zucker', 'Rohrzucker']);
      });
    });
  });

  group('cookFoodOnlyInsideWord', () {
    test('a food inside a word that is another food', () {
      expect(cookFoodOnlyInsideWord('Wein', 'Schweinefilet'), isTrue);
      expect(cookFoodOnlyInsideWord('Wein', 'Bio-Schweinefilet'), isTrue);
      expect(cookFoodOnlyInsideWord('Wein', 'Schwein'), isTrue);
      expect(cookFoodOnlyInsideWord('Ei', 'Reis'), isTrue);
      expect(cookFoodOnlyInsideWord('Ei', 'Salbei'), isTrue);
    });

    test('a food at the start or the end of a word is not', () {
      expect(cookFoodOnlyInsideWord('Reis', 'Basmatireis'), isFalse);
      expect(cookFoodOnlyInsideWord('Hack', 'Hackfleisch'), isFalse);
    });

    test('a short name with a part of the same food behind it is not', () {
      expect(cookFoodOnlyInsideWord('Hack', 'Rinderhackfleisch'), isFalse);
      expect(cookFoodOnlyInsideWord('Hähnchen', 'Bio-Hähnchenbrust'), isFalse);
    });

    test('nor is a food in a word with accents', () {
      expect(cookFoodOnlyInsideWord('Hähnchen', 'Crème fraîche'), isFalse);
      expect(cookFoodOnlyInsideWord('Creme', 'Crème fraîche'), isFalse);
    });
  });

  group('cookStepNamesFood', () {
    const named = <(String, String)>[
      ('Milch mit Salz aufkochen.', 'Milch'),
      ('Milch mit Salz aufkochen.', 'Salz'),
      ('Milchreis dazugeben und 30 Minuten leise kochen.', 'Milchreis'),
      ('Mit Zucker, Zimt und Zitrone abschmecken.', 'Zucker'),
      ('Mit Zucker, Zimt und Zitrone abschmecken.', 'Zimt'),
      ('Mit Zucker, Zimt und Zitrone abschmecken.', 'Zitrone'),
      ('Mit schwarzem Sesam und rotem Pfeffer bestreuen.', 'Schwarzer Pfeffer'),
      ('Die roten Linsen waschen.', 'rote Linsen'),
      ('Die Zwiebeln schälen und fein hacken.', 'Zwiebel'),
      ('Die Zwiebeln schälen und fein hacken.', 'rote Zwiebel'),
      ('Ein Ei aufschlagen.', 'Eier'),
      ('Die Tomate würfeln.', 'Tomaten'),
      ('Beat the eggs with the milk.', 'eggs'),
      ('Beat the eggs with the milk.', 'milk'),
      // The last part of a hyphenated word is a word of its own.
      ('Die Milch erhitzen.', 'Fettarme H-Milch'),
      // "aus" is a small word of the name, never a cut: the food is named by
      // its own word.
      ('Die Zitrone auspressen.', 'Saft aus 1 Zitrone'),
      ('Die Tomaten dazugeben.', 'Tomaten aus der Dose'),
      // A word of the step that ends a compound of the food names it.
      (
        'Bohnen und Mais dazugeben, weitere 5 Min köcheln, abschmecken.',
        'Kidneybohnen (abgetropft)',
      ),
      ('Die Bohne dazugeben.', 'Kidneybohnen'),
      ('Die Tomaten dazugeben.', 'Kirschtomaten'),
    ];
    for (final (step, food) in named) {
      test('"$step" names "$food"', () {
        expect(cookStepNamesFood(step, food), isTrue);
      });
    }

    const notNamed = <(String, String)>[
      ('Milch mit Salz aufkochen.', 'Milchreis'),
      ('Milchreis dazugeben und 30 Minuten leise kochen.', 'Milch'),
      // A word for a kind alone never counts.
      ('Mit schwarzem Sesam und rotem Pfeffer bestreuen.', 'Schwarzer Tee'),
      ('Die Zwiebeln schälen und fein hacken.', 'Hack'),
      // Only a word of three letters or more is a head; "Ei" ends "Brei".
      ('Ein Ei aufschlagen.', 'Haferbrei'),
      ('Den Reis kochen.', 'Eis'),
      ('Das Hackfleisch in der Pfanne krümelig braten.', 'Schweinebraten'),
      // "aus der Dose" says where the tomatoes come from, not what the step
      // uses.
      (
        'Das Hackfleisch in der Pfanne krümelig braten.',
        'Tomaten aus der Dose',
      ),
    ];
    for (final (step, food) in notNamed) {
      test('"$step" does not name "$food"', () {
        expect(cookStepNamesFood(step, food), isFalse);
      });
    }

    // A line names its food only, not the phrase behind it.
    const byFoodOnly = <(String, String)>[
      ('Das Olivenöl erhitzen.', 'Olivenöl zum Braten'),
      ('Wasser aufsetzen.', 'Wasser zum Kochen'),
      ('Die Tomaten dazugeben.', 'Tomaten aus der Dose'),
      ('Mit Pfeffer abschmecken.', 'Salz und Pfeffer'),
      ('Mit Salz würzen.', 'Salz und Pfeffer nach Belieben'),
      ('Heat the oil.', 'oil for frying'),
      ('Den Saft der Zitrone dazugeben.', 'Saft von 1 Zitrone'),
    ];
    for (final (step, food) in byFoodOnly) {
      test('"$step" names "$food" by its food', () {
        expect(cookStepNamesFood(step, food), isTrue);
      });
    }

    const notByPhrase = <(String, String)>[
      ('Nach 10 Minuten den Zimt unterrühren.', 'Salz nach Geschmack'),
      ('Das Hackfleisch in der Pfanne krümelig braten.', 'Olivenöl zum Braten'),
      ('Das Hackfleisch in der Pfanne krümelig braten.', 'Butter zum Braten'),
      (
        'Das Hackfleisch in der Pfanne krümelig braten.',
        'Tomaten aus der Dose',
      ),
      ('Mit Puderzucker bestäuben.', 'Mehl zum Bestäuben'),
      ('Den Teig mit Mehl bestäuben.', 'Puderzucker zum Bestäuben'),
      ('Die Nudeln in Salzwasser kochen.', 'Wasser zum Kochen'),
      ('Taste and adjust.', 'salt to taste'),
      ('Die Milch aufkochen, den Milchreis einrühren.', 'Öl für die Form'),
      ('Den Topf von der Platte nehmen.', 'Saft von 1 Zitrone'),
      ('Die Form einfetten.', 'Abrieb einer Zitrone'),
    ];
    for (final (step, food) in notByPhrase) {
      test('"$step" does not name "$food" by its phrase or small words', () {
        expect(cookStepNamesFood(step, food), isFalse);
      });
    }

    test('the known limit: "eggs" in the step does not name "egg"', () {
      expect(cookStepNamesFood('Beat the eggs.', 'egg'), isFalse);
    });
  });
}
