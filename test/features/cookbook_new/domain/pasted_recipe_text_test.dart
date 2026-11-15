import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/domain/pasted_recipe_text.dart';

const _curry = '''
GERICHT A: HÄHNCHEN-KICHERERBSEN-CURRY MIT BUCHWEIZEN – 2 Portionen (ca. 40 Min)

ZUTATEN
- 400 g Hähnchenbrust
- 1 Zwiebel
- 2 Zehen Knoblauch
- 150 g Paprika
- 150 g Erbsen-Möhren
- 1/2 Dose Kichererbsen (abgetropft, abgespült)
- 1 Dose stückige Tomaten (400 g)
- 100 ml Kokosmilch light
- 2 TL Currypulver, optional 1/2 TL Kreuzkümmel
- 1/2 EL Öl, Salz, Pfeffer
- 140 g Buchweizen (70 g roh/Portion)

SCHRITTE
1. Buchweizen abspülen, mit doppelter Menge Wasser und etwas Salz aufkochen. Deckel drauf, 15 Min auf kleiner Stufe garen, 5 Min ziehen lassen.
2. Zwiebel und Knoblauch fein hacken, Paprika würfeln, Hähnchen in mundgerechte Stücke schneiden.
3. Öl in die Pfanne, Hähnchen bei hoher Hitze 5 Min rundum anbraten, salzen, kurz rausnehmen.
4. Zwiebel und Knoblauch in dieselbe Pfanne, 3 Min braten. Curry (und Kreuzkümmel) dazu, 1 Min mitrösten.
5. Paprika, Erbsen-Möhren, Kichererbsen und Tomaten rein. Aufkochen, 10 Min köcheln.
6. Hähnchen und Kokosmilch dazu, noch 5 Min köcheln, bis das Hähnchen durch ist. Abschmecken.
7. Mit dem Buchweizen auf 2 Dosen verteilen, abkühlen lassen, in den Kühlschrank.

ca. 730 kcal / 62 g Protein pro Portion
''';

void main() {
  group('readPastedRecipe', () {
    test('reads a recipe with headings, a labeled title, and a kcal note', () {
      final read = readPastedRecipe(_curry);

      expect(read.title, 'HÄHNCHEN-KICHERERBSEN-CURRY MIT BUCHWEIZEN');
      expect(read.servings, 2);
      expect(read.ingredients, [
        '400 g Hähnchenbrust',
        '1 Zwiebel',
        '2 Zehen Knoblauch',
        '150 g Paprika',
        '150 g Erbsen-Möhren',
        '1/2 Dose Kichererbsen (abgetropft, abgespült)',
        '1 Dose stückige Tomaten (400 g)',
        '100 ml Kokosmilch light',
        '2 TL Currypulver, optional 1/2 TL Kreuzkümmel',
        '1/2 EL Öl, Salz, Pfeffer',
        '140 g Buchweizen (70 g roh/Portion)',
      ]);
      expect(read.steps, hasLength(7));
      expect(
        read.steps.first,
        'Buchweizen abspülen, mit doppelter Menge Wasser und etwas Salz '
        'aufkochen. Deckel drauf, 15 Min auf kleiner Stufe garen, 5 Min '
        'ziehen lassen.',
      );
      expect(
        read.steps.last,
        'Mit dem Buchweizen auf 2 Dosen verteilen, abkühlen lassen, in den '
        'Kühlschrank.',
      );
      for (final step in read.steps) {
        expect(step, isNot(matches(RegExp(r'^\d+\.'))));
        expect(step, isNot(contains('kcal')));
      }
    });

    test('reads the servings from an ingredients heading', () {
      final read = readPastedRecipe(
        'Zutaten für 4 Personen:\n200 g Mehl\nSalz\n\nZubereitung\nMischen',
      );

      expect(read.servings, 4);
      expect(read.title, isNull);
      expect(read.ingredients, ['200 g Mehl', 'Salz']);
      expect(read.steps, ['Mischen']);
    });

    test('reads English headings', () {
      final read = readPastedRecipe(
        'Pancakes\n\nIngredients\n- 200 g flour\n- 2 eggs\n\n'
        'Instructions\n1) Mix\n2) Fry',
      );

      expect(read.title, 'Pancakes');
      expect(read.ingredients, ['200 g flour', '2 eggs']);
      expect(read.steps, ['Mix', 'Fry']);
    });

    test('without headings, a lone first line is the title', () {
      final read = readPastedRecipe(
        'Pfannkuchen\n\n200 g Mehl\n2 Eier\n\n1. Mischen\n2. Braten',
      );

      expect(read.title, 'Pfannkuchen');
      expect(read.servings, isNull);
      expect(read.ingredients, ['200 g Mehl', '2 Eier']);
      expect(read.steps, ['Mischen', 'Braten']);
    });

    test('without headings, two blocks are ingredients and steps', () {
      final read = readPastedRecipe('200 g Mehl\nSalz\n\nMischen\nBacken\n');

      expect(read.title, isNull);
      expect(read.ingredients, ['200 g Mehl', 'Salz']);
      expect(read.steps, ['Mischen', 'Backen']);
    });

    test('without headings or a gap, all lines are ingredients', () {
      final read = readPastedRecipe('Mehl\nSalz');

      expect(read.title, isNull);
      expect(read.ingredients, ['Mehl', 'Salz']);
      expect(read.steps, isEmpty);
    });

    test('strips bullets from ingredients and numbers from steps', () {
      final read = readPastedRecipe(
        '- Mehl\n• Salz\n▢ Zucker\n\n'
        '1. Mischen\n2) Kneten\n- Backen\n• Essen\n10. Fertig',
      );

      expect(read.ingredients, ['Mehl', 'Salz', 'Zucker']);
      expect(read.steps, ['Mischen', 'Kneten', 'Backen', 'Essen', 'Fertig']);
    });

    test('reads windows line breaks', () {
      final read = readPastedRecipe(
        'Zutaten\r\n- Mehl\r\n- Salz\r\n\r\nSchritte\r\n1. Mischen\r\n'
        '2. Backen\r\n',
      );

      expect(read.ingredients, ['Mehl', 'Salz']);
      expect(read.steps, ['Mischen', 'Backen']);
    });

    group('with an ingredients heading alone', () {
      test('the steps start at the empty line after an ingredient', () {
        final read = readPastedRecipe(
          'Zutaten\n200 g Mehl\n\nDen Teig kneten und backen.',
        );

        expect(read.ingredients, ['200 g Mehl']);
        expect(read.steps, ['Den Teig kneten und backen.']);
      });

      test('an empty line right after the heading changes nothing', () {
        final read = readPastedRecipe('Zutaten\n\n200 g Mehl\n\nKneten.');

        expect(read.ingredients, ['200 g Mehl']);
        expect(read.steps, ['Kneten.']);
      });

      test('an empty line after a sub-heading changes nothing', () {
        final read = readPastedRecipe(
          'Zutaten\nFür den Teig:\n\n200 g Mehl\n\nKneten.',
        );

        expect(read.ingredients, ['200 g Mehl']);
        expect(read.steps, ['Kneten.']);
      });

      test('a second ingredients heading goes back to the ingredients', () {
        final read = readPastedRecipe(
          'Zutaten für den Teig\n200 g Mehl\n\n'
          'Zutaten für die Soße\n1 Becher Sahne\n\nMischen.',
        );

        expect(read.ingredients, ['200 g Mehl', '1 Becher Sahne']);
        expect(read.steps, ['Mischen.']);
      });

      test('a kcal note after the gap is left out', () {
        final read = readPastedRecipe(
          'Zutaten\n200 g Mehl\n\nca. 730 kcal pro Portion',
        );

        expect(read.ingredients, ['200 g Mehl']);
        expect(read.steps, isEmpty);
      });

      test('a kcal note that starts with its number is left out too', () {
        final read = readPastedRecipe(
          'Zutaten\n200 g Mehl\n\n730 kcal pro Portion',
        );

        expect(read.ingredients, ['200 g Mehl']);
        expect(read.steps, isEmpty);
      });

      test('a list spaced with empty lines stays the ingredients', () {
        final read = readPastedRecipe(
          'Tacos\nZutaten:\n\n200 g Mehl\n\n2 Eier\n\n3 EL Öl\n\n'
          'Mix alles zusammen.',
        );

        expect(read.title, 'Tacos');
        expect(read.ingredients, ['200 g Mehl', '2 Eier', '3 EL Öl']);
        expect(read.steps, ['Mix alles zusammen.']);
      });

      test('a second sub-heading after a gap goes on with the ingredients', () {
        final read = readPastedRecipe(
          'Zutaten\nFür den Teig:\n200 g Mehl\n\nFür die Füllung:\n'
          '1 Becher Sahne\n\nMischen.',
        );

        expect(read.ingredients, ['200 g Mehl', '1 Becher Sahne']);
        expect(read.steps, ['Mischen.']);
      });

      test('numbered lines after the gap are the steps', () {
        for (final (first, second) in [
          ('1. Mischen', '2. Backen'),
          ('1) Mischen', '2) Backen'),
        ]) {
          final read = readPastedRecipe(
            'Zutaten\n200 g Mehl\n2 Eier\n\n$first\n$second',
          );

          expect(read.ingredients, ['200 g Mehl', '2 Eier'], reason: first);
          expect(read.steps, ['Mischen', 'Backen'], reason: first);
        }
      });

      test('a decimal amount after the gap stays an ingredient', () {
        final read = readPastedRecipe(
          'Zutaten\n200 g Mehl\n\n1.5 l Milch\n\nMischen.',
        );

        expect(read.ingredients, ['200 g Mehl', '1.5 l Milch']);
        expect(read.steps, ['Mischen.']);
      });
    });

    test('with both headings, a gap among the ingredients stays there', () {
      final read = readPastedRecipe(
        'Zutaten\n200 g Mehl\n\nSalz\n\nZubereitung\nMischen',
      );

      expect(read.ingredients, ['200 g Mehl', 'Salz']);
      expect(read.steps, ['Mischen']);
    });

    group('a title that starts with a digit', () {
      test('is a title when no amount follows the digit', () {
        for (final title in [
          '5-Minuten-Salat',
          '30-Minuten-Curry',
          '1-Topf-Pasta',
        ]) {
          final read = readPastedRecipe(
            '$title\n\n200 g Tomaten\n1 Gurke\n\nAlles mischen.',
          );

          expect(read.title, title);
          expect(read.ingredients, ['200 g Tomaten', '1 Gurke']);
          expect(read.steps, ['Alles mischen.']);
        }
      });

      test('an amount range stays an ingredient', () {
        final read = readPastedRecipe('2-3 Eier\n\n1 Prise Salz\n\nMischen');

        expect(read.title, isNull);
        expect(read.ingredients, ['2-3 Eier']);
        expect(read.steps, ['1 Prise Salz', 'Mischen']);
      });
    });

    group('sub-headings among the ingredients', () {
      test('are left out, with or without a bullet', () {
        final read = readPastedRecipe(
          'Zutaten\nFür den Teig:\n200 g Mehl\n- Für die Soße:\n'
          '- 1 Becher Sahne\nZubereitung\nMischen.',
        );

        expect(read.ingredients, ['200 g Mehl', '1 Becher Sahne']);
        expect(read.steps, ['Mischen.']);
      });

      test('are left out without headings too', () {
        final read = readPastedRecipe('Teig:\n200 g Mehl\n\nKneten.');

        expect(read.ingredients, ['200 g Mehl']);
        expect(read.steps, ['Kneten.']);
      });

      test('a line with a digit or text after the colon stays', () {
        final read = readPastedRecipe(
          'Zutaten\nFür 2 Personen:\nZum Bestreuen: Puderzucker\n'
          'Zubereitung\nMischen.',
        );

        expect(read.ingredients, [
          'Für 2 Personen:',
          'Zum Bestreuen: Puderzucker',
        ]);
      });
    });

    group('heading lines', () {
      test('a step that starts with a heading word stays a step', () {
        final read = readPastedRecipe(
          'Zutaten\n200 g Mehl\nZubereitung\nZutaten vermengen\n'
          'Zutaten formen\nIm Ofen backen',
        );

        expect(read.ingredients, ['200 g Mehl']);
        expect(read.steps, [
          'Zutaten vermengen',
          'Zutaten formen',
          'Im Ofen backen',
        ]);
      });

      test('a time line is no steps heading', () {
        final german = readPastedRecipe(
          'Kuchen\nZubereitung: 30 Minuten\n4 Portionen\n\n'
          'Zutaten\n200 g Mehl\n\nSchritte\nMischen',
        );

        expect(german.title, 'Kuchen');
        expect(german.servings, 4);
        expect(german.ingredients, ['200 g Mehl']);
        expect(german.steps, ['Mischen']);

        final english = readPastedRecipe(
          'Pancakes\nPreparation time: 15 minutes\nCook time: 30 minutes\n'
          '4 servings\n\nIngredients\n- flour\n\nMethod\nMix',
        );

        expect(english.title, 'Pancakes');
        expect(english.servings, 4);
        expect(english.ingredients, ['flour']);
        expect(english.steps, ['Mix']);
      });

      test('every ingredients heading ending still counts', () {
        for (final heading in [
          'Zutaten',
          'ZUTATEN:',
          'Zutatenliste',
          'Einkaufsliste',
          'Zutaten für 4 Personen:',
          'Zutaten (für 4 Personen)',
          'Zutaten – 2 Portionen',
          'Zutaten 2 Portionen',
          'Ingredients for 4',
          'Zutaten Teig:',
          'Ingredients list:',
        ]) {
          final read = readPastedRecipe('$heading\nMehl\nZubereitung\nMischen');

          expect(read.ingredients, ['Mehl'], reason: heading);
          expect(read.steps, ['Mischen'], reason: heading);
        }
      });

      test('ingredients under named headings stay before a steps heading', () {
        final german = readPastedRecipe(
          'Lasagne\nZutaten Teig:\n200 g Mehl\nZutaten Füllung:\n100 g Hack\n\n'
          'Zubereitung:\nBacken.',
        );

        expect(german.title, 'Lasagne');
        expect(german.ingredients, ['200 g Mehl', '100 g Hack']);
        expect(german.steps, ['Backen.']);

        final english = readPastedRecipe(
          'Soup\nIngredients list:\n200 g flour\n\nMethod:\nMix.',
        );

        expect(english.title, 'Soup');
        expect(english.ingredients, ['200 g flour']);
        expect(english.steps, ['Mix.']);
      });

      test('a named ingredients heading is no title', () {
        final read = readPastedRecipe(
          'Zutaten Teig:\n200 g Mehl\nZubereitung:\nBacken.',
        );

        expect(read.title, isNull);
        expect(read.ingredients, ['200 g Mehl']);
      });

      test('a time label alone on a line is no steps heading', () {
        final read = readPastedRecipe(
          'Pancakes\nPreparation time:\n15 minutes\nServes 4\n\n'
          'Ingredients\n- flour\n\nMethod\nMix',
        );

        expect(read.title, 'Pancakes');
        expect(read.servings, 4);
        expect(read.ingredients, ['flour']);
        expect(read.steps, ['Mix']);
      });

      test('every steps heading still counts', () {
        for (final heading in [
          'Zubereitung',
          'Zubereitung:',
          'Zubereitungsschritte',
          'Schritte',
          'Arbeitsschritte',
          'Anleitung',
          'Anweisungen',
          "So geht's",
          'Instructions',
          'Steps',
          'Steps:',
          'Directions',
          'Method',
          'Preparation',
          'Preparation method',
          'Preparation steps',
          'Zubereitung (30 Min)',
        ]) {
          final read = readPastedRecipe(
            'Zutaten\nMehl\n\n$heading\n1. Mischen',
          );

          expect(read.ingredients, ['Mehl'], reason: heading);
          expect(read.steps, ['Mischen'], reason: heading);
        }
      });

      test('reads a steps heading in English after a bulleted list', () {
        final read = readPastedRecipe(
          'Pancakes\n\nIngredients\n- 200 g flour\n- 2 eggs\n\n'
          'Steps\n1. Mix\n2. Fry',
        );

        expect(read.title, 'Pancakes');
        expect(read.ingredients, ['200 g flour', '2 eggs']);
        expect(read.steps, ['Mix', 'Fry']);
      });
    });

    group('step numbers', () {
      test('a decimal amount at the start of a step stays whole', () {
        final read = readPastedRecipe(
          'Zutaten\nWasser\nZubereitung\n1.5 l Wasser aufkochen.\n1. Mischen\n'
          '12.5 Min köcheln.\n10. Fertig',
        );

        expect(read.steps, [
          '1.5 l Wasser aufkochen.',
          'Mischen',
          '12.5 Min köcheln.',
          'Fertig',
        ]);
      });

      test('a number without a space before the text still goes', () {
        final read = readPastedRecipe(
          'Zutaten\nWasser\nZubereitung\n1.Mischen\n2. 5 l Wasser dazu',
        );

        expect(read.steps, ['Mischen', '5 l Wasser dazu']);
      });

      test('a decimal kcal note is left out', () {
        final read = readPastedRecipe(
          'Zutaten\nWasser\nZubereitung\nMischen\n730.5 kcal pro Portion',
        );

        expect(read.steps, ['Mischen']);
      });
    });

    group('portions', () {
      test('reads the number on either side of the word', () {
        const cases = {
          'Brot – 2 Portionen 30 Min': 2,
          'Zutaten für 4 Personen:': 4,
          'Serves 4': 4,
          'Servings: 4': 4,
          'Ingredients (serves 4)': 4,
          'Portionen: 6': 6,
          'Yield: 8': 8,
          'Yields 8': 8,
          '6 Portionen': 6,
        };
        for (final MapEntry(key: line, value: servings) in cases.entries) {
          final read = readPastedRecipe('Brot\n$line\nZutaten\nMehl');

          expect(read.servings, servings, reason: line);
        }
      });

      test('a longer word that holds the word is no portions', () {
        final read = readPastedRecipe('Brot\nProportion 2\nZutaten\nMehl');

        expect(read.servings, isNull);
      });
    });

    group('the title', () {
      test('keeps a dish name before a colon', () {
        final read = readPastedRecipe(
          'Kürbissuppe: schnell und einfach\nZutaten\nMehl',
        );

        expect(read.title, 'Kürbissuppe: schnell und einfach');
      });

      test('loses a known label', () {
        for (final label in ['Rezept', 'recipe', 'GERICHT', 'Gericht A']) {
          final read = readPastedRecipe('$label: Brot\nZutaten\nMehl');

          expect(read.title, 'Brot', reason: label);
        }
      });

      test('is no line with nothing but the portions', () {
        for (final (line, servings) in [
          ('Für 4 Personen', 4),
          ('4 Portionen', 4),
          ('For 2 servings:', 2),
          ('Serves 4', 4),
          ('Portionen: 6', 6),
        ]) {
          final read = readPastedRecipe('$line\nZutaten\n200 g Mehl');

          expect(read.title, isNull, reason: line);
          expect(read.servings, servings, reason: line);
          expect(read.ingredients, ['200 g Mehl'], reason: line);
        }
      });

      test('is the next line after a line with nothing but the portions', () {
        final read = readPastedRecipe('4 Portionen\nBrot\nZutaten\nMehl');

        expect(read.title, 'Brot');
        expect(read.servings, 4);
      });

      test('is no portions line without headings either', () {
        final read = readPastedRecipe(
          'Für 4 Personen\n\n200 g Mehl\n\n1. Mischen',
        );

        expect(read.title, isNull);
        expect(read.servings, 4);
        expect(read.ingredients, ['200 g Mehl']);
        expect(read.steps, ['Mischen']);
      });
    });
  });
}
