import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_finish_check.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_view_builder.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../../../recipes/cook_run_fixtures.dart';
import '../../kochmodus_fixtures.dart';

const _pieceWeight = CookLineConversion(
  amountPerPiece: 150,
  unit: TemplateIngredientUnit.gram,
);

KochmodusView _view(
  List<CookRunLine> lines,
  List<InventoryItem> items, {
  Map<String, int> others = const {},
}) => buildKochmodusView(
  run: buildCookRun(
    pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
    lines: lines,
  ),
  saved: true,
  ended: false,
  busy: false,
  reopened: false,
  finished: null,
  tab: null,
  items: items,
  otherReservations: others,
  utensils: const [],
  parser: const TemplateIngredientParser(),
);

KochmodusLineView _line(KochmodusView view, String id) =>
    view.lines.singleWhere((line) => line.id == id);

void main() {
  group('a guessed piece weight', () {
    // The recipe says a piece weighs 150 g: 3 pieces guess 450 g.
    CookRunLine onions(int take) => textLine(
      'a',
      '3 Zwiebeln',
      conversion: _pieceWeight,
      settlement: assigned({'on': take}),
    );

    test('on 400 g of onions is not short and stands under "Noch zu '
        'wiegen"', () {
      final view = _view([onions(400)], [stockItem('on', 400)]);
      final line = _line(view, 'a');

      expect(line.shortBy ?? 0, 0);
      expect(line.weight, const CookWeightEstimated(400, toWeigh: true));
      expect(view.toWeigh.map((line) => line.id), ['a']);
      expect(view.estimatedCount, 1);
    });

    test('takes at most what is there, whatever the guess says', () {
      final onion = stockItem('on', 400);
      final refilled = refillKochmodusTakes(
        buildCookRun(
          lines: [textLine('a', '3 Zwiebeln', conversion: _pieceWeight)],
        ),
        'a',
        const ['on'],
        items: [onion],
        otherReservations: const {},
        parser: const TemplateIngredientParser(),
      );
      final takes = (refilled.lineOf('a')!.settlement as LineAssigned).takes;

      // The guess says 450 g, 400 g are there.
      expect(takes.map((take) => (take.itemId, take.amount)), [('on', 400)]);

      final view = _view(refilled.lines, [onion]);
      expect(_line(view, 'a').shortBy ?? 0, 0);
      expect(view.portion.blocks.whereType<CookStockShort>(), isEmpty);
    });

    test('with nothing left it is short', () {
      final view = _view(
        [onions(450)],
        [stockItem('on', 400)],
        others: const {'on': 400},
      );

      expect(_line(view, 'a').shortBy, isNotNull);
    });

    test('a guessed spoon with nothing left is short, with something left it '
        'is not', () {
      final spoon = textLine(
        'a',
        '1 EL Honig',
        settlement: assigned({'jar': 15}),
      );

      expect(_line(_view([spoon], [stockItem('jar', 8)]), 'a').shortBy, isNull);
      expect(
        _line(
          _view([spoon], [stockItem('jar', 8)], others: const {'jar': 8}),
          'a',
        ).shortBy,
        isNotNull,
      );
    });
  });

  group('a cup, a ladle, a handful', () {
    const cup = CookLineConversion(
      amountPerPiece: 120,
      unit: TemplateIngredientUnit.gram,
    );

    for (final text in ['1 Tasse Reis', '2 Kellen Brühe', '1 Handvoll Nüsse']) {
      test('"$text" with a recipe weight stands under "Noch zu wiegen" on a '
          'food kept in g', () {
        final view = _view(
          [
            textLine(
              'a',
              text,
              conversion: cup,
              settlement: assigned({'g': 120}),
            ),
          ],
          [stockItem('g', 1000)],
        );

        expect(view.toWeigh.map((line) => line.id), ['a'], reason: text);
        expect(_line(view, 'a').shortBy, isNull);
      });
    }

    test('a spoon with a recipe weight stands there too', () {
      final view = _view(
        [
          textLine(
            'a',
            '2 EL Honig',
            conversion: const CookLineConversion(
              amountPerPiece: 15,
              unit: TemplateIngredientUnit.gram,
            ),
            settlement: assigned({'g': 30}),
          ),
        ],
        [stockItem('g', 1000)],
      );

      expect(view.toWeigh.map((line) => line.id), ['a']);
    });
  });

  group('a line that does not count', () {
    test('"Salz nach Geschmack" is neither estimated nor counted', () {
      final view = _view(
        [
          textLine(
            'a',
            'Salz nach Geschmack',
            settlement: assigned({'salt': 3}),
            roughWeight: const CookRoughWeight(
              amount: 3,
              unit: TemplateIngredientUnit.gram,
            ),
          ),
        ],
        [stockItem('salt', 500)],
      );

      expect(view.estimated.map((line) => line.id), isEmpty);
      expect(view.estimatedCount, 0);
      expect(view.toWeigh, isEmpty);
    });
  });

  group('a guessed piece line with a stored take of 0', () {
    test('waits for a weight like a guessed spoon: not short, not ready', () {
      final view = _view(
        [
          textLine(
            'a',
            '3 Zwiebeln',
            conversion: _pieceWeight,
            settlement: assigned({'on': 0}),
          ),
        ],
        [stockItem('on', 400)],
      );
      final line = _line(view, 'a');

      expect(line.shortBy, isNull);
      expect(line.takesNothing, isTrue);
      expect(line.weight, const CookWeightMissing());
      expect(view.unweighed.map((line) => line.id), ['a']);
      expect(view.guessed, isEmpty);
      expect(view.toAnswer.map((line) => line.id), isNot(contains('a')));
      expect(view.portion.blocks.whereType<CookStockShort>(), isEmpty);
      expect(view.portion.blocks, contains(isA<CookLineWithoutTake>()));
    });

    test('with nothing left it is short, not waiting', () {
      final view = _view(
        [
          textLine(
            'a',
            '3 Zwiebeln',
            conversion: _pieceWeight,
            settlement: assigned({'on': 0}),
          ),
        ],
        [stockItem('on', 400)],
        others: const {'on': 400},
      );

      expect(_line(view, 'a').shortBy, isNotNull);
    });
  });

  group('guessed, unweighed and estimatedCount', () {
    final eggs = stockItem(
      'egg',
      3000,
      unit: InventoryAmountUnit.piece,
      scale: 1000,
      servingQuantity: 60,
      servingQuantityUnit: 'g',
    );
    final items = [stockItem('g', 1000), eggs, packItem('pack', 2)];

    test('exact, weighed and ignored lines are not estimated', () {
      final view = _view([
        textLine('a', '100 g Mehl', settlement: assigned({'g': 100})),
        cookLine('b', settlement: assigned({'egg': 1000}), weighed: 60),
        cookLine('c', settlement: const LineIgnored()),
      ], items);

      expect(view.estimatedCount, 0);
      expect(view.guessed, isEmpty);
      expect(view.unweighed, isEmpty);
    });

    test('only a line with an estimated weight is guessed', () {
      // A pack line without a weight and a line that takes 0 g are missing a
      // weight, not estimated.
      final view = _view([
        cookLine('a', settlement: assigned({'egg': 1000})),
        cookLine('b', settlement: assigned({'pack': 1})),
        cookLine('c', settlement: assigned({'g': 0})),
      ], items);

      expect(view.estimatedCount, 1);
      expect(view.guessed.map((line) => line.id), ['a']);
      expect(view.unweighed.map((line) => line.id), isNot(contains('a')));
      expect(
        {...view.guessed, ...view.unweighed}.map((line) => line.id),
        view.estimated.map((line) => line.id).toSet(),
      );
    });

    test('a line that takes nothing is never counted as estimated', () {
      final view = _view([
        textLine('a', '1 EL Senf', settlement: assigned({'pack': 0})),
        textLine('b', '1 Möhre', settlement: assigned({'g': 0})),
      ], items);

      expect(view.estimatedCount, 0);
      expect(view.guessed, isEmpty);
    });

    test('lines that are not assigned are left out', () {
      final view = _view([
        cookLine('a'),
        cookLine('b', settlement: const LineShopping()),
      ], items);

      expect(view.estimatedCount, 0);
      expect(view.estimated, isEmpty);
    });
  });
}
