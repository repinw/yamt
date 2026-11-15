import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kochmodus/domain/cook_meal_name.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';

const _namedB = CookPot(
  id: 'pot-b',
  name: '  Großer Topf ',
  emptyWeight: 600,
  imageStoragePath: null,
);

void main() {
  group('recipe', () {
    test('without pots it is the recipe name', () {
      final run = buildCookRun();

      expect(
        cookMealName(run, countedMealPotId),
        const CookMealNamePlain('Eintopf'),
      );
    });

    test('with one pot it is the recipe name, whatever the pot is called', () {
      final run = buildCookRun(
        pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
      );

      expect(cookMealName(run, 'pot-a'), const CookMealNamePlain('Eintopf'));
    });

    test('counted is the recipe name', () {
      final run = buildCookRun(pots: const CookCounted());

      expect(
        cookMealName(run, countedMealPotId),
        const CookMealNamePlain('Eintopf'),
      );
    });

    test('with two pots a named pot is added, trimmed', () {
      final run = buildCookRun(
        pots: CookPotsChosen(pots: const [cookPotA, _namedB], inCans: false),
      );

      expect(
        cookMealName(run, 'pot-b'),
        const CookMealNameInPot(recipe: 'Eintopf', pot: 'Großer Topf'),
      );
      expect(
        cookMealName(run, 'pot-a'),
        const CookMealNameInPot(recipe: 'Eintopf', pot: 'Topf'),
      );
    });

    test('with two pots an unnamed pot gets the recipe name alone', () {
      final run = buildCookRun(
        pots: CookPotsChosen(pots: const [cookPotA, cookPotB], inCans: false),
      );

      expect(cookMealName(run, 'pot-b'), const CookMealNamePlain('Eintopf'));
    });

    test('an unknown pot gets the recipe name alone', () {
      final run = buildCookRun(
        pots: CookPotsChosen(pots: const [cookPotA, _namedB], inCans: false),
      );

      expect(cookMealName(run, 'nope'), const CookMealNamePlain('Eintopf'));
    });
  });

  group('free cooking', () {
    const counted = CookCounted();

    test('without a line it is "Frei gekocht"', () {
      expect(
        cookMealName(freeRun(const [], pots: counted), countedMealPotId),
        const CookMealNameFree(),
      );
    });

    test('one line names its food', () {
      final run = freeRun([textLine('a', '200 g Reis')], pots: counted);

      expect(
        cookMealName(run, countedMealPotId),
        const CookMealNamePlain('Reis'),
      );
    });

    test('two or more lines name the first two foods', () {
      final run = freeRun([
        textLine('a', '200 g Reis'),
        textLine('b', '1 Zwiebel'),
        textLine('c', 'Salz'),
      ], pots: counted);

      expect(
        cookMealName(run, countedMealPotId),
        const CookMealNameWith(first: 'Reis', second: 'Zwiebel'),
      );
    });

    test('ignored lines do not count', () {
      final run = freeRun([
        textLine('a', 'Salz', settlement: const LineIgnored()),
        textLine('b', 'Reis'),
      ], pots: counted);

      expect(
        cookMealName(run, countedMealPotId),
        const CookMealNamePlain('Reis'),
      );
    });

    test('names only the lines of that pot', () {
      final run = freeRun([
        textLine('a', 'Reis', potId: 'pot-a'),
        textLine('b', 'Bohnen', potId: 'pot-b'),
        textLine('c', 'Mais', potId: 'pot-b'),
      ], pots: CookPotsChosen(pots: const [cookPotA, cookPotB], inCans: false));

      expect(cookMealName(run, 'pot-a'), const CookMealNamePlain('Reis'));
      expect(
        cookMealName(run, 'pot-b'),
        const CookMealNameWith(first: 'Bohnen', second: 'Mais'),
      );
    });

    test('before the pots are chosen it is "Frei gekocht"', () {
      final run = freeRun([textLine('a', 'Reis')]);

      expect(cookMealName(run, countedMealPotId), const CookMealNameFree());
    });
  });
}
