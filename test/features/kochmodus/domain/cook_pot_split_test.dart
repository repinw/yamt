import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kochmodus/domain/cook_pot_split.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';

List<String> _ids(Map<String, List<CookRunLine>> split, String key) => [
  for (final line in split[key]!) line.id,
];

void main() {
  group('cookLinesByPot', () {
    test('is empty until the pots are chosen', () {
      final run = buildCookRun(lines: [cookLine('a')]);

      expect(cookLinesByPot(run), isEmpty);
    });

    test('counted puts every line but the ignored ones under counted', () {
      final run = buildCookRun(
        pots: const CookCounted(),
        lines: [
          cookLine('a'),
          cookLine('b', settlement: const LineIgnored()),
          cookLine('c', potId: 'pot-a'),
        ],
      );

      final split = cookLinesByPot(run);

      expect(split.keys, [countedMealPotId]);
      expect(_ids(split, countedMealPotId), ['a', 'c']);
    });

    test('one pot takes all lines, even with a foreign potId', () {
      final run = buildCookRun(
        pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
        lines: [
          cookLine('a'),
          cookLine('b', potId: 'pot-zzz'),
          cookLine('c', settlement: const LineIgnored()),
        ],
      );

      expect(_ids(cookLinesByPot(run), 'pot-a'), ['a', 'b']);
    });

    test('two pots split by potId; the rest goes to the first pot', () {
      final run = buildCookRun(
        pots: CookPotsChosen(pots: const [cookPotA, cookPotB], inCans: false),
        lines: [
          cookLine('a', potId: 'pot-b'),
          cookLine('b'),
          cookLine('c', potId: 'pot-a'),
          cookLine('d', potId: 'gone-pot'),
          cookLine('e', potId: 'pot-b', settlement: const LineIgnored()),
        ],
      );

      final split = cookLinesByPot(run);

      expect(split.keys, ['pot-a', 'pot-b']);
      expect(_ids(split, 'pot-a'), ['b', 'c', 'd']);
      expect(_ids(split, 'pot-b'), ['a']);
    });

    test('a pot without lines keeps an empty entry', () {
      final run = buildCookRun(
        pots: CookPotsChosen(pots: const [cookPotA, cookPotB], inCans: false),
        lines: [cookLine('a', potId: 'pot-a')],
      );

      expect(cookLinesByPot(run)['pot-b'], isEmpty);
    });

    test('keeps the order of the lines inside a pot', () {
      final run = freeRun([
        textLine('z', 'Zwiebel'),
        textLine('a', 'Apfel'),
      ], pots: const CookCounted());

      expect(_ids(cookLinesByPot(run), countedMealPotId), ['z', 'a']);
    });
  });
}
