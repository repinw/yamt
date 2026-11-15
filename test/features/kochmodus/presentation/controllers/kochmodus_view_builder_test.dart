import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/kochmodus/application/cook_finish_check.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_line_view_builder.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_picker_offers.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_view_builder.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_text.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_card_texts.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations_de.dart';
import 'package:yamt/l10n/app_localizations_en.dart';

import '../../../../support/prepared_meal_test_data.dart';
import '../../../recipes/cook_run_fixtures.dart';
import '../../kochmodus_fixtures.dart';

final _pots = CookPotsChosen(pots: const [cookPotA, cookPotB], inCans: false);

KochmodusView _view(
  CookRun run, {
  bool saved = true,
  KochmodusStep? tab,
  List<InventoryItem> items = const [],
  Map<String, int> others = const {},
  bool busy = false,
  bool ended = false,
}) => buildKochmodusView(
  run: run,
  saved: saved,
  ended: ended,
  busy: busy,
  reopened: false,
  finished: null,
  tab: tab,
  items: items,
  otherReservations: others,
  utensils: const [],
  parser: const TemplateIngredientParser(),
);

KochmodusLineView _line(KochmodusView view, String id) =>
    view.lines.singleWhere((line) => line.id == id);

void main() {
  group('groups', () {
    test('sorts the lines by their settlement and origin', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('open', '200 g Reis'),
            textLine('taken', '100 g Mehl', settlement: assigned({'i1': 100})),
            textLine('shop', 'Zwiebeln', settlement: const LineShopping()),
            textLine('skip', 'Salz', settlement: const LineIgnored()),
            cookLine('new', origin: CookLineOrigin.cooking),
          ],
        ),
        items: [stockItem('i1', 100)],
      );

      expect(view.toAnswer.map((line) => line.id), ['open', 'new']);
      expect(view.shopping.map((line) => line.id), ['shop']);
      expect(view.ignored.map((line) => line.id), ['skip']);
      expect(view.newLines.map((line) => line.id), ['new']);
      expect(view.lines.map((line) => line.id), [
        'open',
        'taken',
        'shop',
        'skip',
        'new',
      ]);
    });

    group('short and ready', () {
      KochmodusView build() => _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('fits', '100 g Mehl', settlement: assigned({'i1': 100})),
            textLine('spare', '100 g Reis', settlement: assigned({'i2': 100})),
            textLine(
              'short',
              '300 g Zucker',
              settlement: assigned({'i3': 100}),
            ),
            textLine('salt', 'Salz', settlement: assigned({'i4': 1})),
            textLine('open', '200 g Nudeln'),
            textLine('shop', '200 g Hack', settlement: const LineShopping()),
            textLine('skip', '200 g Kaese', settlement: const LineIgnored()),
          ],
        ),
        items: [
          stockItem('i1', 100),
          stockItem('i2', 500),
          stockItem('i3', 100),
          stockItem('i4', 50),
        ],
      );

      test('shortBy is what the items lack, null when they hold enough', () {
        final view = build();

        expect(_line(view, 'fits').shortBy, isNull);
        expect(_line(view, 'spare').shortBy, isNull);
        expect(_line(view, 'short').shortBy, 200);
      });

      test(
        'shortBy is null for a line that is not assigned or has no amount',
        () {
          final view = build();

          expect(_line(view, 'salt').shortBy, isNull);
          expect(_line(view, 'open').shortBy, isNull);
          expect(_line(view, 'shop').shortBy, isNull);
          expect(_line(view, 'skip').shortBy, isNull);
        },
      );

      test('a line with more in stock than needed stays ready', () {
        final view = build();

        expect(view.toAnswer.map((line) => line.id), ['open', 'short']);
        expect(view.lines, hasLength(7));
      });

      test('a short line counts as open and keeps the main button waiting', () {
        final view = build();

        expect(view.openCount, 2);
        expect(view.toAnswer.map((line) => line.id), ['open', 'short']);
      });

      test('the own amount of the cook is what the line needs', () {
        final view = _view(
          buildCookRun(
            pots: _pots,
            lines: [
              textLine(
                'spare',
                '100 g Reis',
                amount: 150,
                settlement: assigned({'i2': 150}),
              ),
              textLine(
                'less',
                '300 g Zucker',
                amount: 100,
                settlement: assigned({'i3': 100}),
              ),
            ],
          ),
          items: [stockItem('i2', 500), stockItem('i3', 100)],
        );

        expect(_line(view, 'spare').shortBy, isNull);
        expect(_line(view, 'less').shortBy, isNull);
        expect(_line(view, 'less').takesLess, isTrue);
        expect(view.toAnswer, isEmpty);
      });

      test('a rough need is never short', () {
        final view = _view(
          buildCookRun(
            pots: _pots,
            lines: [
              textLine(
                'rough',
                'Butter zum Braten',
                settlement: assigned({'i1': 5}),
                roughWeight: const CookRoughWeight(
                  amount: 20,
                  unit: TemplateIngredientUnit.gram,
                ),
              ),
            ],
          ),
          items: [stockItem('i1', 5)],
        );

        expect(_line(view, 'rough').roughNeed, isTrue);
        expect(_line(view, 'rough').need?.amount, 20);
        expect(_line(view, 'rough').shortBy, isNull);
        expect(view.toAnswer, isEmpty);
      });

      test('restOnList follows the shopping line of the rest', () {
        final view = _view(
          buildCookRun(
            pots: _pots,
            lines: [
              textLine(
                'short',
                '300 g Zucker',
                amount: 100,
                settlement: assigned({'i3': 100}),
              ),
              textLine(
                cookRestLineId('short'),
                '200 g Zucker',
                settlement: const LineShopping(),
              ),
            ],
          ),
          items: [stockItem('i3', 100)],
        );

        expect(_line(view, 'short').restOnList, isTrue);
        expect(view.shopping.map((line) => line.id), ['short-rest']);
        expect(view.toAnswer, isEmpty);
      });
    });

    test('toWeigh holds only lines whose weight is missing', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine(
              'piece',
              '1 Zwiebel',
              settlement: assigned({'onion': 1000}),
            ),
            textLine('exact', '100 g Mehl', settlement: assigned({'i1': 100})),
          ],
        ),
        items: [
          stockItem('i1', 100),
          stockItem(
            'onion',
            3000,
            unit: InventoryAmountUnit.piece,
            scale: 1000,
          ),
        ],
      );

      expect(view.toWeigh.map((line) => line.id), everyElement(isNot('exact')));
      expect(
        view.toWeigh.every((line) => line.weight is CookWeightMissing),
        isTrue,
      );
    });

    test('puts each line into its pot, the first by default, no ignored', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', 'Reis'),
            textLine('b', 'Mehl', potId: 'pot-b'),
            textLine('c', 'Salz', settlement: const LineIgnored()),
            textLine('d', 'Zwiebeln', potId: 'gone'),
          ],
        ),
      );

      expect(view.portion.meals.map((meal) => meal.potId), ['pot-a', 'pot-b']);
      expect(_line(view, 'a').potId, 'pot-a');
      expect(_line(view, 'd').potId, 'pot-a');
      expect(_line(view, 'b').potId, 'pot-b');
      expect(_line(view, 'c').potId, isNull);
    });

    test('keeps one meal for counted cooking and none before the pots', () {
      final counted = _view(buildCookRun(pots: const CookCounted()));
      final draft = _view(buildCookRun(step: CookRunStep.pots), saved: false);

      expect(counted.counted, isTrue);
      expect(counted.pots, isEmpty);
      expect(counted.portion.meals.map((meal) => meal.potId), [
        countedMealPotId,
      ]);
      expect(draft.portion.meals, isEmpty);
      expect(draft.pots, isEmpty);
      expect(draft.counted, isFalse);
    });

    test('shows the chosen pots and the cans choice', () {
      final view = _view(
        buildCookRun(
          pots: CookPotsChosen(pots: const [cookPotA], inCans: true),
        ),
      );

      expect(view.pots, [cookPotA]);
      expect(view.inCans, isTrue);
    });

    test('sorts the timers by their end', () {
      final soon = CookTimer(
        id: 'soon',
        label: 'Reis',
        endsAt: cookRunStart.add(const Duration(minutes: 5)),
        deviceId: 'd',
      );
      final late = CookTimer(
        id: 'late',
        label: 'Soße',
        endsAt: cookRunStart.add(const Duration(minutes: 20)),
        deviceId: 'd',
      );

      final view = _view(buildCookRun(timers: [late, soon]));

      expect(view.timers.map((timer) => timer.id), ['soon', 'late']);
    });

    test('reads the guide steps with a timer choice for each time', () {
      final view = _view(
        buildCookRun(steps: const ['Rühren', '8-10 Min köcheln']),
      );

      expect(view.guide.map((step) => step.text), [
        'Rühren',
        '8-10 Min köcheln',
      ]);
      expect(view.guide.first.timerSteps, isEmpty);
      expect(view.guide.last.timerSteps.single, isNotEmpty);
      expect(view.guideVisible, isTrue);
    });
  });

  group('tabs', () {
    test('follows the run step, a run before cooking shows Töpfe', () {
      expect(
        _view(buildCookRun(step: CookRunStep.cook)).step,
        KochmodusStep.cook,
      );
      expect(
        _view(buildCookRun(step: CookRunStep.paused)).step,
        KochmodusStep.pots,
      );
      expect(_view(buildCookRun()).step, KochmodusStep.pots);
      expect(
        _view(buildCookRun(step: CookRunStep.pots)).step,
        KochmodusStep.pots,
      );
      expect(
        _view(buildCookRun(step: CookRunStep.portion)).step,
        KochmodusStep.portion,
      );
    });

    test('shows the tab the cook opened over the run step', () {
      final view = _view(
        buildCookRun(step: CookRunStep.cook),
        tab: KochmodusStep.pots,
      );

      expect(view.step, KochmodusStep.pots);
      expect(view.nextStep, KochmodusStep.cook);
    });

    test('a recipe and free cooking have the same three tabs', () {
      final recipe = _view(buildCookRun());
      final free = _view(freeRun([textLine('a', 'Reis')]));

      expect(free.isFree, isTrue);
      expect(recipe.isFree, isFalse);
      expect(KochmodusStep.values, [
        KochmodusStep.pots,
        KochmodusStep.cook,
        KochmodusStep.portion,
      ]);
    });

    test('the last tab is its own next tab', () {
      final view = _view(buildCookRun(step: CookRunStep.portion));

      expect(view.nextStep, KochmodusStep.portion);
    });

    test('a draft locks everything past Töpfe', () {
      final view = _view(buildCookRun(step: CookRunStep.pots), saved: false);

      expect(view.saved, isFalse);
      expect(view.locked, {KochmodusStep.cook, KochmodusStep.portion});
    });

    test('a stored run opens every tab, open lines lock nothing', () {
      final open = _view(buildCookRun(pots: _pots));
      final shopping = _view(
        buildCookRun(
          pots: _pots,
          lines: [textLine('a', 'Reis', settlement: const LineShopping())],
        ),
      );

      // "Zuweisen" is its own page; its "Kochen" keeps the cook from going
      // on while lines are open.
      expect(open.locked, isEmpty);
      expect(shopping.locked, isEmpty);
    });

    test('Kochen and Portion stay open when lines come in while cooking', () {
      final view = _view(
        buildCookRun(
          step: CookRunStep.cook,
          pots: _pots,
          lines: [
            textLine('a', 'Reis', settlement: assigned({'i1': 100})),
            cookLine('n', origin: CookLineOrigin.cooking),
            cookLine(
              'm',
              origin: CookLineOrigin.cooking,
              settlement: const LineShopping(),
            ),
          ],
        ),
        items: [stockItem('i1', 500)],
      );

      expect(view.locked, isEmpty);
    });

    test('free cooking never waits for open lines', () {
      final view = _view(freeRun([textLine('a', 'Reis')], pots: _pots));

      expect(view.locked, isEmpty);
    });
  });

  group('perPortion', () {
    test('divides energy, protein, carbs and fat by the portions', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '800 g Reis', settlement: assigned({'i1': 800})),
          ],
        ),
        items: [stockItem('i1', 1000)],
      );

      // 800 g at 100 kcal, 1 g protein, 1 g carbs and 1 g fat per 100 g.
      expect(view.perPortion, (kcal: 200, protein: 2, carbs: 2, fat: 2));
      expect(view.kcalPerPortion, 200);
    });

    test('is null when a take has no complete nutrition', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '800 g Reis', settlement: assigned({'i1': 800})),
          ],
        ),
        items: [stockItem('i1', 1000, nutrition: null)],
      );

      expect(view.perPortion, isNull);
      expect(view.kcalPerPortion, isNull);
    });

    test('is null while a line is open or on the shopping list', () {
      final open = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '800 g Reis', settlement: assigned({'i1': 800})),
            textLine('b', 'Milch'),
          ],
        ),
        items: [stockItem('i1', 1000)],
      );
      final shopping = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '800 g Reis', settlement: assigned({'i1': 800})),
            textLine('b', 'Milch', settlement: const LineShopping()),
          ],
        ),
        items: [stockItem('i1', 1000)],
      );

      expect(open.perPortion, isNull);
      expect(shopping.perPortion, isNull);
    });
  });

  group('what is left to answer on Zuweisen', () {
    test('an assignment that takes nothing and no weight can help is still '
        'asked, so the page is not ready', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('flour', '250 g Mehl', settlement: assigned({'pack': 0})),
            textLine('ok', '100 g Reis', settlement: assigned({'i1': 100})),
          ],
        ),
        items: [packItem('pack', 2), stockItem('i1', 500)],
      );

      expect(_line(view, 'flour').needsOtherFood, isTrue);
      expect(view.toAnswer.map((line) => line.id), ['flour']);
      expect(view.shopping, isEmpty);
    });

    test('a take of 0 on an item kept in grams waits for a weight instead', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('oil', '2 EL Öl', settlement: assigned({'i1': 0})),
          ],
        ),
        items: [stockItem('i1', 500)],
      );

      expect(_line(view, 'oil').needsOtherFood, isFalse);
      expect(view.toAnswer, isEmpty);
    });

    test('open lines are asked, and there is no energy yet', () {
      final view = _view(buildCookRun(pots: _pots));

      expect(view.toAnswer, isNotEmpty);
      expect(view.kcalPerPortion, isNull);
    });

    test('shopping lines leave nothing to answer', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', 'Reis', settlement: assigned({'i1': 100})),
            textLine('b', 'Zwiebeln', settlement: const LineShopping()),
          ],
        ),
        items: [stockItem('i1', 500)],
      );

      expect(view.toAnswer, isEmpty);
      expect(view.shopping.map((line) => line.id), ['b']);
    });

    test('open lines are asked first, shopping lines stay on the list', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', 'Reis'),
            textLine('b', 'Zwiebeln', settlement: const LineShopping()),
          ],
        ),
      );

      expect(view.toAnswer.map((line) => line.id), ['a']);
      expect(view.shopping.map((line) => line.id), ['b']);
      expect(view.kcalPerPortion, isNull);
    });

    test('A3: everything settled leaves nothing to answer or buy', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', 'Reis', settlement: assigned({'i1': 100})),
          ],
        ),
        items: [stockItem('i1', 500)],
      );

      expect(view.toAnswer, isEmpty);
      expect(view.shopping, isEmpty);
      expect(view.kcalPerPortion, isNotNull);
    });

    test('A3: Mit Anleitung shows only for a recipe with instructions', () {
      final withSteps = _view(buildCookRun());
      final without = _view(buildCookRun(steps: const []));

      expect(withSteps.guideVisible, isTrue);
      expect(without.guideVisible, isFalse);
      expect(without.showGuide, isFalse);
    });

    test('the guide shows when switched on and there are instructions', () {
      final run = buildCookRun();
      final on = _view(run.useGuide(on: true));

      expect(on.showGuide, isTrue);
      expect(_view(run).showGuide, isFalse);
    });

    test('carries the busy flag, the ended flag, and paused', () {
      final view = _view(
        buildCookRun(step: CookRunStep.paused),
        busy: true,
        ended: true,
      );

      expect(view.busy, isTrue);
      expect(view.ended, isTrue);
      expect(view.paused, isTrue);
    });
  });

  group('kcal per portion', () {
    CookRun settled(Map<String, int> amounts) => buildCookRun(
      pots: _pots,
      lines: [textLine('a', 'Reis', settlement: assigned(amounts))],
    );

    test('sums the takes over the portions', () {
      // 300 g at 100 kcal per 100 g, over 4 portions.
      final view = _view(settled({'i1': 300}), items: [stockItem('i1', 500)]);

      expect(view.kcalPerPortion, 75);
    });

    test('adds the takes of every line and item', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', 'Reis', settlement: assigned({'i1': 200, 'i2': 100})),
            textLine('b', 'Mehl', settlement: assigned({'i2': 100})),
          ],
        ),
        items: [stockItem('i1', 500), stockItem('i2', 500)],
      );

      expect(view.kcalPerPortion, 100);
    });

    test('is empty while a line is open or waits for the shopping', () {
      final open = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', 'Reis', settlement: assigned({'i1': 300})),
            textLine('b', 'Mehl'),
          ],
        ),
        items: [stockItem('i1', 500)],
      );
      final shopping = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', 'Reis', settlement: assigned({'i1': 300})),
            textLine('b', 'Mehl', settlement: const LineShopping()),
          ],
        ),
        items: [stockItem('i1', 500)],
      );

      expect(open.kcalPerPortion, isNull);
      expect(shopping.kcalPerPortion, isNull);
    });

    test('is empty when a taken item has no complete nutrition', () {
      final view = _view(
        settled({'i1': 300}),
        items: [stockItem('i1', 500, nutrition: null)],
      );

      expect(view.kcalPerPortion, isNull);
    });

    test('is empty when a taken item is gone', () {
      final view = _view(settled({'ghost': 300}));

      expect(view.kcalPerPortion, isNull);
    });

    test('is empty when nothing is taken', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [textLine('a', 'Salz', settlement: const LineIgnored())],
        ),
      );

      expect(view.kcalPerPortion, isNull);
    });

    test('counts takes of 0 as nothing, even without nutrition', () {
      final view = _view(
        settled({'i1': 0}),
        items: [stockItem('i1', 500, nutrition: null)],
      );

      expect(view.kcalPerPortion, isNull);
    });
  });

  group('blocks and line flags', () {
    test('only N there: names what the short item still has', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '300 g Reis', settlement: assigned({'i1': 300})),
          ],
        ),
        items: [stockItem('i1', 100)],
      );

      expect(view.portion.blocks, contains(isA<CookStockShort>()));
      expect(_line(view, 'a').onlyAvailable?.available, 100);
    });

    test('nothing short leaves onlyAvailable empty', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '300 g Reis', settlement: assigned({'i1': 300})),
          ],
        ),
        items: [stockItem('i1', 500)],
      );

      expect(_line(view, 'a').onlyAvailable, isNull);
      expect(view.portion.blocks.whereType<CookStockShort>(), isEmpty);
    });

    test('another line of the run counts against the same item', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '300 g Reis', settlement: assigned({'i1': 300})),
            textLine('b', '300 g Reis', settlement: assigned({'i1': 300})),
          ],
        ),
        items: [stockItem('i1', 500)],
      );

      expect(_line(view, 'a').onlyAvailable?.available, 200);
      expect(_line(view, 'b').onlyAvailable?.available, 200);
    });

    test('entry missing: the item is gone from the Vorrat', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '300 g Reis', settlement: assigned({'ghost': 300})),
          ],
        ),
      );
      final line = _line(view, 'a');

      expect(line.entryMissing, isTrue);
      expect(line.takes.single.item, isNull);
      expect(line.takes.single.itemId, 'ghost');
      expect(line.pictureItem, isNull);
      expect(
        view.portion.blocks,
        contains(const CookEntryMissing(lineId: 'a', itemId: 'ghost')),
      );
    });

    test('nutrition missing: the item lacks energy or a macro', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '300 g Reis', settlement: assigned({'i1': 300})),
          ],
        ),
        items: [stockItem('i1', 500, nutrition: null)],
      );

      expect(_line(view, 'a').nutritionMissing, isTrue);
      expect(_line(view, 'a').entryMissing, isFalse);
      expect(
        view.portion.blocks,
        contains(const CookNutritionMissing(lineId: 'a', itemId: 'i1')),
      );
    });

    test('the flags belong to their own line', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '300 g Reis', settlement: assigned({'ghost': 300})),
            textLine('b', '100 g Mehl', settlement: assigned({'i1': 100})),
          ],
        ),
        items: [stockItem('i1', 500)],
      );

      expect(_line(view, 'a').entryMissing, isTrue);
      expect(_line(view, 'b').entryMissing, isFalse);
      expect(_line(view, 'b').pictureItem?.id, 'i1');
    });

    test('onlyAvailable carries the short item when the second take is', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine(
              'a',
              '300 g Reis',
              settlement: assigned({'i1': 100, 'i2': 200}),
            ),
          ],
        ),
        items: [stockItem('i1', 500), stockItem('i2', 50)],
      );

      final short = _line(view, 'a').onlyAvailable;
      final block = view.portion.blocks.whereType<CookStockShort>().single;

      expect(short?.item.id, block.itemId);
      expect(short?.item.id, 'i2');
      expect(short?.available, 50);
    });

    test('itemCount counts the takes still in the Vorrat', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine(
              'a',
              '300 g Reis',
              settlement: assigned({'gone': 100, 'i1': 100, 'i2': 100}),
            ),
          ],
        ),
        items: [stockItem('i1', 500), stockItem('i2', 500)],
      );

      expect(_line(view, 'a').itemCount, 2);
      expect(_line(view, 'a').pictureItem?.id, 'i1');
    });

    group('a take of 0', () {
      KochmodusLineView lineWith(
        Map<String, int> takes, {
        String text = '300 g Reis',
        List<String> added = const [],
      }) => _line(
        _view(
          buildCookRun(
            pots: _pots,
            lines: [
              textLine(
                'a',
                text,
                settlement: assigned(takes),
                addedItemIds: added,
              ),
            ],
          ),
          items: [stockItem('i1', 500), stockItem('i2', 500)],
        ),
        'a',
      );

      test('is not named next to a take', () {
        final line = lineWith({'i1': 300, 'i2': 0});

        expect(line.itemCount, 1);
        expect(line.pictureItem?.id, 'i1');
      });

      test('is not named first or pictured', () {
        final line = lineWith({'i1': 0, 'i2': 300});

        expect(line.itemCount, 1);
        expect(line.pictureItem?.id, 'i2');
        expect(line.taken, 300);
      });

      test('leaves the first item when nothing takes anything', () {
        final line = lineWith({'i1': 0, 'i2': 0});

        expect(line.itemCount, 1);
        expect(line.pictureItem?.id, 'i1');
      });

      test('of a gone item changes no weight, entry or weighing', () {
        final line = lineWith({'gone': 0, 'i1': 300});

        expect(line.weight, const CookWeightExact(300));
        expect(line.entryMissing, isFalse);
        expect(line.canFollowWeight, isTrue);
        expect(line.pictureItem?.id, 'i1');
      });

      test('counts in no kcal', () {
        final view = _view(
          buildCookRun(
            pots: _pots,
            lines: [
              textLine(
                'a',
                '300 g Reis',
                settlement: assigned({'i1': 300, 'bare': 0}),
              ),
            ],
          ),
          items: [
            stockItem('i1', 500),
            stockItem('bare', 500, nutrition: null),
          ],
        );

        expect(view.kcalPerPortion, 75);
        expect(view.portion.blocks.whereType<CookNutritionMissing>(), isEmpty);
      });

      test('a line that takes only from added items follows the recipe', () {
        final line = lineWith({'i1': 200, 'i2': 0}, added: const ['i1']);

        expect(line.ownAmountFor(300), isNull);
        expect(lineWith({'i1': 0, 'i2': 200}).ownAmountFor(300), isNull);
      });
    });

    test('names the blocks short, gone, nutrition, then open lines', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '300 g Reis', settlement: assigned({'i1': 300})),
            textLine('b', '100 g Mehl', settlement: assigned({'ghost': 100})),
            textLine('c', '100 g Zucker', settlement: assigned({'i3': 100})),
            textLine('d', 'Salz'),
          ],
        ),
        items: [stockItem('i1', 100), stockItem('i3', 500, nutrition: null)],
      );

      expect(view.portion.blocks.take(3).map((block) => block.runtimeType), [
        CookStockShort,
        CookEntryMissing,
        CookNutritionMissing,
      ]);
      expect(view.portion.blocks.last, const CookLinesOpen(1));
    });
  });

  group('weight', () {
    test('exact weight for items kept in grams', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '300 g Reis', settlement: assigned({'i1': 300})),
          ],
        ),
        items: [stockItem('i1', 500)],
      );

      expect(_line(view, 'a').weight, const CookWeightExact(300));
      expect(view.estimatedCount, 0);
    });

    test('weighed beats exact', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine(
              'a',
              '300 g Reis',
              settlement: assigned({'i1': 300}),
              weighed: 280,
            ),
          ],
        ),
        items: [stockItem('i1', 500)],
      );

      expect(_line(view, 'a').weight, const CookWeightWeighed(280));
      expect(view.estimatedCount, 0);
    });

    test('Gewicht fehlt: an item that is gone has no weight', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '300 g Reis', settlement: assigned({'ghost': 300})),
            textLine('b', '100 g Mehl', settlement: assigned({'i1': 100})),
          ],
        ),
        items: [stockItem('i1', 500)],
      );

      final ghost = _line(view, 'a');
      expect(ghost.weight, const CookWeightMissing());
      // Weighing a food that left the Vorrat helps nothing: the line is
      // neither estimated nor under "Noch zu wiegen".
      expect(view.estimatedCount, 0);
      expect(view.estimated.map((line) => line.id), isNot(contains('a')));
      expect(view.toWeigh.map((line) => line.id), isNot(contains('a')));
    });

    test('a piece item with a serving size is estimated, not missing', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '2 Zwiebeln', settlement: assigned({'i1': 2})),
          ],
        ),
        items: [
          stockItem(
            'i1',
            5,
            unit: InventoryAmountUnit.piece,
            servingQuantity: 80,
            servingQuantityUnit: 'g',
          ),
        ],
      );

      expect(_line(view, 'a').weight, const CookWeightEstimated(160));
      expect(view.estimatedCount, 1);
    });

    test('an ignored line does not count', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [textLine('a', 'Salz', settlement: const LineIgnored())],
        ),
      );

      expect(_line(view, 'a').weight, const CookWeightNotCounted());
      expect(view.estimatedCount, 0);
    });
  });

  group('line text and amounts', () {
    test('scales the recipe line to the portions of the run', () {
      final view = _view(
        buildCookRun(portions: 8, lines: [textLine('a', '500 g Hack')]),
      );
      final line = _line(view, 'a');

      expect(line.text, '1000 g Hack');
      expect(line.parsed, isNotNull);
    });

    test('the own amount replaces the recipe amount', () {
      final view = _view(
        buildCookRun(lines: [textLine('a', '500 g Hack', amount: 300)]),
      );
      final line = _line(view, 'a');

      expect(line.text, '300 g Hack');
      expect(line.parsed, isNotNull);
    });

    test('a line without amount keeps its text', () {
      final view = _view(buildCookRun(lines: [textLine('a', ' Salz ')]));
      final line = _line(view, 'a');

      expect(line.text, 'Salz');
      expect(line.parsed, isNull);
      expect(line.need, isNull);
    });

    test('pieces show no unit', () {
      final view = _view(buildCookRun(lines: [textLine('a', '2 Zwiebeln')]));

      expect(_line(view, 'a').text, '2 Zwiebeln');
    });

    test('taken sums the takes in the unit of the first item', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine(
              'a',
              '400 g Reis',
              settlement: assigned({'i1': 250, 'i2': 150}),
            ),
          ],
        ),
        items: [stockItem('i1', 500), stockItem('i2', 500)],
      );
      final line = _line(view, 'a');

      expect(line.taken, 400);
      expect(line.needFromItem?.amount, 400);
      expect(line.takes.map((take) => take.itemId), ['i1', 'i2']);
    });

    test('taken is 0 without a take', () {
      final view = _view(buildCookRun(lines: [textLine('a', '400 g Reis')]));

      expect(_line(view, 'a').taken, 0);
      expect(_line(view, 'a').needFromItem, isNull);
    });
  });

  group('portion blocks', () {
    CookRun portionRun(List<CookRunLine> lines) => buildCookRun(
      step: CookRunStep.portion,
      pots: _pots,
      steps: const [],
      lines: lines,
    );

    test('blockLine is the line of a short, gone or nutrition block', () {
      final short = _view(
        portionRun([
          textLine('a', 'Reis', settlement: assigned({'i1': 300})),
        ]),
        items: [stockItem('i1', 100)],
      );
      final gone = _view(
        portionRun([
          textLine('b', 'Mehl', settlement: assigned({'ghost': 100})),
        ]),
      );
      final plain = _view(
        portionRun([
          textLine('c', 'Zucker', settlement: assigned({'i3': 100})),
        ]),
        items: [stockItem('i3', 500, nutrition: null)],
      );

      expect(short.portion.blockLine?.id, 'a');
      expect(gone.portion.blockLine?.id, 'b');
      expect(plain.portion.blockLine?.id, 'c');
    });

    test('blockLine is empty when the first block is not about a line', () {
      final view = _view(
        buildCookRun(
          step: CookRunStep.portion,
          pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
          steps: const [],
          lines: [
            textLine(
              'a',
              'Reis',
              settlement: assigned({'i1': 100}),
              potId: cookPotA.id,
            ),
            textLine('b', 'Mehl'),
          ],
        ),
        items: [stockItem('i1', 500)],
      );

      expect(view.portion.blocks.first, isA<CookPotUnweighed>());
      expect(view.portion.blockLine, isNull);
    });

    test('unweighedPots counts the pots without weight', () {
      final view = _view(
        portionRun([
          textLine(
            'a',
            'Reis',
            settlement: assigned({'i1': 100}),
            potId: cookPotA.id,
          ),
          textLine(
            'b',
            'Mehl',
            settlement: assigned({'i1': 100}),
            potId: cookPotB.id,
          ),
        ]),
        items: [stockItem('i1', 500)],
      );

      expect(view.portion.unweighedPots, 2);
    });
  });

  group('refillKochmodusTakes', () {
    CookRun refill(
      CookRun run,
      List<String> ids, {
      List<InventoryItem>? items,
      Map<String, int> others = const {},
    }) => refillKochmodusTakes(
      run,
      'a',
      ids,
      items: items ?? [stockItem('i1', 500), stockItem('i2', 500)],
      otherReservations: others,
      parser: const TemplateIngredientParser(),
    );

    final run = buildCookRun(lines: [textLine('a', '300 g Reis')]);

    String takes(CookRun run) => switch (run.lineOf('a')!.settlement) {
      LineAssigned(:final takes) =>
        takes.map((take) => '${take.itemId}:${take.amount}').join(','),
      final other => other.runtimeType.toString(),
    };

    test('takes the need from one item', () {
      expect(takes(refill(run, ['i1'])), 'i1:300');
    });

    test('goes on with the next item when the first is short', () {
      final result = refill(
        run,
        ['i1', 'i2'],
        items: [stockItem('i1', 100), stockItem('i2', 500)],
      );

      expect(takes(result), 'i1:100,i2:200');
    });

    test('leaves out what other runs reserve', () {
      final result = refill(run, ['i1', 'i2'], others: const {'i1': 400});

      expect(takes(result), 'i1:100,i2:200');
    });

    test('no items open the line again', () {
      final assignedRun = refill(run, ['i1']);

      expect(takes(refill(assignedRun, const [])), 'LineOpen');
    });

    test('an item gone from the Vorrat keeps its take', () {
      final assignedRun = run.withTakes('a', const [
        ItemTake(itemId: 'gone', amount: 100),
        ItemTake(itemId: 'i1', amount: 200),
      ]);

      final result = refill(
        assignedRun,
        ['gone', 'i1'],
        items: [stockItem('i1', 500)],
      );

      expect(takes(result), 'gone:100,i1:300');
    });

    test('a line with its own amount and an added item follows the need', () {
      final own = buildCookRun(
        lines: [
          textLine(
            'a',
            '300 g Reis',
            amount: 100,
            settlement: assigned({'added': 200}),
            addedItemIds: ['added'],
          ),
        ],
      );

      final result = refill(own, ['added'], items: [stockItem('added', 500)]);

      expect(takes(result), 'added:100');
    });

    test('an added item missing from the items keeps its take', () {
      final own = buildCookRun(
        lines: [
          textLine(
            'a',
            '300 g Reis',
            settlement: assigned({'added': 200}),
            addedItemIds: ['added'],
          ),
        ],
      );

      final result = refill(own, ['added'], items: const []);

      expect(takes(result), 'added:200');
    });

    test('throws when the line is gone', () {
      expect(
        () => refillKochmodusTakes(
          run,
          'nope',
          const ['i1'],
          items: [stockItem('i1', 500)],
          otherReservations: const {},
          parser: const TemplateIngredientParser(),
        ),
        throwsStateError,
      );
    });
  });

  group('availableForLine', () {
    final assignedRun = buildCookRun(
      pots: _pots,
      lines: [
        textLine('a', '300 g Reis', settlement: assigned({'i1': 300})),
      ],
    );

    test('a line with no takes has nothing to name', () {
      final view = _view(
        buildCookRun(pots: _pots, lines: [textLine('a', '300 g Reis')]),
        items: [stockItem('i1', 500)],
      );

      expect(_line(view, 'a').availableForLine, isNull);
    });

    test('the whole stock of the item counts, more than the line needs', () {
      final view = _view(assignedRun, items: [stockItem('i1', 500)]);

      expect(_line(view, 'a').availableForLine, 500);
    });

    test('several takes add up', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine(
              'a',
              '300 g Reis',
              settlement: assigned({'i1': 100, 'i2': 200}),
            ),
          ],
        ),
        items: [stockItem('i1', 400), stockItem('i2', 250)],
      );

      expect(_line(view, 'a').availableForLine, 650);
    });

    test('other runs reserve their share', () {
      final view = _view(
        assignedRun,
        items: [stockItem('i1', 500)],
        others: const {'i1': 150},
      );

      expect(_line(view, 'a').availableForLine, 350);
    });

    test('the other lines of the run take their share', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '300 g Reis', settlement: assigned({'i1': 300})),
            textLine('b', '100 g Reis', settlement: assigned({'i1': 100})),
          ],
        ),
        items: [stockItem('i1', 500)],
      );

      expect(_line(view, 'a').availableForLine, 400);
      expect(_line(view, 'b').availableForLine, 200);
    });

    test('an item reserved away gives 0', () {
      final view = _view(
        assignedRun,
        items: [stockItem('i1', 100)],
        others: const {'i1': 400},
      );

      expect(_line(view, 'a').availableForLine, 0);
    });

    test('a take in a unit that cannot supply the line gives null', () {
      final view = _view(
        assignedRun,
        items: [
          stockItem('i1', 6000, unit: InventoryAmountUnit.piece, scale: 1000),
        ],
      );

      expect(_line(view, 'a').availableForLine, isNull);
    });

    test('an ml item supplies grams 1:1', () {
      final view = _view(
        assignedRun,
        items: [stockItem('i1', 500, unit: InventoryAmountUnit.milliliter)],
      );

      expect(_line(view, 'a').availableForLine, 500);
    });

    test('pieces count in the unit of the line', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '2 Eier', settlement: assigned({'i1': 2000})),
          ],
        ),
        items: [
          stockItem('i1', 6000, unit: InventoryAmountUnit.piece, scale: 1000),
        ],
      );

      expect(_line(view, 'a').availableForLine, 6);
    });

    test('a take of an item gone from the Vorrat gives null', () {
      final view = _view(assignedRun);

      expect(_line(view, 'a').availableForLine, isNull);
    });
  });

  group('ownAmountFor', () {
    test('the recipe amount clears the own amount, others keep it', () {
      final view = _view(
        buildCookRun(pots: _pots, lines: [textLine('a', '300 g Reis')]),
      );
      final line = _line(view, 'a');
      final recipe = line.parsed!.amount;

      expect(line.ownAmountFor(recipe), isNull);
      expect(line.ownAmountFor(170), 170);
      expect(line.ownAmountFor(recipe + 1), recipe + 1);
      expect(line.ownAmountFor(0), 0);
    });

    test('a line without amount in its text keeps what is typed', () {
      final view = _view(
        buildCookRun(pots: _pots, lines: [textLine('a', 'Salz')]),
      );
      final line = _line(view, 'a');

      expect(line.parsed, isNull);
      expect(line.ownAmountFor(5), 5);
      expect(line.ownAmountFor(0), 0);
    });

    group('a recipe amount with a part of a unit', () {
      KochmodusLineView partLine(
        String text, {
        int portions = 4,
        List<InventoryItem> items = const [],
        LineSettlement settlement = const LineOpen(),
      }) => _line(
        _view(
          buildCookRun(
            pots: _pots,
            portions: portions,
            lines: [textLine('a', text, settlement: settlement)],
          ),
          items: items,
        ),
        'a',
      );

      test('a whole number that rounds to it is an own amount', () {
        final quarter = partLine('1 Zwiebel', portions: 1);
        expect(quarter.text, '1/4 Zwiebel');
        expect(quarter.ownAmountFor(1), 1);

        final eggs = partLine('3 Eier', portions: 3);
        expect(eggs.text, '2,25 Eier');
        expect(eggs.ownAmountFor(2), 2);

        final oil = partLine('1,5 EL Öl');
        expect(oil.text, '1,5 EL Öl');
        expect(oil.ownAmountFor(2), 2);
      });

      test('whole amounts it scales to still clear it', () {
        expect(partLine('1 Zwiebel', portions: 8).ownAmountFor(2), isNull);
      });

      test(
        'an item counted whole shows the whole number, that is the recipe',
        () {
          final line = partLine(
            '1/2 Zitrone',
            items: [packItem('w', 5)],
            settlement: assigned({'w': 1}),
          );
          expect(line.text, '1 Zitrone');
          expect(line.ownAmountFor(1), isNull);
          expect(line.ownAmountFor(2), 2);
        },
      );
    });

    test('a line that takes only from added items follows the recipe', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine(
              'a',
              '300 g Reis',
              settlement: assigned({'added': 300}),
              addedItemIds: const ['added'],
            ),
          ],
        ),
        items: [stockItem('added', 500)],
      );
      final line = _line(view, 'a');

      expect(line.ownAmountFor(line.parsed!.amount), isNull);
      expect(line.ownAmountFor(170), 170);
    });

    test('an added item next to a Vorrat item clears it like any line', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine(
              'a',
              '300 g Reis',
              settlement: assigned({'added': 100, 'rice': 200}),
              addedItemIds: const ['added'],
            ),
          ],
        ),
        items: [stockItem('added', 500), stockItem('rice', 500)],
      );
      final line = _line(view, 'a');

      expect(line.ownAmountFor(line.parsed!.amount), isNull);
    });
  });

  group('weighsInstead and takesNothing', () {
    test('1 Möhre on an item kept in grams has only a weight to say', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '1 Möhre', settlement: assigned({'g': 0})),
          ],
        ),
        items: [stockItem('g', 500)],
      );
      final line = _line(view, 'a');

      expect(line.weighsInstead, isTrue);
      expect(line.takesNothing, isTrue);
    });

    test('grams on a gram item and on an ml item do not weigh instead', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '200 g Reis', settlement: assigned({'g': 200})),
            textLine('b', '200 g Öl', settlement: assigned({'ml': 200})),
          ],
        ),
        items: [
          stockItem('g', 500),
          stockItem('ml', 500, unit: InventoryAmountUnit.milliliter),
        ],
      );

      expect(_line(view, 'a').weighsInstead, isFalse);
      expect(_line(view, 'b').weighsInstead, isFalse);
      expect(_line(view, 'b').takesNothing, isFalse);
    });

    test('a weighed line takes the weight and no longer takes nothing', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine(
              'a',
              '1 Möhre',
              settlement: assigned({'g': 60}),
              weighed: 60,
            ),
          ],
        ),
        items: [stockItem('g', 500)],
      );
      final line = _line(view, 'a');

      expect(line.takesNothing, isFalse);
      expect(line.needFromItem?.amount, 60);
      expect(line.weighsInstead, isTrue);
    });

    test('Salz without amount takes nothing on purpose, no block', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', 'Salz', settlement: assigned({'g': 0})),
          ],
        ),
        items: [stockItem('g', 500)],
      );

      expect(_line(view, 'a').takesNothing, isFalse);
    });
  });

  group('canFollowWeight and needsOtherFood', () {
    final items = [
      stockItem('g', 500),
      packItem('pack', 2),
      stockItem('egg', 3000, unit: InventoryAmountUnit.piece, scale: 1000),
    ];

    KochmodusView view(List<CookRunLine> lines) => _view(
      buildCookRun(pots: _pots, lines: lines),
      items: items,
    );

    test('1 EL Senf on a whole pack must pick another food', () {
      final line = _line(
        view([
          textLine('a', '1 EL Senf', settlement: assigned({'pack': 0})),
        ]),
        'a',
      );

      expect(line.takesNothing, isTrue);
      expect(line.canFollowWeight, isFalse);
      expect(line.needsOtherFood, isTrue);
      expect(line.weighsInstead, isFalse);
    });

    test('200 g Reis on an item counted in pieces must pick another', () {
      final line = _line(
        view([
          textLine('a', '200 g Reis', settlement: assigned({'egg': 0})),
        ]),
        'a',
      );

      expect(line.needsOtherFood, isTrue);
    });

    test('1 Möhre on an item kept in grams is told to weigh', () {
      final line = _line(
        view([
          textLine('a', '1 Möhre', settlement: assigned({'g': 0})),
        ]),
        'a',
      );

      expect(line.canFollowWeight, isTrue);
      expect(line.needsOtherFood, isFalse);
    });

    test('the block of such a line says it cannot weigh', () {
      final built = view([
        textLine('a', '1 EL Senf', settlement: assigned({'pack': 0})),
        textLine('b', '1 Möhre', settlement: assigned({'g': 0})),
      ]);

      expect(built.portion.blocks.whereType<CookLineWithoutTake>().toList(), [
        const CookLineWithoutTake('a', canWeigh: false),
        const CookLineWithoutTake('b', canWeigh: true),
      ]);
    });

    test('is not in the lines still to weigh', () {
      final built = view([
        textLine('a', '1 EL Senf', settlement: assigned({'pack': 0})),
        textLine('b', '1 Möhre', settlement: assigned({'g': 0})),
      ]);

      expect(built.estimated.map((line) => line.id), ['b']);
    });

    test('a pack line that takes something is still estimated', () {
      final built = view([
        textLine('a', 'Tomaten', settlement: assigned({'pack': 1})),
      ]);

      expect(built.estimated.map((line) => line.id), ['a']);
    });
  });

  group('stockLeftOf', () {
    final first = stockItem('first', 300);
    final second = stockItem('second', 400);

    KochmodusView built({Map<String, int> others = const {}}) => _view(
      buildCookRun(
        pots: _pots,
        lines: [
          textLine(
            'a',
            '500 g Hack',
            settlement: assigned({'first': 300, 'second': 200}),
          ),
        ],
      ),
      items: [first, second],
      others: others,
    );

    test('is what its own food has, not what the first food has', () {
      final view = built();
      final line = _line(view, 'a');

      expect(view.stockLeftOf(line, second), 400);
      expect(view.stockLeftOf(line, first), 300);
    });

    test('takes what the other runs hold off its own food only', () {
      final view = built(others: const {'second': 150});
      final line = _line(view, 'a');

      expect(view.stockLeftOf(line, second), 250);
      expect(view.stockLeftOf(line, first), 300);
    });
  });

  group('a line in standard spoons', () {
    const tenMl = CookLineConversion(
      amountPerPiece: 10,
      unit: TemplateIngredientUnit.milliliter,
    );

    KochmodusView spoonView(
      String text,
      Map<String, int> takes,
      List<InventoryItem> items, {
      CookLineConversion? conversion,
      List<String> added = const [],
    }) => _view(
      buildCookRun(
        pots: _pots,
        lines: [
          textLine(
            'a',
            text,
            settlement: assigned(takes),
            conversion: conversion,
            addedItemIds: added,
          ),
        ],
      ),
      items: items,
    );

    test('1 EL Honig on a jar in g takes 15 g, to weigh and never short', () {
      final view = spoonView(
        '1 EL Honig',
        {'jar': 15},
        [stockItem('jar', 250)],
      );
      final line = _line(view, 'a');

      expect(line.weight, const CookWeightEstimated(15, toWeigh: true));
      expect(line.shortBy, isNull);
      expect(view.estimatedCount, 1);
      expect(view.estimated.map((line) => line.id), ['a']);
      expect(view.toWeigh.map((line) => line.id), ['a']);
    });

    test('2 EL Öl with the recipe weight of 10 ml is 20 ml, to weigh', () {
      final view = spoonView(
        '2 EL Öl',
        {'oil': 20},
        [stockItem('oil', 500, unit: InventoryAmountUnit.milliliter)],
        conversion: tenMl,
      );

      expect(
        _line(view, 'a').weight,
        const CookWeightEstimated(20, toWeigh: true),
      );
      expect(view.estimatedCount, 1);
    });

    test(
      '1 TL Zimt with 4 g left takes 4 g, is not short, one tap takes it',
      () {
        final cinnamon = stockItem('z', 4);
        final run = buildCookRun(
          pots: _pots,
          lines: [textLine('a', '1 TL Zimt')],
        );
        final refilled = refillKochmodusTakes(
          run,
          'a',
          const ['z'],
          items: [cinnamon],
          otherReservations: const {},
          parser: const TemplateIngredientParser(),
        );
        final takes = (refilled.lineOf('a')!.settlement as LineAssigned).takes;

        expect(takes.map((take) => (take.itemId, take.amount)), [('z', 4)]);

        final view = _view(refilled, items: [cinnamon]);

        expect(_line(view, 'a').shortBy, isNull);
        expect(
          _line(view, 'a').weight,
          const CookWeightEstimated(4, toWeigh: true),
        );
        expect(view.portion.blocks.whereType<CookStockShort>(), isEmpty);
        expect(kochmodusOffers(view, 'a').single.missing, 0);
      },
    );

    test('1 TL Zimt with nothing left is short by 1 TL', () {
      // The 4 g that are left are held by another cooking.
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '1 TL Zimt', settlement: assigned({'z': 5})),
          ],
        ),
        items: [stockItem('z', 4)],
        others: const {'z': 4},
      );

      expect(_line(view, 'a').shortBy, 1);
    });

    test('1 EL Zimt taking 15 g from 8 g left is asked, one tap takes the 8 g, '
        'and nothing left reads as short', () {
      final cinnamon = stockItem('z', 8);
      final run = buildCookRun(
        pots: _pots,
        lines: [
          textLine('a', '1 EL Zimt', settlement: assigned({'z': 15})),
          textLine('done', '100 g Reis', settlement: assigned({'r': 100})),
        ],
      );
      final items = [cinnamon, stockItem('r', 500)];

      final view = _view(run, items: items);
      final line = _line(view, 'a');

      expect(view.toAnswer.map((line) => line.id), ['a']);
      expect(view.openCount, 1);
      expect(line.shortBy, isNull);
      final only = kochmodusGuessedTakeOnly(line);
      expect(only, isNotNull);
      expect(only!.item.id, 'z');
      expect(only.available, 8);

      // "Nur 8 g nehmen" assigns the line's items again.
      final refilled = refillKochmodusTakes(
        run,
        'a',
        [for (final take in line.takes) take.itemId],
        items: items,
        otherReservations: const {},
        parser: const TemplateIngredientParser(),
      );
      final takes = (refilled.lineOf('a')!.settlement as LineAssigned).takes;
      expect(takes.map((take) => (take.itemId, take.amount)), [('z', 8)]);

      final after = _view(refilled, items: items);
      expect(after.portion.blocks.whereType<CookStockShort>(), isEmpty);
      expect(after.toAnswer, isEmpty);
      expect(kochmodusGuessedTakeOnly(_line(after, 'a')), isNull);
    });

    test('1/2 TL Zimt with nothing left is short, and the row says so', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '1/2 TL Zimt', settlement: assigned({'z': 3})),
          ],
        ),
        items: [stockItem('z', 4)],
        others: const {'z': 4},
      );
      final line = _line(view, 'a');
      final l10n = AppLocalizationsEn();

      expect(line.shortBy, isNotNull);
      expect(kochmodusGuessedTakeOnly(line), isNull);
      expect(view.toAnswer.map((line) => line.id), ['a']);
      expect(
        kochmodusRowWord(l10n, line, onCard: false),
        l10n.kochmodusRowShort,
      );
    });

    group('with an empty stored take from an older run', () {
      final jar = stockItem('jar', 500);

      test('waits for a weight instead of taking nothing', () {
        final view = spoonView('1 EL Honig', {'jar': 0}, [jar]);
        final line = _line(view, 'a');

        expect(line.weighsInstead, isTrue);
        expect(line.takesNothing, isTrue);
        expect(line.weight, const CookWeightMissing());
        expect(view.portion.blocks.whereType<CookLineWithoutTake>().toList(), [
          const CookLineWithoutTake('a', canWeigh: true),
        ]);
      });

      test('names an added food that supplies nothing yet', () {
        final view = spoonView(
          '1 EL Honig',
          {'jar': 0},
          [jar],
          added: const ['jar'],
        );

        expect(_line(view, 'a').uncounted?.id, 'jar');
      });
    });
  });

  group('weighed lines without a need', () {
    test('show the weighed grams and open the keypad', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', 'Öl', settlement: assigned({'g': 30}), weighed: 30),
          ],
        ),
        items: [stockItem('g', 500)],
      );
      final line = _line(view, 'a');

      expect(line.need, isNull);
      expect(line.weighsInstead, isTrue);
      expect(line.needFromItem?.amount, 30);
      expect(line.needFromItem?.unit, InventoryAmountUnit.gram);
      expect(line.taken, 30);
    });

    test('without a weight and without need they do not', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', 'Öl', settlement: assigned({'g': 30})),
          ],
        ),
        items: [stockItem('g', 500)],
      );

      expect(_line(view, 'a').weighsInstead, isFalse);
    });

    test('a line on a whole pack never weighs instead', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', 'Senf', settlement: assigned({'p': 1}), weighed: 30),
          ],
        ),
        items: [packItem('p', 2)],
      );

      expect(_line(view, 'a').weighsInstead, isFalse);
    });
  });

  group('mixed g and ml items', () {
    test('count together in taken', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine(
              'a',
              '300 g Milch',
              settlement: assigned({'g': 100, 'ml': 200}),
            ),
          ],
        ),
        items: [
          stockItem('g', 500),
          stockItem('ml', 500, unit: InventoryAmountUnit.milliliter),
        ],
      );
      final line = _line(view, 'a');

      expect(line.needFromItem?.amount, 300);
      expect(line.taken, 300);
    });

    test('items in another scale do not add up', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine(
              'a',
              '300 g Milch',
              settlement: assigned({'g': 100, 'kg': 2000}),
            ),
          ],
        ),
        items: [stockItem('g', 500), stockItem('kg', 5000, scale: 1000)],
      );

      expect(_line(view, 'a').taken, 100);
    });

    test('only N there names the short item in its own unit', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine(
              'a',
              '300 g Milch',
              settlement: assigned({'g': 100, 'ml': 200}),
            ),
          ],
        ),
        items: [
          stockItem('g', 500),
          stockItem('ml', 150, unit: InventoryAmountUnit.milliliter),
        ],
      );
      final short = _line(view, 'a').onlyAvailable!;

      expect(short.item.id, 'ml');
      expect(short.item.amountUnit, InventoryAmountUnit.milliliter);
      expect(short.available, 150);
    });
  });

  group('finished', () {
    PreparedMeal meal({
      String id = 'm1',
      String name = 'Eintopf',
      int portions = 4,
      double kcal = 800,
      bool? inPieces,
    }) => preparedMealTestData(id: id, name: name, totalPortions: portions)
        .copyWith(
          totalKcal: kcal,
          totalProtein: 41,
          totalCarbs: 82,
          totalFat: 21,
          servedInPieces: inPieces,
        );

    KochmodusDone? done(
      List<PreparedMeal> meals, {
      bool inCans = false,
      bool inCookbook = false,
    }) => buildKochmodusView(
      run: buildCookRun(pots: _pots),
      saved: false,
      ended: true,
      busy: false,
      reopened: false,
      finished: (meals: meals, inCans: inCans, inCookbook: inCookbook),
      tab: null,
      items: const [],
      otherReservations: const {},
      utensils: const [],
      parser: const TemplateIngredientParser(),
    ).finished;

    test('is null while nothing is finished', () {
      expect(_view(buildCookRun(pots: _pots)).finished, isNull);
    });

    test('maps each meal with its id, name and count', () {
      final result = done([
        meal(),
        meal(id: 'm2', name: 'Suppe', portions: 6),
      ])!;

      expect(result.meals.map((meal) => meal.id), ['m1', 'm2']);
      expect(result.meals.map((meal) => meal.name), ['Eintopf', 'Suppe']);
      expect(result.meals.map((meal) => meal.count), [4, 6]);
    });

    test('serves a portion by default', () {
      expect(done([meal()])!.meals.single.serving, KochmodusServing.portion);
    });

    test('serves a piece for a meal served in pieces', () {
      expect(
        done([meal(inPieces: true)])!.meals.single.serving,
        KochmodusServing.piece,
      );
    });

    test('serves a can for meals that went into cans', () {
      expect(
        done([meal()], inCans: true)!.meals.single.serving,
        KochmodusServing.can,
      );
    });

    test('pieces win over cans', () {
      expect(
        done([meal(inPieces: true)], inCans: true)!.meals.single.serving,
        KochmodusServing.piece,
      );
    });

    test('rounds the nutrition of one serving', () {
      final serving = done([meal(portions: 3)])!.meals.single.perServing!;

      // 800 / 3, 41 / 3, 82 / 3, 21 / 3.
      expect(serving, (kcal: 267, protein: 14, carbs: 27, fat: 7));
    });

    test('has no nutrition for a meal without energy', () {
      expect(done([meal(kcal: 0)])!.meals.single.perServing, isNull);
    });

    test('has no nutrition for a meal that rounds to 0 kcal', () {
      expect(done([meal(kcal: 1)])!.meals.single.perServing, isNull);
    });

    test('has no nutrition for a meal without servings', () {
      expect(done([meal(portions: 0)])!.meals.single.perServing, isNull);
    });

    test('keeps whether free cooking became a recipe', () {
      expect(done([meal()], inCookbook: true)!.inCookbook, isTrue);
      expect(done([meal()])!.inCookbook, isFalse);
    });

    test('has no meals for an empty summary', () {
      expect(done(const [])!.meals, isEmpty);
    });
  });

  group('"Noch zu wiegen": a guessed weight is never a fact', () {
    const perPiece = CookLineConversion(
      amountPerPiece: 150,
      unit: TemplateIngredientUnit.gram,
    );

    KochmodusView onion(
      InventoryItem item, {
      String text = '1 Zwiebel',
      Map<String, int> takes = const {},
      CookLineConversion? conversion,
      int? weighed,
      LineSettlement? settlement,
    }) => _view(
      buildCookRun(
        pots: _pots,
        lines: [
          textLine(
            'a',
            text,
            conversion: conversion,
            weighed: weighed,
            settlement: settlement ?? assigned(takes),
          ),
        ],
      ),
      items: [item],
    );

    final grams = stockItem('i1', 1000).copyWith(name: 'Zwiebel');

    test('a piece on a food kept in g without a conversion: missing, to '
        'weigh', () {
      final view = onion(grams, takes: const {'i1': 0});

      expect(_line(view, 'a').weight, const CookWeightMissing());
      expect(view.toWeigh.map((line) => line.id), ['a']);
    });

    test('with a conversion of 150 g it is a guess, still to weigh', () {
      final view = onion(grams, takes: const {'i1': 150}, conversion: perPiece);
      final de = AppLocalizationsDe();

      expect(
        _line(view, 'a').weight,
        const CookWeightEstimated(150, toWeigh: true),
      );
      expect(view.toWeigh.map((line) => line.id), ['a']);
      expect(view.estimatedCount, 1);
      expect(
        de.kochmodusWeightEstimated(kochmodusWeightText(de, 150, grams)),
        '≈ 150\u00A0g geschätzt',
      );
    });

    test('weighing it makes it a fact and takes it out of the list', () {
      final view = onion(
        grams,
        takes: const {'i1': 150},
        conversion: perPiece,
        weighed: 120,
      );

      expect(_line(view, 'a').weight, const CookWeightWeighed(120));
      expect(view.toWeigh, isEmpty);
    });

    test('on a food kept in pieces with a serving size: estimated, not to '
        'weigh', () {
      final eggs = stockItem(
        'i1',
        3000,
        unit: InventoryAmountUnit.piece,
        scale: 1000,
        servingQuantity: 80,
        servingQuantityUnit: 'g',
      ).copyWith(name: 'Zwiebel');
      final view = onion(eggs, takes: const {'i1': 1000});

      expect(_line(view, 'a').weight, const CookWeightEstimated(80));
      expect(view.toWeigh, isEmpty);
    });

    test(
      'on a food kept in pieces without a piece size: missing, to weigh',
      () {
        final plain = stockItem(
          'i1',
          3000,
          unit: InventoryAmountUnit.piece,
          scale: 1000,
        ).copyWith(name: 'Zwiebel');
        final view = onion(plain, takes: const {'i1': 1000});

        expect(_line(view, 'a').weight, const CookWeightMissing());
        expect(view.toWeigh.map((line) => line.id), ['a']);
      },
    );

    test('a line in spoons on a food kept in ml is to weigh', () {
      final oil = stockItem(
        'i1',
        500,
        unit: InventoryAmountUnit.milliliter,
      ).copyWith(name: 'Öl');
      final view = onion(oil, text: '2 EL Öl', takes: const {'i1': 30});

      expect(
        _line(view, 'a').weight,
        const CookWeightEstimated(30, toWeigh: true),
      );
      expect(view.toWeigh.map((line) => line.id), ['a']);
    });

    test('a line that does not count is never to weigh', () {
      final view = onion(grams, text: 'Salz', settlement: const LineIgnored());

      expect(_line(view, 'a').weight, const CookWeightNotCounted());
      expect(view.toWeigh, isEmpty);
    });
  });
}
