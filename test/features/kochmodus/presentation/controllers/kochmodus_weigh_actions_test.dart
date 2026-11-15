import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_finish_check.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_controller.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_picker_offers.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_said_controller.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../../recipes/cook_run_fixtures.dart';
import '../../kochmodus_fixtures.dart';
import 'kochmodus_controller_harness.dart';

const _recipe = KochmodusTarget.recipe(recipeId: 't1');

InventoryItem _named(String id, String name, int amount) =>
    stockItem(id, amount).copyWith(name: name);

CookRun _run({
  List<CookRunLine>? lines,
  int portions = 4,
  CookRunStep step = CookRunStep.cook,
  List<CookMealDraft> meals = const [],
}) => buildCookRun(
  step: step,
  meals: meals,
  portions: portions,
  pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
  lines:
      lines ??
      [
        textLine('oil', '20 g Öl', settlement: assigned({'oil': 20})),
      ],
);

Map<String, int> _takesOf(CookRun? run, String lineId) => {
  for (final take in (run!.lineOf(lineId)!.settlement as LineAssigned).takes)
    take.itemId: take.amount,
};

void main() {
  late KochmodusHarness harness;

  setUp(() async {
    harness = await KochmodusHarness.open();
    await harness.stock([
      _named('oil', 'Öl', 500),
      _named('rice', 'Reis', 800),
    ]);
  });

  Future<KochmodusController> open(CookRun run) async {
    await harness.cook.start(run);
    return await harness.openPage(_recipe);
  }

  Future<CookRun?> stored() => harness.cook.storedRun('recipe-t1');

  KochmodusView view() => harness.view(_recipe)!;

  Future<KochmodusSaid?> say(
    KochmodusController controller,
    String said, {
    String locale = 'de',
  }) async {
    final taken = await harness.container
        .read(kochmodusSaidControllerProvider(_recipe).notifier)
        .take(controller, said, items: view().items, localeCode: locale);
    await harness.settle();
    return taken;
  }

  Future<bool> undoLast(KochmodusController controller) => harness.container
      .read(kochmodusSaidControllerProvider(_recipe).notifier)
      .undoLast(controller);

  group('weigh', () {
    test('a line kept in grams takes what was weighed', () async {
      final controller = await open(_run());

      expect(await controller.weigh('oil', 30), isTrue);
      await harness.settle();

      final run = await stored();
      expect(run!.lineOf('oil')!.weighed, 30);
      expect(_takesOf(run, 'oil'), {'oil': 30});
    });

    test('clearing the weight goes back to the amount of the recipe', () async {
      final controller = await open(_run());
      await controller.weigh('oil', 30);

      await controller.weigh('oil', null);
      await harness.settle();

      final run = await stored();
      expect(run!.lineOf('oil')!.weighed, isNull);
      expect(_takesOf(run, 'oil'), {'oil': 20});
    });

    test('clearing goes back to the own amount of the cook', () async {
      final controller = await open(
        _run(
          lines: [
            textLine(
              'oil',
              '20 g Öl',
              amount: 50,
              settlement: assigned({'oil': 50}),
            ),
          ],
        ),
      );
      await controller.weigh('oil', 30);
      expect(_takesOf(await stored(), 'oil'), {'oil': 30});

      await controller.weigh('oil', null);
      await harness.settle();

      expect(_takesOf(await stored(), 'oil'), {'oil': 50});
    });

    test('the kcal follow the weight', () async {
      final controller = await open(_run());
      await harness.settle();
      // 20 g at 100 kcal per 100 g, for 4 portions.
      expect(view().kcalPerPortion, 5);

      await controller.weigh('oil', 40);
      await harness.settle();

      expect(view().kcalPerPortion, 10);

      await controller.weigh('oil', null);
      await harness.settle();

      expect(view().kcalPerPortion, 5);
    });

    test('a weight above the stock stays, and the kcal count it', () async {
      await harness.stock([_named('small', 'Rapsöl', 25)]);
      final controller = await open(
        _run(
          lines: [
            textLine('oil', 'Öl', settlement: assigned({'small': 10})),
          ],
        ),
      );

      await controller.weigh('oil', 300);
      await harness.settle();

      expect(_takesOf(await stored(), 'oil'), {'small': 300});
      // 300 g at 100 kcal per 100 g, for 4 portions.
      expect(view().kcalPerPortion, 75);
    });

    test('a weight above the stock is short: "nur 170 g da"', () async {
      await harness.stock([_named('small', 'Rapsöl', 170)]);
      final controller = await open(
        _run(
          lines: [
            textLine('oil', 'Öl', settlement: assigned({'small': 10})),
          ],
        ),
      );

      await controller.weigh('oil', 300);
      await harness.settle();

      final line = view().lines.single;
      expect(line.needFromItem?.amount, 300);
      expect(line.needFromItem?.unit, InventoryAmountUnit.gram);
      expect(line.taken, 300);
      expect(line.onlyAvailable?.item.id, 'small');
      expect(line.onlyAvailable?.available, 170);
      // The cook corrects the weight or picks another item: not a meal that
      // silently books less than the row says.
      expect(
        view().portion.blocks,
        contains(
          const CookStockShort(lineId: 'oil', itemId: 'small', available: 170),
        ),
      );
    });

    test('only the other lines limit the take, not other runs', () async {
      await harness.cook.start(
        buildCookRun(
          id: 'recipe-t2',
          recipeId: 't2',
          lines: [
            textLine('x', '400 g Öl', settlement: assigned({'oil': 400})),
          ],
        ),
      );
      final controller = await open(
        _run(
          lines: [
            textLine('oil', '20 g Öl', settlement: assigned({'oil': 20})),
            textLine('other', '60 g Öl', settlement: assigned({'oil': 60})),
          ],
        ),
      );

      await controller.weigh('oil', 300);
      await harness.settle();

      // The food is in the pot, whatever the other run reserves.
      expect(_takesOf(await stored(), 'oil'), {'oil': 300});
      expect(view().lines.first.onlyAvailable, isNull);
      // Takes its weight and goes through.
      expect(view().portion.blocks.whereType<CookStockShort>(), isEmpty);
    });

    test('a weighed line is not to weigh any more', () async {
      await harness.stock([
        stockItem(
          'onion',
          6000,
          unit: InventoryAmountUnit.piece,
          scale: 1000,
          servingQuantity: 90,
          servingQuantityUnit: 'g',
        ).copyWith(name: 'Zwiebel'),
      ]);
      final controller = await open(
        _run(
          lines: [
            textLine(
              'onion',
              '1 Zwiebel',
              settlement: assigned({'onion': 1000}),
            ),
          ],
        ),
      );
      await harness.settle();
      expect(view().estimated.map((line) => line.id), ['onion']);

      await controller.weigh('onion', 180);
      await harness.settle();

      expect(view().estimated, isEmpty);
      expect(view().lines.single.weight, const CookWeightWeighed(180));
    });

    test('a piece item keeps its take, the weight is a record', () async {
      await harness.stock([
        stockItem(
          'onion',
          6000,
          unit: InventoryAmountUnit.piece,
          scale: 1000,
        ).copyWith(name: 'Zwiebel'),
      ]);
      final controller = await open(
        _run(
          lines: [
            textLine(
              'onion',
              '1 Zwiebel',
              settlement: assigned({'onion': 1000}),
            ),
          ],
        ),
      );

      await controller.weigh('onion', 180);
      await harness.settle();

      final run = await stored();
      expect(run!.lineOf('onion')!.weighed, 180);
      expect(_takesOf(run, 'onion'), {'onion': 1000});
    });

    test('a line that is not assigned only records the weight', () async {
      final controller = await open(_run(lines: [textLine('oil', '20 g Öl')]));

      expect(await controller.weigh('oil', 30), isTrue);
      await harness.settle();

      final run = await stored();
      expect(run!.lineOf('oil')!.weighed, 30);
      expect(run.lineOf('oil')!.settlement, isA<LineOpen>());
    });
  });

  group('a weighed line through later refills', () {
    test('setAmount keeps the takes at the weight', () async {
      final controller = await open(_run());
      await controller.weigh('oil', 30);

      await controller.setAmount('oil', 90);
      await harness.settle();

      expect(_takesOf(await stored(), 'oil'), {'oil': 30});

      await controller.weigh('oil', null);
      await harness.settle();

      expect(_takesOf(await stored(), 'oil'), {'oil': 90});
    });

    test('assignItems on another item takes the weight from it', () async {
      await harness.stock([_named('olive', 'Olivenöl', 200)]);
      final controller = await open(_run());
      await controller.weigh('oil', 30);

      await controller.assignItems('oil', ['olive']);
      await harness.settle();

      final run = await stored();
      expect(run!.lineOf('oil')!.weighed, 30);
      expect(_takesOf(run, 'oil'), {'olive': 30});
    });

    test('assignItems over a piece item keeps the take of the need', () async {
      await harness.stock([
        stockItem(
          'onion',
          6000,
          unit: InventoryAmountUnit.piece,
          scale: 1000,
        ).copyWith(name: 'Zwiebel'),
      ]);
      final controller = await open(
        _run(lines: [textLine('l', '2 Zwiebeln', weighed: 180)]),
      );

      await controller.assignItems('l', ['onion']);
      await harness.settle();

      expect(_takesOf(await stored(), 'l'), {'onion': 2000});
    });
  });

  group('a weight above the stock next to another line', () {
    CookRun twoLines() => _run(
      lines: [
        textLine('oil', '20 g Öl', settlement: assigned({'small': 20})),
        textLine('dash', '15 g Öl', settlement: assigned({'small': 15})),
      ],
    );

    test('does not starve the other line on a refill', () async {
      await harness.stock([_named('small', 'Öl', 100)]);
      final controller = await open(twoLines());

      await controller.weigh('oil', 300);
      await harness.settle();

      final run = await stored();
      expect(_takesOf(run, 'oil'), {'small': 300});
      expect(_takesOf(run, 'dash'), {'small': 15});
      // Only the line that is above the stock is told so, with what is left.
      expect(view().portion.blocks.whereType<CookLineWithoutTake>(), isEmpty);
      expect(view().portion.blocks.whereType<CookStockShort>(), [
        const CookStockShort(lineId: 'oil', itemId: 'small', available: 85),
      ]);

      await controller.weigh('oil', 85);
      await harness.settle();

      expect(view().portion.blocks.whereType<CookStockShort>(), isEmpty);
    });
  });

  group('assignFound on a weighed line', () {
    test('splits the weight over the items, the new one first', () async {
      await harness.stock([
        _named('small', 'Öl', 170),
        _named('found', 'Öl B', 130),
      ]);
      final controller = await open(
        _run(
          lines: [
            textLine('oil', '20 g Öl', settlement: assigned({'small': 20})),
          ],
        ),
      );
      await controller.weigh('oil', 300);

      await controller.assignFound('oil', _named('found', 'Öl B', 130));
      await harness.settle();

      final run = await stored();
      expect(_takesOf(run, 'oil'), {'small': 170, 'found': 130});
      expect(run!.lineOf('oil')!.addedItemIds, ['found']);
      expect(view().portion.blocks.whereType<CookStockShort>(), isEmpty);
    });

    test('never books more than the weight', () async {
      await harness.stock([_named('found', 'Öl B', 500)]);
      final controller = await open(_run());
      await controller.weigh('oil', 300);

      await controller.assignFound('oil', _named('found', 'Öl B', 500));
      await harness.settle();

      expect(_takesOf(await stored(), 'oil'), {'found': 300, 'oil': 0});
    });

    test('a found item in pieces without a weight keeps a take of 0', () async {
      final onion = stockItem(
        'onion',
        3000,
        unit: InventoryAmountUnit.piece,
        scale: 1000,
      );
      await harness.stock([onion]);
      final controller = await open(_run());
      await controller.weigh('oil', 300);

      await controller.assignFound('oil', onion);
      await harness.settle();

      // Pieces cannot supply a line in grams: the food the cook added stays
      // with 0 and the line keeps what it had.
      expect(_takesOf(await stored(), 'oil'), {'onion': 0, 'oil': 20});
    });
  });

  group('undoRemove', () {
    test('keeps the weight and its takes', () async {
      final controller = await open(_run());
      await controller.weigh('oil', 30);
      final removed = await controller.removeFromPortion('oil');

      await controller.undoRemove(removed!);
      await harness.settle();

      final run = await stored();
      expect(run!.lineOf('oil')!.weighed, 30);
      expect(_takesOf(run, 'oil'), {'oil': 30});
    });
  });

  group('the picker of a weighed line', () {
    test('needs and misses what was weighed', () async {
      await harness.stock([_named('small', 'Rapsöl', 100)]);
      final controller = await open(_run());
      await controller.weigh('oil', 300);
      await harness.settle();

      final offers = kochmodusPickerOffers(view(), 'oil', localeCode: 'de');
      final small = [
        ...offers.matches,
        ...offers.rest,
      ].singleWhere((offer) => offer.item.id == 'small');
      final oil = [
        ...offers.matches,
        ...offers.rest,
      ].singleWhere((offer) => offer.item.id == 'oil');

      expect(small.needed, 300);
      expect(small.missing, 200);
      expect(oil.needed, 300);
      expect(oil.missing, 0);
    });

    test("counts the run's own lines, not the other runs", () async {
      await harness.cook.start(
        buildCookRun(
          id: 'recipe-t2',
          recipeId: 't2',
          lines: [
            textLine('x', '400 g Öl', settlement: assigned({'oil': 400})),
          ],
        ),
      );
      final controller = await open(
        _run(
          lines: [
            textLine('oil', '20 g Öl', settlement: assigned({'oil': 20})),
            textLine('other', '60 g Öl', settlement: assigned({'oil': 60})),
          ],
        ),
      );
      await controller.weigh('oil', 300);
      await harness.settle();

      final offers = kochmodusPickerOffers(view(), 'oil', localeCode: 'de');
      final oil = offers.matches.singleWhere((offer) => offer.item.id == 'oil');

      expect(oil.reserved, 60);
      expect(oil.available, 440);
      expect(oil.missing, 0);
      // As booked and checked: the take is its weight and passes.
      expect(_takesOf(await stored(), 'oil'), {'oil': 300});
      expect(view().portion.blocks.whereType<CookStockShort>(), isEmpty);
    });

    test('an item in pieces still counts the other runs', () async {
      await harness.stock([
        stockItem('egg', 5000, unit: InventoryAmountUnit.piece, scale: 1000),
      ]);
      await harness.cook.start(
        buildCookRun(
          id: 'recipe-t2',
          recipeId: 't2',
          lines: [
            textLine('x', '1 Ei', settlement: assigned({'egg': 2000})),
          ],
        ),
      );
      final controller = await open(_run());
      await controller.weigh('oil', 300);
      await harness.settle();

      final offers = kochmodusPickerOffers(view(), 'oil', localeCode: 'de');
      final egg = offers.rest.singleWhere((offer) => offer.item.id == 'egg');

      expect(egg.reserved, 2000);
      expect(egg.available, 3000);
    });
  });

  group('the Vorrat follows the weight', () {
    test('another run sees the weighed take as planned', () async {
      final controller = await open(_run());
      await controller.weigh('oil', 30);
      await harness.settle();

      const other = KochmodusTarget.recipe(recipeId: 't2');
      await harness.cook.start(
        buildCookRun(
          id: 'recipe-t2',
          recipeId: 't2',
          lines: [textLine('y', '10 g Reis')],
        ),
      );
      await harness.cook.settle();

      final provider = kochmodusControllerProvider(other);
      harness.container.listen(provider, (_, _) {});
      await harness.container.read(provider.future);
      final otherView = harness.view(other)!;

      expect(otherView.otherReservations['oil'], 30);
    });

    test('finishing writes the weighed take into the Vorrat', () async {
      final controller = await open(
        _run(
          step: CookRunStep.portion,
          meals: const [
            CookMealDraft(
              potId: 'pot-a',
              name: 'Eintopf',
              count: 4,
              inPieces: false,
              grossWeight: 2400,
            ),
          ],
          lines: [
            textLine('oil', '20 g Öl', settlement: assigned({'oil': 20})),
          ],
        ),
      );
      await controller.weigh('oil', 30);
      await harness.settle();

      final summary = await controller.finish();
      await harness.settle();

      expect(summary, isNotNull);
      expect((await harness.cook.storedItem('oil'))!.currentAmount, 470);
    });
  });

  group('takeSaid', () {
    test('a weight for an assigned line weighs it and adds no line', () async {
      final controller = await open(_run());

      final taken = await say(controller, '30 g Öl');

      expect(taken?.lineId, 'oil');
      expect(taken?.before?.weighed, isNull);
      final run = await stored();
      expect(run!.lines, hasLength(1));
      expect(run.lineOf('oil')!.weighed, 30);
      expect(_takesOf(run, 'oil'), {'oil': 30});
    });

    test('a weight given the other way round counts too', () async {
      final controller = await open(_run());

      await say(controller, 'Öl 30 Gramm');

      expect((await stored())!.lineOf('oil')!.weighed, 30);
    });

    test('kg and l convert', () async {
      final controller = await open(
        _run(
          lines: [
            textLine('oil', 'Öl', settlement: assigned({'oil': 10})),
          ],
        ),
      );

      await say(controller, '0,5 l Öl');

      expect((await stored())!.lineOf('oil')!.weighed, 500);
    });

    group('words for an amount', () {
      final said = {
        '1 Kilo Öl': 1000,
        'ein Liter Öl': 1000,
        'Öl 30 Milliliter': 30,
        '1 Pfund Öl': 500,
        '1,250 kg Öl': 1250,
        '0,250 kg Öl': 250,
      };
      for (final MapEntry(key: words, value: grams) in said.entries) {
        test('"$words" counts for the assigned line', () async {
          final controller = await open(_run());

          await say(controller, words);

          final run = await stored();
          expect(run!.lines, hasLength(1));
          expect(run.lineOf('oil')!.weighed, grams);
        });
      }
    });

    test('a new line stays what was said, whatever the portions', () async {
      final controller = await open(_run(portions: 8));

      await say(controller, '200 g Sahne');

      expect(view().newLines.single.text, '200 g Sahne');
      expect(view().newLines.single.need?.amount, 200);
    });

    test('a second mention adds up', () async {
      final controller = await open(_run());

      await say(controller, '30 g Öl');
      final second = await say(controller, '10 g Öl');

      expect(second?.before?.weighed, 30);
      final run = await stored();
      expect(run!.lineOf('oil')!.weighed, 40);
      expect(_takesOf(run, 'oil'), {'oil': 40});
    });

    test('a weight for a food no line has becomes a new line', () async {
      final controller = await open(_run());

      final taken = await say(controller, '50 g Zucker');

      expect(taken?.before, isNull);
      final run = await stored();
      expect(run!.lines.map((line) => line.text), ['20 g Öl', '50 g Zucker']);
      expect(run.lineOf('oil')!.weighed, isNull);
      expect(run.lines.last.origin, CookLineOrigin.cooking);
      expect(run.lines.last.settlement, isA<LineOpen>());
    });

    group('a weight on the wrong food', () {
      Future<void> saysNewLine(
        String said, {
        required String line,
        required InventoryItem item,
      }) async {
        await harness.stock([item]);
        final controller = await open(
          _run(
            lines: [
              textLine('it', line, settlement: assigned({item.id: 100})),
            ],
          ),
        );

        final taken = await say(controller, said);

        expect(taken?.before, isNull);
        final run = await stored();
        expect(run!.lines.map((line) => line.text), [line, said]);
        expect(run.lineOf('it')!.weighed, isNull);
        expect(_takesOf(run, 'it'), {item.id: 100});
      }

      test('wine does not land on pork', () async {
        await saysNewLine(
          '100 ml Wein',
          line: '100 g Schweinefilet',
          item: _named('pork', 'Schweinefilet', 800),
        );
      });

      test('egg does not land on rice', () async {
        await saysNewLine(
          '50 g Ei',
          line: '100 g Reis',
          item: _named('r', 'Reis', 800),
        );
      });

      test('salt does not land on the oil of a bundled line', () async {
        await saysNewLine(
          '5 g Salz',
          line: '100 ml Öl, Salz, Pfeffer',
          item: _named('rapeseed', 'Rapsöl', 800),
        );
      });

      test('paprika does not land on the Maggi of a bundled line', () async {
        await saysNewLine(
          '5 g Paprikapulver',
          line: 'Maggi oder Sojasoße, 1 TL Paprikapulver',
          item: _named('maggi', 'Maggi', 800),
        );
      });
    });

    test('a short name weighs the line named the long way', () async {
      await harness.stock([_named('mince', 'Hackfleisch gemischt', 800)]);
      final controller = await open(
        _run(
          lines: [
            textLine(
              'mince',
              '500 g Hackfleisch',
              settlement: assigned({'mince': 500}),
            ),
          ],
        ),
      );

      final taken = await say(controller, '480 g Hack');

      expect(taken?.lineId, 'mince');
      final run = await stored();
      expect(run!.lines, hasLength(1));
      expect(run.lineOf('mince')!.weighed, 480);
      expect(_takesOf(run, 'mince'), {'mince': 480});
    });

    test('pieces, spoons and no amount stay new lines', () async {
      final controller = await open(_run());

      await say(controller, '2 EL Öl');
      await say(controller, 'Öl');
      await say(controller, '2 Öle');

      final run = await stored();
      expect(run!.lineOf('oil')!.weighed, isNull);
      expect(run.lines.map((line) => line.text), [
        '20 g Öl',
        '2 EL Öl',
        'Öl',
        '2 Öle',
      ]);
    });

    test('an ignored or shopping line is not matched', () async {
      final controller = await open(
        _run(
          lines: [
            textLine('oil', 'Öl', settlement: const LineIgnored()),
            textLine('oil2', 'Öl', settlement: const LineShopping()),
          ],
        ),
      );

      final taken = await say(controller, '30 g Öl');

      expect(taken?.before, isNull);
      final run = await stored();
      expect(run!.lines, hasLength(3));
      expect(run.lineOf('oil')!.weighed, isNull);
      expect(run.lineOf('oil2')!.weighed, isNull);
    });

    test('a weighed Rapsöl counts for the line that takes from it', () async {
      await harness.stock([_named('rapeseed', 'Rapsöl', 300)]);
      final controller = await open(
        _run(
          lines: [
            textLine('oil', 'Öl', settlement: assigned({'rapeseed': 10})),
          ],
        ),
      );

      await say(controller, '30 g Rapsöl');

      final run = await stored();
      expect(run!.lines, hasLength(1));
      expect(_takesOf(run, 'oil'), {'rapeseed': 30});
    });
  });

  group('undoLast', () {
    test('removes a new line', () async {
      final controller = await open(_run());
      await say(controller, '50 g Zucker');

      expect(await undoLast(controller), isTrue);
      await harness.settle();

      expect((await stored())!.lines.map((line) => line.id), ['oil']);
    });

    test('restores a weight and the takes to null and before', () async {
      final controller = await open(_run());
      await say(controller, '30 g Öl');
      await say(controller, '10 g Öl');

      await undoLast(controller);
      await harness.settle();

      var run = await stored();
      expect(run!.lineOf('oil')!.weighed, 30);
      expect(_takesOf(run, 'oil'), {'oil': 30});

      await undoLast(controller);
      await harness.settle();

      run = await stored();
      expect(run!.lineOf('oil')!.weighed, isNull);
      expect(_takesOf(run, 'oil'), {'oil': 20});
    });

    test('restores a line with an added item as it was', () async {
      await harness.stock([_named('extra', 'Rapsöl', 500)]);
      final controller = await open(
        _run(
          lines: [
            textLine(
              'oil',
              '20 g Öl',
              settlement: assigned({'oil': 10, 'extra': 10}),
              addedItemIds: const ['extra'],
            ),
          ],
        ),
      );
      await say(controller, '40 g Öl');
      expect(_takesOf(await stored(), 'oil'), {'oil': 40, 'extra': 0});

      await undoLast(controller);
      await harness.settle();

      final run = await stored();
      expect(run!.lineOf('oil')!.weighed, isNull);
      // The takes fill the line's need again, in the order of the items.
      expect(_takesOf(run, 'oil'), {'oil': 20, 'extra': 0});
      expect(run.lineOf('oil')!.addedItemIds, ['extra']);
    });
  });
}
