import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_takes.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';

TemplateIngredientRequirement? _grams(int amount) =>
    TemplateIngredientRequirement(
      amount: amount,
      unit: TemplateIngredientUnit.gram,
      name: 'Zutat',
    );

Map<String, int> _takes(List<ItemTake> takes) => {
  for (final take in takes) take.itemId: take.amount,
};

void main() {
  List<ItemTake> takes({
    required List<InventoryItem> items,
    TemplateIngredientRequirement? need,
    CookRunLine? line,
    List<CookRunLine> others = const [],
    Map<String, int> reserved = const {},
  }) {
    final own = line ?? cookLine('own');
    return cookTakesFor(
      run: buildCookRun(lines: [own, ...others]),
      line: own,
      need: need,
      items: items,
      otherReservations: reserved,
    );
  }

  group('cookTakesFor', () {
    test('no items give no takes', () {
      expect(takes(items: const [], need: _grams(100)), isEmpty);
    });

    test('one item that holds enough gives the need', () {
      final result = takes(items: [stockItem('a', 500)], need: _grams(200));

      expect(_takes(result), {'a': 200});
    });

    test('fills in the order of the items, the rest stays with 0', () {
      final result = takes(
        items: [stockItem('a', 100), stockItem('b', 500), stockItem('c', 500)],
        need: _grams(250),
      );

      expect(result.map((take) => take.itemId), ['a', 'b', 'c']);
      expect(_takes(result), {'a': 100, 'b': 150, 'c': 0});
    });

    test('an item not needed now fills again when the need rises', () {
      final items = [stockItem('a', 300), stockItem('b', 500)];
      CookRunLine from(List<ItemTake> taken) =>
          cookLine('own', settlement: LineAssigned(taken));

      final full = takes(items: items, need: _grams(400));
      final less = takes(items: items, need: _grams(200), line: from(full));
      final again = takes(items: items, need: _grams(400), line: from(less));

      expect(_takes(full), {'a': 300, 'b': 100});
      expect(_takes(less), {'a': 200, 'b': 0});
      expect(_takes(again), {'a': 300, 'b': 100});
    });

    test('keeps the order of the items, not of the amounts', () {
      final result = takes(
        items: [stockItem('big', 500), stockItem('small', 50)],
        need: _grams(100),
      );

      expect(_takes(result), {'big': 100, 'small': 0});
    });

    test('reservations of other runs reduce what an item offers', () {
      final result = takes(
        items: [stockItem('a', 300), stockItem('b', 300)],
        need: _grams(250),
        reserved: {'a': 200},
      );

      expect(_takes(result), {'a': 100, 'b': 150});
    });

    test('takes of other lines reduce what an item offers', () {
      final result = takes(
        items: [stockItem('a', 300), stockItem('b', 300)],
        need: _grams(250),
        others: [
          cookLine('other', settlement: assigned({'a': 250})),
        ],
      );

      expect(_takes(result), {'a': 50, 'b': 200});
    });

    test('the takes of the line itself do not reduce what it may take', () {
      final own = cookLine('own', settlement: assigned({'a': 200}));

      final result = takes(
        items: [stockItem('a', 200)],
        need: _grams(200),
        line: own,
      );

      expect(_takes(result), {'a': 200});
    });

    test('both reservations and other lines count together', () {
      final result = takes(
        items: [stockItem('a', 300), stockItem('b', 300)],
        need: _grams(200),
        reserved: {'a': 100},
        others: [
          cookLine('other', settlement: assigned({'a': 100})),
        ],
      );

      expect(_takes(result), {'a': 100, 'b': 100});
    });

    test('short stock gives what there is, less than the need', () {
      final result = takes(
        items: [stockItem('a', 100), stockItem('b', 50)],
        need: _grams(500),
      );

      expect(_takes(result), {'a': 100, 'b': 50});
    });

    test('an item with nothing left gives nothing and stays with 0', () {
      final result = takes(
        items: [stockItem('a', 100), stockItem('b', 100)],
        need: _grams(100),
        reserved: {'a': 100},
      );

      expect(_takes(result), {'a': 0, 'b': 100});
    });

    test('nothing available keeps every item with 0', () {
      final result = takes(
        items: [stockItem('a', 100), stockItem('b', 100)],
        need: _grams(100),
        reserved: {'a': 100, 'b': 100},
      );

      expect(_takes(result), {'a': 0, 'b': 0});
    });

    test('a line without a need keeps its items with 0', () {
      final result = takes(items: [stockItem('a', 100), stockItem('b', 100)]);

      expect(_takes(result), {'a': 0, 'b': 0});
    });

    test('a line without a need keeps out what is kept another way', () {
      final result = takes(items: [stockItem('a', 100), packItem('pack', 2)]);

      expect(_takes(result), {'a': 0});
    });

    test('spoons take a standard spoon of the first item a weight can fill, '
        'whole packs stay with 0', () {
      const spoons = TemplateIngredientRequirement(
        amount: 1,
        unit: TemplateIngredientUnit.piece,
        name: 'Öl',
        countMeasureLabel: 'EL',
        allowsDirectPieceInventoryMatch: false,
      );

      expect(
        _takes(
          takes(
            items: [stockItem('a', 100), stockItem('b', 100)],
            need: spoons,
          ),
        ),
        {'a': 15, 'b': 0},
      );
      expect(
        _takes(
          takes(items: [packItem('p', 1), packItem('q', 1)], need: spoons),
        ),
        {'p': 0},
      );
    });

    group('unit and scale', () {
      final pieces = [
        stockItem('pc', 6000, unit: InventoryAmountUnit.piece, scale: 1000),
        stockItem('pc2', 6000, unit: InventoryAmountUnit.piece, scale: 1000),
      ];

      test('an ml item fills grams like a gram item, 1:1', () {
        final result = takes(
          items: [
            stockItem('a', 100),
            stockItem('ml', 500, unit: InventoryAmountUnit.milliliter),
            stockItem('b', 500),
          ],
          need: _grams(300),
        );

        expect(_takes(result), {'a': 100, 'ml': 200, 'b': 0});
      });

      test('an item that cannot supply the need does not fill it', () {
        final result = takes(
          items: [stockItem('a', 100), pieces.first, stockItem('b', 500)],
          need: _grams(300),
        );

        expect(_takes(result), {'a': 100, 'b': 200});
      });

      test('an item that cannot supply, placed first, does not block', () {
        final result = takes(
          items: [pieces.first, stockItem('a', 100), stockItem('b', 500)],
          need: _grams(300),
        );

        expect(_takes(result), {'a': 100, 'b': 200});
      });

      test('only items that cannot supply keep the first item with 0', () {
        final result = takes(items: pieces, need: _grams(300));

        expect(_takes(result), {'pc': 0});
      });

      test('an ml item placed first supplies the whole need', () {
        final result = takes(
          items: [
            stockItem('ml', 500, unit: InventoryAmountUnit.milliliter),
            stockItem('a', 100),
          ],
          need: _grams(300),
        );

        expect(_takes(result), {'ml': 300, 'a': 0});
      });

      test('items counted whole do not fill grams', () {
        final result = takes(
          items: [stockItem('a', 100), packItem('pack', 3)],
          need: _grams(300),
        );

        expect(_takes(result), {'a': 100});
      });

      test('pieces in another scale than the first item do not fill', () {
        final result = takes(
          items: [
            stockItem('a', 1000, unit: InventoryAmountUnit.piece, scale: 1000),
            packItem('pack', 5),
          ],
          need: const TemplateIngredientRequirement(
            amount: 3,
            unit: TemplateIngredientUnit.piece,
            name: 'Eier',
          ),
        );

        expect(_takes(result), {'a': 1000});
      });

      test('pieces fill in their scale of a thousand', () {
        final result = takes(
          items: [
            stockItem('a', 2000, unit: InventoryAmountUnit.piece, scale: 1000),
            stockItem('b', 4000, unit: InventoryAmountUnit.piece, scale: 1000),
          ],
          need: const TemplateIngredientRequirement(
            amount: 3,
            unit: TemplateIngredientUnit.piece,
            name: 'Eier',
          ),
        );

        expect(_takes(result), {'a': 2000, 'b': 1000});
      });

      test('pieces from gram items use the line piece weight', () {
        final line = cookLine(
          'own',
          conversion: const CookLineConversion(
            amountPerPiece: 60,
            unit: TemplateIngredientUnit.gram,
          ),
        );

        final result = takes(
          items: [stockItem('a', 1000)],
          need: const TemplateIngredientRequirement(
            amount: 3,
            unit: TemplateIngredientUnit.piece,
            name: 'Eier',
          ),
          line: line,
        );

        expect(_takes(result), {'a': 180});
      });
    });

    group('items added by search', () {
      test('take the need capped by the stock, never the entered amount', () {
        final line = cookLine(
          'own',
          settlement: assigned({'added': 500}),
          addedItemIds: const ['added'],
        );

        final result = takes(
          items: [stockItem('added', 500)],
          need: _grams(250),
          line: line,
        );

        expect(_takes(result), {'added': 250});
      });

      test('the found item fills first, the other fills what is left', () {
        final line = cookLine(
          'own',
          settlement: assigned({'a': 200}),
          addedItemIds: const ['added'],
        );

        final result = takes(
          items: [stockItem('added', 150), stockItem('a', 500)],
          need: _grams(200),
          line: line,
        );

        expect(_takes(result), {'added': 150, 'a': 50});
      });

      test('follow the need when it changes', () {
        final line = cookLine(
          'own',
          settlement: assigned({'added': 50}),
          addedItemIds: const ['added'],
        );

        final result = takes(
          items: [stockItem('added', 500)],
          need: _grams(400),
          line: line,
        );

        expect(_takes(result), {'added': 400});
      });

      test('that cover the need leave the other items at 0', () {
        final line = cookLine(
          'own',
          settlement: assigned({'added': 200}),
          addedItemIds: const ['added'],
        );

        final result = takes(
          items: [stockItem('added', 500), stockItem('a', 500)],
          need: _grams(150),
          line: line,
        );

        expect(_takes(result), {'added': 150, 'a': 0});
      });

      test('never take more than the need together', () {
        final line = cookLine('own', addedItemIds: const ['added']);

        final result = takes(
          items: [
            stockItem('added', 120),
            stockItem('a', 500),
            stockItem('b', 500),
          ],
          need: _grams(300),
          line: line,
        );

        expect(result.map((take) => take.amount).reduce((a, b) => a + b), 300);
      });

      test('come out in the order of the items', () {
        final line = cookLine(
          'own',
          settlement: assigned({'added': 50}),
          addedItemIds: const ['added'],
        );

        final result = takes(
          items: [stockItem('added', 500), stockItem('a', 500)],
          need: _grams(200),
          line: line,
        );

        expect(result.map((take) => take.itemId), ['added', 'a']);
      });

      test('are chosen like any item while the line is not assigned', () {
        final line = cookLine('own', addedItemIds: const ['added']);

        final result = takes(
          items: [stockItem('added', 500)],
          need: _grams(200),
          line: line,
        );

        expect(_takes(result), {'added': 200});
      });

      test('that cannot supply the line keep a take of 0 beside the food '
          'that fills the need', () {
        final line = cookLine(
          'own',
          settlement: assigned({'pc': 1000}),
          addedItemIds: const ['pc'],
        );

        final result = takes(
          items: [
            stockItem('pc', 6000, unit: InventoryAmountUnit.piece, scale: 1000),
            stockItem('a', 500),
          ],
          need: _grams(200),
          line: line,
        );

        expect(_takes(result), {'a': 200, 'pc': 0});
      });

      test('in ml count 1:1 and fill the need in grams', () {
        final line = cookLine(
          'own',
          settlement: assigned({'ml': 100}),
          addedItemIds: const ['ml'],
        );

        final result = takes(
          items: [
            stockItem('ml', 500, unit: InventoryAmountUnit.milliliter),
            stockItem('a', 500),
          ],
          need: _grams(200),
          line: line,
        );

        expect(_takes(result), {'ml': 200, 'a': 0});
      });

      test('follow the own amount when the other items take nothing', () {
        final line = cookLine(
          'own',
          amount: 100,
          settlement: assigned({'added': 200, 'a': 0}),
          addedItemIds: const ['added'],
        );

        expect(
          _takes(
            takes(
              items: [stockItem('added', 200), stockItem('a', 500)],
              need: _grams(100),
              line: line,
            ),
          ),
          {'added': 100, 'a': 0},
        );
        expect(
          _takes(
            takes(
              items: [stockItem('added', 200), stockItem('a', 500)],
              need: _grams(300),
              line: line,
            ),
          ),
          {'added': 200, 'a': 100},
        );
      });

      test('a take of an item no longer listed is dropped', () {
        final line = cookLine(
          'own',
          settlement: assigned({'added': 50}),
          addedItemIds: const ['added'],
        );

        final result = takes(
          items: [stockItem('a', 500)],
          need: _grams(200),
          line: line,
        );

        expect(_takes(result), {'a': 200});
      });
    });
  });

  group('cookTakesFor with a weight', () {
    CookRunLine weighedLine({
      String id = 'own',
      Map<String, int>? taken,
      int weighed = 30,
      int? amount,
      List<String> added = const [],
    }) => cookLine(
      id,
      settlement: assigned(taken ?? {'a': 100}),
      weighed: weighed,
      amount: amount,
      addedItemIds: added,
    );

    test('takes the weighed amount instead of the need', () {
      final result = takes(
        items: [stockItem('a', 500)],
        need: _grams(100),
        line: weighedLine(),
      );

      expect(_takes(result), {'a': 30});
    });

    test('the weight beats the cook amount', () {
      final result = takes(
        items: [stockItem('a', 500)],
        need: _grams(400),
        line: weighedLine(amount: 400),
      );

      expect(_takes(result), {'a': 30});
    });

    test('works without a need at all', () {
      final result = takes(items: [stockItem('a', 500)], line: weighedLine());

      expect(_takes(result), {'a': 30});
    });

    test('is not capped at what the item has: the stock check says so', () {
      final result = takes(
        items: [stockItem('a', 20)],
        need: _grams(100),
        line: weighedLine(),
      );

      expect(_takes(result), {'a': 30});
    });

    test('what the items cannot hold goes onto the last one', () {
      final result = takes(
        items: [stockItem('a', 20), stockItem('b', 30)],
        line: weighedLine(weighed: 100),
      );

      expect(_takes(result), {'a': 20, 'b': 80});
    });

    test('an item with nothing left still takes the weight', () {
      final result = takes(
        items: [stockItem('a', 0, initial: 100)],
        line: weighedLine(),
      );

      expect(_takes(result), {'a': 30});
    });

    test('fills in the order of the items', () {
      final result = takes(
        items: [stockItem('a', 20), stockItem('b', 500)],
        line: weighedLine(weighed: 50),
      );

      expect(_takes(result), {'a': 20, 'b': 30});
    });

    test('items that are not needed stay at 0', () {
      final result = takes(
        items: [stockItem('a', 500), stockItem('b', 500)],
        line: weighedLine(),
      );

      expect(result.map((take) => take.itemId), ['a', 'b']);
      expect(_takes(result), {'a': 30, 'b': 0});
    });

    test('reservations of other runs do not limit a weight', () {
      final result = takes(
        items: [stockItem('a', 300), stockItem('b', 300)],
        line: weighedLine(weighed: 150),
        reserved: {'a': 200},
      );

      expect(_takes(result), {'a': 150, 'b': 0});
    });

    test('takes of other lines reduce what an item offers', () {
      final result = takes(
        items: [stockItem('a', 100), stockItem('b', 500)],
        line: weighedLine(weighed: 60),
        others: [
          cookLine('other', settlement: assigned({'a': 80})),
        ],
      );

      expect(_takes(result), {'a': 20, 'b': 40});
    });

    test('added items follow the weight like the rest', () {
      final result = takes(
        items: [stockItem('a', 500), stockItem('added', 500)],
        line: weighedLine(
          taken: {'a': 100, 'added': 300},
          weighed: 40,
          added: const ['added'],
        ),
      );

      expect(_takes(result), {'a': 40, 'added': 0});
    });

    test('items in grams and ml fill together', () {
      final result = takes(
        items: [
          stockItem('a', 20),
          stockItem('ml', 500, unit: InventoryAmountUnit.milliliter),
        ],
        line: weighedLine(weighed: 50),
      );

      expect(_takes(result), {'a': 20, 'ml': 30});
    });

    test('a piece item keeps the take of the need, never 0', () {
      final onion = stockItem(
        'onion',
        6000,
        unit: InventoryAmountUnit.piece,
        scale: 1000,
      );
      final line = cookLine(
        'own',
        settlement: assigned({'onion': 1000}),
        weighed: 180,
      );

      final result = takes(
        items: [onion],
        need: const TemplateIngredientRequirement(
          amount: 1,
          unit: TemplateIngredientUnit.piece,
          name: 'Zwiebel',
        ),
        line: line,
      );

      expect(_takes(result), {'onion': 1000});
    });

    test('a piece item next to a gram item keeps the take of the need', () {
      final result = takes(
        items: [
          stockItem('a', 500),
          stockItem(
            'piece',
            6000,
            unit: InventoryAmountUnit.piece,
            scale: 1000,
          ),
        ],
        need: _grams(100),
        line: weighedLine(),
      );

      expect(_takes(result)['a'], 100);
    });

    test('without a weight it takes the need as before', () {
      final result = takes(
        items: [stockItem('a', 500)],
        need: _grams(100),
        line: cookLine('own', settlement: assigned({'a': 100})),
      );

      expect(_takes(result), {'a': 100});
    });
  });

  group('cookReservedFor and cookAvailableFor', () {
    test('count the other runs and the other lines, not the own take', () {
      final own = cookLine('own', settlement: assigned({'a': 200}));
      final other = cookLine('other', settlement: assigned({'a': 100}));
      final run = buildCookRun(lines: [own, other]);
      final item = stockItem('a', 500);

      expect(cookReservedFor(run, own, item, const {'a': 50}), 150);
      expect(cookAvailableFor(run, own, item, const {'a': 50}), 350);
      expect(cookReservedFor(run, own, stockItem('zz', 500), const {}), 0);
    });

    test('a take above the whole stock does not count for the others', () {
      final own = cookLine('own', settlement: assigned({'a': 15}));
      final above = cookLine('above', settlement: assigned({'a': 300}));
      final within = cookLine('within', settlement: assigned({'a': 40}));
      final item = stockItem('a', 100);

      expect(
        cookAvailableFor(
          buildCookRun(lines: [own, above]),
          own,
          item,
          const {},
        ),
        100,
      );
      expect(
        cookAvailableFor(
          buildCookRun(lines: [own, above, within]),
          own,
          item,
          const {},
        ),
        60,
      );
    });

    test('never go below 0', () {
      final own = cookLine('own');
      final run = buildCookRun(lines: [own]);

      expect(
        cookAvailableFor(run, own, stockItem('a', 100), const {'a': 400}),
        0,
      );
    });
  });

  group('cookLineAvailable', () {
    int? available({
      required List<InventoryItem> items,
      TemplateIngredientRequirement? need,
      CookRunLine? line,
      List<CookRunLine> others = const [],
      Map<String, int> reserved = const {},
    }) {
      final own = line ?? cookLine('own');
      return cookLineAvailable(
        buildCookRun(lines: [own, ...others]),
        own,
        need ?? _grams(100),
        items,
        reserved,
      );
    }

    test('a line with no items has nothing to name', () {
      expect(available(items: const []), isNull);
    });

    test('one item gives its whole stock, more than the line needs', () {
      expect(available(items: [stockItem('a', 500)], need: _grams(400)), 500);
    });

    test('several items add up', () {
      expect(available(items: [stockItem('a', 300), stockItem('b', 200)]), 500);
    });

    test('other runs reserve their share', () {
      expect(
        available(
          items: [stockItem('a', 500), stockItem('b', 200)],
          reserved: const {'a': 150},
        ),
        550,
      );
    });

    test(
      'the other lines of the run take their share, the line itself not',
      () {
        final own = cookLine('own', settlement: assigned({'a': 300}));
        final other = cookLine('other', settlement: assigned({'a': 100}));

        expect(
          available(items: [stockItem('a', 500)], line: own, others: [other]),
          400,
        );
      },
    );

    test('an item that is reserved away counts 0, not below', () {
      expect(
        available(
          items: [stockItem('a', 100), stockItem('b', 50)],
          reserved: const {'a': 400},
        ),
        50,
      );
      expect(
        available(items: [stockItem('a', 100)], reserved: const {'a': 400}),
        0,
      );
    });

    test('ml and grams add up 1:1', () {
      expect(
        available(
          items: [
            stockItem('ml', 700, unit: InventoryAmountUnit.milliliter),
            stockItem('a', 300),
          ],
        ),
        1000,
      );
    });

    test('an item that cannot supply the line is left out', () {
      final piece = stockItem(
        'pc',
        6000,
        unit: InventoryAmountUnit.piece,
        scale: 1000,
      );

      expect(available(items: [piece, stockItem('a', 300)]), 300);
      expect(available(items: [piece]), isNull);
    });

    test('pieces of items kept in thousandths come back whole', () {
      expect(
        available(
          items: [
            stockItem('pc', 6000, unit: InventoryAmountUnit.piece, scale: 1000),
          ],
          need: const TemplateIngredientRequirement(
            amount: 2,
            unit: TemplateIngredientUnit.piece,
            name: 'Eier',
          ),
        ),
        6,
      );
    });

    test('pieces from a gram item use the piece weight of the line', () {
      final line = cookLine(
        'own',
        conversion: const CookLineConversion(
          amountPerPiece: 60,
          unit: TemplateIngredientUnit.gram,
        ),
      );

      expect(
        available(
          items: [stockItem('a', 500)],
          line: line,
          need: const TemplateIngredientRequirement(
            amount: 3,
            unit: TemplateIngredientUnit.piece,
            name: 'Eier',
          ),
        ),
        8,
      );
    });
  });

  group('a recipe that needs part of a piece', () {
    InventoryItem piece() => stockItem(
      'flour',
      1000,
      unit: InventoryAmountUnit.piece,
      scale: 1000,
      servingQuantity: 1000,
      servingQuantityUnit: 'g',
    );

    test('250 g of a food kept as 1 piece of 1000 g takes a quarter piece', () {
      final item = piece();

      final result = takes(items: [item], need: _grams(250));

      expect(_takes(result), {'flour': 250});
      // The item keeps the rest: 750 of its 1000 thousandths.
      expect(item.currentAmount - result.single.amount, 750);
    });

    test('a food that gives only weight in pieces still fills in order', () {
      final result = takes(
        items: [piece(), stockItem('a', 500)],
        need: _grams(1500),
      );

      expect(_takes(result)['flour'], 1000);
    });
  });

  group('foods the cook added', () {
    test('keep a take of 0 when another food fills the need', () {
      final line = cookLine('own', addedItemIds: const ['mine']);

      final result = takes(
        items: [stockItem('other', 500), stockItem('mine', 500)],
        need: _grams(200),
        line: line,
      );

      expect(_takes(result), {'other': 200, 'mine': 0});
    });

    test('keep their place when the food was not added for the line: a '
        'Vorrat food that does not fill drops out', () {
      final line = cookLine('own');

      final result = takes(
        items: [
          stockItem('other', 500),
          stockItem('pc', 6000, unit: InventoryAmountUnit.piece, scale: 1000),
        ],
        need: _grams(200),
        line: line,
      );

      expect(_takes(result).containsKey('pc'), isFalse);
    });
  });

  group('cookLineStockLeft', () {
    final bottle = stockItem(
      'bottle',
      400,
      unit: InventoryAmountUnit.milliliter,
    );

    // What the line "own" has left of the foods it holds, once [others] take
    // from the same foods and [reserved] is held by other runs.
    ({String id, int amount})? left({
      required Map<String, int> takesOfLine,
      required List<InventoryItem> items,
      List<CookRunLine> others = const [],
      Map<String, int> reserved = const {},
    }) {
      final own = textLine(
        'own',
        '5 EL Olivenöl',
        settlement: takesOfLine.isEmpty
            ? const LineOpen()
            : assigned(takesOfLine),
      );
      final run = buildCookRun(lines: [own, ...others]);
      final result = cookLineStockLeft(run, own, byId(items), reserved);
      return result == null
          ? null
          : (id: result.item.id, amount: result.amount);
    }

    test("keeps the line's own takes in and takes other runs off", () {
      expect(
        left(
          takesOfLine: {'bottle': 50},
          items: [bottle],
          reserved: {'bottle': 50},
        ),
        (id: 'bottle', amount: 350),
      );
    });

    test('takes the other lines of the run off', () {
      final other = textLine(
        'other',
        '100 ml Öl',
        settlement: assigned({'bottle': 100}),
      );

      expect(
        left(takesOfLine: {'bottle': 50}, items: [bottle], others: [other]),
        (id: 'bottle', amount: 300),
      );
    });

    test('adds up grams and milliliters, in the unit of the first', () {
      final grams = stockItem('g', 100);

      expect(
        left(takesOfLine: {'g': 20, 'bottle': 20}, items: [grams, bottle]),
        (id: 'g', amount: 500),
      );
    });

    test('does not add an item kept in another scale', () {
      final pieces = stockItem(
        'pc',
        6000,
        unit: InventoryAmountUnit.piece,
        scale: 1000,
      );

      expect(
        left(takesOfLine: {'bottle': 20, 'pc': 1000}, items: [bottle, pieces]),
        (id: 'bottle', amount: 400),
      );
    });

    test('counts only the foods that take something', () {
      final grams = stockItem('g', 100);

      expect(
        left(takesOfLine: {'g': 0, 'bottle': 20}, items: [grams, bottle]),
        (id: 'bottle', amount: 400),
      );
    });

    test('counts all held foods when none of them takes anything', () {
      final grams = stockItem('g', 100);

      expect(left(takesOfLine: {'g': 0, 'bottle': 0}, items: [grams, bottle]), (
        id: 'g',
        amount: 500,
      ));
    });

    test('is null for a line that holds no food of the Vorrat', () {
      expect(left(takesOfLine: const {}, items: [bottle]), isNull);
      expect(left(takesOfLine: {'gone': 20}, items: [bottle]), isNull);
    });
  });
}
