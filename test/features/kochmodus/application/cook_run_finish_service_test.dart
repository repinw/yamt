import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/kochmodus/application/cook_run_finish_service.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/recipes_exceptions.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../../../helpers/fake_prepared_meal_template_repository.dart';
import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'cook_services_harness.dart';

final _now = DateTime.utc(2026, 11, 7, 12);

/// The meal id of the pot [potId] of the run that `buildCookRun` makes.
String _mealId(String potId) => '${buildCookRun().cookingId}-$potId';

const _oneGross = CookMealDraft(
  potId: 'pot-a',
  name: 'Eintopf',
  count: 4,
  inPieces: false,
  grossWeight: 2400,
);

const _twoGross = CookMealDraft(
  potId: 'pot-b',
  name: 'Suppe',
  count: 2,
  inPieces: false,
  grossWeight: 1600,
);

CookPotChoice _pots(List<CookPot> pots, {bool inCans = false}) =>
    CookPotsChosen(pots: pots, inCans: inCans);

CookRun _oneRun({List<CookRunLine>? lines, List<CookMealDraft>? meals}) =>
    buildCookRun(
      step: CookRunStep.portion,
      pots: _pots(const [cookPotA]),
      meals: meals ?? const [_oneGross],
      lines:
          lines ??
          [
            textLine(
              'line-0',
              '300 g Reis',
              settlement: assigned({'rice': 300}),
            ),
            textLine(
              'line-1',
              '200 g Karotten',
              settlement: assigned({'carrots': 200}),
            ),
          ],
    );

class _OrderTemplates extends FakePreparedMealTemplateRepository {
  new(this.harness);

  final CookHarness harness;
  bool? runStillThereAtSave;
  int? stockAtSave;

  @override
  Future<bool> save(PreparedMeal template) async {
    runStillThereAtSave = await harness.storedRun('recipe-t1') != null;
    stockAtSave = (await harness.storedItem('rice'))?.currentAmount;
    return await super.save(template);
  }
}

// Ends the run right after the recipe is saved, like a finish that went
// through on another device.
class _EndingTemplates extends FakePreparedMealTemplateRepository {
  new(this.harness);

  final CookHarness harness;

  @override
  Future<bool> save(PreparedMeal template) async {
    final saved = await super.save(template);
    await harness.removeRun('recipe-t1');
    await harness.settle();
    return saved;
  }
}

void main() {
  late CookHarness harness;
  late CookRunFinishService service;

  setUp(() async {
    harness = await CookHarness.open();
    service = _service(harness);
    await harness.stock([
      stockItem('rice', 800),
      stockItem('carrots', 500),
      stockItem('salt', 100),
    ]);
  });

  Future<CookFinishSummary> finish() async {
    final summary = await service.finish('recipe-t1');
    await harness.settle();
    return summary;
  }

  group('one pot', () {
    test('writes one meal with a fixed id, the stock and no run', () async {
      await harness.start(_oneRun());

      final summary = await finish();

      expect(summary.meals, hasLength(1));
      expect(summary.meals.map((m) => m.totalPortions).sum, 4);
      expect(summary.inCookbook, isFalse);
      final meal = (await harness.storedMeal(_mealId('pot-a')))!;
      expect(meal.name, 'Eintopf');
      expect(meal.totalPortions, 4);
      expect(meal.components.map((c) => c.inventoryItemId), [
        'rice',
        'carrots',
      ]);
      expect((await harness.storedItem('rice'))!.currentAmount, 500);
      expect((await harness.storedItem('carrots'))!.currentAmount, 300);
      expect(await harness.storedRun('recipe-t1'), isNull);
    });

    test('weighs the pot: tare and net weight from the gross weight', () async {
      await harness.start(_oneRun());

      await finish();

      final meal = (await harness.storedMeal(_mealId('pot-a')))!;
      expect(meal.potTareWeight, 900);
      expect(meal.finalNetWeight, 1500);
      expect(meal.imageUrl, 'https://example.test/a.jpg');
    });

    test('a blank meal name falls back to the run name', () async {
      await harness.start(
        _oneRun(
          meals: [
            const CookMealDraft(
              potId: 'pot-a',
              name: '  ',
              count: 3,
              inPieces: false,
              grossWeight: 2400,
            ),
          ],
        ),
      );

      await finish();

      expect((await harness.storedMeal(_mealId('pot-a')))!.name, 'Eintopf');
    });

    test(
      'sums two lines that take from the same item into one change',
      () async {
        await harness.start(
          _oneRun(
            lines: [
              textLine(
                'line-0',
                '300 g Reis',
                settlement: assigned({'rice': 300}),
              ),
              textLine(
                'line-1',
                '100 g Reis',
                settlement: assigned({'rice': 100}),
              ),
            ],
          ),
        );

        await finish();

        final meal = (await harness.storedMeal(_mealId('pot-a')))!;
        expect(meal.components, hasLength(1));
        expect(meal.components.single.usedAmount, 400);
        expect((await harness.storedItem('rice'))!.currentAmount, 400);
        expect(await harness.eventCount(), 1);
      },
    );

    test('half a piece books half a piece and half its energy', () async {
      await harness.stock([
        stockItem('lemon', 3000, unit: InventoryAmountUnit.piece, scale: 1000),
        stockItem('whole', 1000, unit: InventoryAmountUnit.piece, scale: 1000),
      ]);
      await harness.start(
        _oneRun(
          lines: [
            textLine(
              'line-0',
              '1/2 Zitrone',
              settlement: assigned({'lemon': 500}),
            ),
            textLine(
              'line-1',
              '1 Zitrone',
              settlement: assigned({'whole': 1000}),
            ),
          ],
        ),
      );

      await finish();

      final components = (await harness.storedMeal(_mealId('pot-a')))!
          .components;
      final half = components.singleWhere((c) => c.inventoryItemId == 'lemon');
      final full = components.singleWhere((c) => c.inventoryItemId == 'whole');
      expect(half.usedAmount, 500);
      expect(half.totalKcal, closeTo(full.totalKcal / 2, 0.001));
      expect((await harness.storedItem('lemon'))!.currentAmount, 2500);
    });

    test('a take of 0 writes nothing for that item', () async {
      await harness.start(
        _oneRun(
          lines: [
            textLine(
              'line-0',
              '300 g Reis',
              settlement: assigned({'rice': 300}),
            ),
            textLine('line-1', 'Salz', settlement: assigned({'salt': 0})),
          ],
        ),
      );

      await finish();

      final meal = (await harness.storedMeal(_mealId('pot-a')))!;
      expect(meal.components.map((c) => c.inventoryItemId), ['rice']);
      expect((await harness.storedItem('salt'))!.currentAmount, 100);
      expect(await harness.eventCount(), 1);
    });

    test('a take of 0 next to a take writes nothing for its item', () async {
      await harness.start(
        _oneRun(
          lines: [
            textLine(
              'line-0',
              '300 g Reis',
              settlement: assigned({'salt': 0, 'rice': 300}),
            ),
          ],
        ),
      );

      await finish();

      final meal = (await harness.storedMeal(_mealId('pot-a')))!;
      expect(meal.components.map((c) => c.inventoryItemId), ['rice']);
      expect((await harness.storedItem('salt'))!.currentAmount, 100);
      expect(await harness.eventCount(), 1);
    });

    test('an ignored line adds no component and no stock change', () async {
      await harness.start(
        _oneRun(
          lines: [
            textLine(
              'line-0',
              '300 g Reis',
              settlement: assigned({'rice': 300}),
            ),
            textLine('line-1', 'Pfeffer', settlement: const LineIgnored()),
          ],
        ),
      );

      await finish();

      final meal = (await harness.storedMeal(_mealId('pot-a')))!;
      expect(meal.components, hasLength(1));
      expect(await harness.eventCount(), 1);
    });
  });

  group('two pots', () {
    CookRun twoPots() => buildCookRun(
      step: CookRunStep.portion,
      pots: _pots(const [cookPotA, cookPotB]),
      meals: const [_oneGross, _twoGross],
      lines: [
        textLine(
          'line-0',
          '300 g Reis',
          settlement: assigned({'rice': 300}),
          potId: 'pot-a',
        ),
        textLine(
          'line-1',
          '200 g Reis',
          settlement: assigned({'rice': 200}),
          potId: 'pot-b',
        ),
        textLine(
          'line-2',
          '100 g Karotten',
          settlement: assigned({'carrots': 100}),
          potId: 'pot-b',
        ),
      ],
    );

    test('one meal per pot with the fixed ids', () async {
      await harness.start(twoPots());

      final summary = await finish();

      expect(summary.meals, hasLength(2));
      expect(summary.meals.map((m) => m.totalPortions).sum, 6);
      expect(await harness.mealCount(), 2);
      expect(
        (await harness.storedMeal(_mealId('pot-a')))!.components,
        hasLength(1),
      );
      expect(
        (await harness.storedMeal(_mealId('pot-b')))!.components,
        hasLength(2),
      );
    });

    test('an item in both pots is one change against the original', () async {
      await harness.start(twoPots());

      await finish();

      expect((await harness.storedItem('rice'))!.currentAmount, 300);
      expect(await harness.eventCount(), 2);
    });

    test('each pot snapshots the original item, not the chained one', () async {
      await harness.start(twoPots());

      await finish();

      for (final id in [_mealId('pot-a'), _mealId('pot-b')]) {
        final rice = (await harness.storedMeal(id))!.components
            .firstWhere((component) => component.inventoryItemId == 'rice');
        expect(rice.sourceItemSnapshot.currentAmount, 800, reason: id);
      }
      final second = (await harness.storedMeal(_mealId('pot-b')))!;
      expect(
        second.components
            .firstWhere((c) => c.inventoryItemId == 'rice')
            .usedAmount,
        200,
      );
    });

    test(
      'a pot whose takes are all 0 is blocked, nothing is written',
      () async {
        await harness.start(
          buildCookRun(
            step: CookRunStep.portion,
            pots: _pots(const [cookPotA, cookPotB]),
            meals: const [_oneGross, _twoGross],
            lines: [
              textLine(
                'line-0',
                '300 g Reis',
                settlement: assigned({'rice': 300}),
                potId: 'pot-a',
              ),
              textLine(
                'line-1',
                'Salz',
                settlement: assigned({'salt': 0}),
                potId: 'pot-b',
              ),
            ],
          ),
        );

        await expectLater(service.finish('recipe-t1'), throwsStateError);
        await harness.settle();

        expect(await harness.mealCount(), 0);
        expect((await harness.storedItem('rice'))!.currentAmount, 800);
        expect(await harness.storedRun('recipe-t1'), isNotNull);
      },
    );
  });

  group('without pots and in cans', () {
    test('counted pieces become one meal of pieces', () async {
      await harness.start(
        buildCookRun(
          step: CookRunStep.portion,
          pots: const CookCounted(),
          meals: const [
            CookMealDraft(
              potId: countedMealPotId,
              name: 'Kekse',
              count: 12,
              inPieces: true,
              grossWeight: null,
            ),
          ],
          lines: [
            textLine(
              'line-0',
              '300 g Reis',
              settlement: assigned({'rice': 300}),
            ),
          ],
        ),
      );

      final summary = await finish();

      expect(summary.meals.map((m) => m.totalPortions).sum, 12);
      final meal = (await harness.storedMeal(_mealId('counted')))!;
      expect(meal.name, 'Kekse');
      expect(meal.totalPortions, 12);
      expect(meal.servedInPieces, isTrue);
      expect(meal.finalNetWeight, isNull);
      expect(meal.potTareWeight, isNull);
    });

    test('cans count as the portions of the pot', () async {
      await harness.start(
        buildCookRun(
          step: CookRunStep.portion,
          pots: _pots(const [cookPotA], inCans: true),
          meals: const [
            CookMealDraft(
              potId: 'pot-a',
              name: 'Eintopf',
              count: 5,
              inPieces: false,
              grossWeight: 2400,
            ),
          ],
          lines: [
            textLine(
              'line-0',
              '300 g Reis',
              settlement: assigned({'rice': 300}),
            ),
          ],
        ),
      );

      final summary = await finish();

      expect(summary.meals.map((m) => m.totalPortions).sum, 5);
      final meal = (await harness.storedMeal(_mealId('pot-a')))!;
      expect(meal.totalPortions, 5);
      // The food left the pot: its weight stays, the pot's tare does not.
      expect(meal.potTareWeight, isNull);
      expect(meal.finalNetWeight, 1500);
    });

    test('a pot eaten in pieces keeps neither tare nor weight', () async {
      await harness.start(
        _oneRun(
          meals: const [
            CookMealDraft(
              potId: 'pot-a',
              name: 'Kekse',
              count: 12,
              inPieces: true,
              grossWeight: 2400,
            ),
          ],
        ),
      );

      await finish();

      final meal = (await harness.storedMeal(_mealId('pot-a')))!;
      expect(meal.servedInPieces, isTrue);
      expect(meal.potTareWeight, isNull);
      expect(meal.finalNetWeight, isNull);
    });
  });

  group('added items', () {
    test('deletes the unused unchanged ones, keeps used and touched', () async {
      await harness.stock([
        stockItem('extra', 400),
        stockItem('used', 400),
        stockItem('touched', 300, initial: 500),
      ]);
      await harness.start(
        _oneRun(
          lines: [
            textLine(
              'line-0',
              '100 g Mehl',
              settlement: assigned({'used': 100}),
              addedItemIds: const ['used', 'extra', 'touched'],
            ),
          ],
        ),
      );

      await finish();

      expect(await harness.storedItem('extra'), isNull);
      expect((await harness.storedItem('used'))!.currentAmount, 300);
      expect(await harness.storedItem('touched'), isNotNull);
    });

    test('keeps a Vorrat food and an added food the line holds with a take '
        'of 0', () async {
      await harness.stock([
        stockItem('home', 400),
        stockItem('used', 400),
        stockItem('extra', 400),
      ]);
      await harness.start(
        _oneRun(
          lines: [
            textLine(
              'line-0',
              '100 g Mehl',
              settlement: assigned({'used': 100, 'home': 0, 'extra': 0}),
              // `home` was in the Vorrat before the run: not added for it.
              addedItemIds: const ['used', 'extra'],
            ),
          ],
        ),
      );

      await finish();

      expect(await harness.storedItem('home'), isNotNull);
      expect((await harness.storedItem('home'))!.currentAmount, 400);
      expect((await harness.storedItem('extra'))!.currentAmount, 400);
    });

    test('deletes the unchanged items of a removed line', () async {
      await harness.stock([stockItem('dropped', 400)]);
      await harness.start(
        _oneRun(
          lines: [
            ..._oneRun().lines,
            textLine('line-9', 'Mehl', addedItemIds: const ['dropped']),
          ],
        ).removeLine('line-9'),
      );

      await finish();

      expect(await harness.storedItem('dropped'), isNull);
    });

    test('keeps an added item that another run takes from', () async {
      await harness.stock([stockItem('shared', 400)]);
      await harness.start(
        _oneRun(
          lines: [
            ..._oneRun().lines,
            textLine(
              'line-9',
              'Mehl',
              settlement: const LineIgnored(),
              addedItemIds: const ['shared'],
            ),
          ],
        ),
      );
      await harness.start(
        buildCookRun(
          id: 'recipe-t2',
          lines: [
            textLine('line-0', 'Mehl', settlement: assigned({'shared': 100})),
          ],
        ),
      );

      await finish();

      expect(await harness.storedItem('shared'), isNotNull);
    });

    test(
      'keeps an added item that a line holds, also with a take of 0',
      () async {
        await harness.stock([stockItem('held', 400), stockItem('free', 400)]);
        await harness.start(
          _oneRun(
            lines: [
              textLine(
                'line-0',
                'Salz',
                settlement: assigned({'held': 0}),
                addedItemIds: const ['held', 'free'],
              ),
              textLine(
                'line-1',
                '300 g Reis',
                settlement: assigned({'rice': 300}),
              ),
            ],
          ),
        );

        await finish();

        expect((await harness.storedItem('held'))!.currentAmount, 400);
        expect(await harness.storedItem('free'), isNull);
      },
    );

    test('the meal inputs do not mark an added item for deletion', () async {
      await harness.stock([stockItem('used', 400)]);
      await harness.start(
        _oneRun(
          lines: [
            textLine(
              'line-0',
              '100 g Mehl',
              settlement: assigned({'used': 100}),
              addedItemIds: const ['used'],
            ),
            textLine(
              'line-1',
              '300 g Reis',
              settlement: assigned({'rice': 300}),
            ),
          ],
        ),
      );

      await finish();

      final components = (await harness.storedMeal(_mealId('pot-a')))!
          .components;
      expect(
        components.firstWhere((c) => c.inventoryItemId == 'used').addedForMeal,
        isNot(true),
      );
    });
  });

  group('free cooking', () {
    CookRun free({required bool toCookbook, String name = 'Frei'}) =>
        freeRun(name: name, [
          textLine(
            'line-0',
            '2 Eier',
            settlement: assigned({'rice': 300}),
            conversion: const CookLineConversion(
              amountPerPiece: 60,
              unit: TemplateIngredientUnit.gram,
            ),
          ),
          textLine('line-1', 'Pfeffer', settlement: const LineIgnored()),
        ], pots: _pots(const [cookPotA])).copyWith(
          step: CookRunStep.portion,
          meals: const [_oneGross],
          toCookbook: toCookbook,
        );

    test('with "Ins Kochbuch" saves the recipe before the batch', () async {
      final templates = _OrderTemplates(harness);
      service = _service(harness, templates: templates);
      await harness.start(free(toCookbook: true));

      final summary = await finish();

      expect(summary.inCookbook, isTrue);
      expect(templates.runStillThereAtSave, isTrue);
      expect(templates.stockAtSave, 800);
      expect(await harness.storedRun('recipe-t1'), isNull);
      final recipe = templates.templates.single;
      expect(recipe.id, 'cookbook-${buildCookRun().cookingId}');
      expect(recipe.name, 'Eintopf');
      expect(recipe.recipeIngredients, ['2 Eier', 'Pfeffer']);
      expect(recipe.ignoredRecipeIngredients, ['Pfeffer']);
      expect(recipe.recipeIngredientAmountConversions.keys, ['2 Eier']);
      expect(recipe.totalPortions, 4);
    });

    test('saves the amounts the cook took for a line without one', () async {
      final templates = FakePreparedMealTemplateRepository();
      service = _service(harness, templates: templates);
      await harness.start(
        freeRun([
          textLine('line-0', 'Reis', settlement: assigned({'rice': 200})),
        ], name: 'Reisgericht').copyWith(
          step: CookRunStep.portion,
          pots: _pots(const [cookPotA]),
          meals: const [_oneGross],
          toCookbook: true,
        ),
      );

      await finish();

      expect(templates.templates.single.recipeIngredients, ['200 g Reis']);
    });

    test('saves the cook amount of a line at the run portions', () async {
      final templates = FakePreparedMealTemplateRepository();
      service = _service(harness, templates: templates);
      await harness.start(
        freeRun([
          textLine(
            'line-0',
            'Reis',
            settlement: assigned({'rice': 300}),
            amount: 300,
            amountPortions: 1,
          ),
        ], name: 'Reisgericht').copyWith(
          step: CookRunStep.portion,
          pots: _pots(const [cookPotA]),
          meals: const [_oneGross],
          toCookbook: true,
        ),
      );

      await finish();

      expect(templates.templates.single.recipeIngredients, ['300 g Reis']);
    });

    test('a failing batch keeps the recipe when the run is gone', () async {
      final templates = _EndingTemplates(harness);
      service = _service(harness, templates: templates);
      await harness.start(free(toCookbook: true));
      harness.inventory.items = [
        for (final item in harness.inventory.items)
          if (item.id == 'rice') stockItem('rice', 900) else item,
      ];

      try {
        await service.finish('recipe-t1');
      } on Object {
        // Whether the batch refuses or not is not what this checks.
      }
      await harness.settle();

      expect(templates.templates, hasLength(1));
    });

    test('a batch that fails deletes the saved recipe again', () async {
      final templates = FakePreparedMealTemplateRepository();
      service = _service(harness, templates: templates);
      await harness.start(free(toCookbook: true));
      // The read shows more rice than the store holds: the batch refuses.
      harness.inventory.items = [
        for (final item in harness.inventory.items)
          if (item.id == 'rice') stockItem('rice', 900) else item,
      ];

      await expectLater(service.finish('recipe-t1'), throwsStateError);
      await harness.settle();

      expect(templates.writeCount, 2);
      expect(templates.templates, isEmpty);
      expect(await harness.storedRun('recipe-t1'), isNotNull);
      expect(await harness.mealCount(), 0);
    });

    test(
      'a batch that fails without "Ins Kochbuch" deletes no recipe',
      () async {
        final templates = FakePreparedMealTemplateRepository();
        service = _service(harness, templates: templates);
        await harness.start(free(toCookbook: false));
        harness.inventory.items = [
          for (final item in harness.inventory.items)
            if (item.id == 'rice') stockItem('rice', 900) else item,
        ];

        await expectLater(service.finish('recipe-t1'), throwsStateError);

        expect(templates.writeCount, 0);
      },
    );

    test('a meal with a blank name and a run without name throws', () async {
      await harness.start(
        free(toCookbook: false, name: '').copyWith(
          meals: const [
            CookMealDraft(
              potId: 'pot-a',
              name: ' ',
              count: 4,
              inPieces: false,
              grossWeight: 2400,
            ),
          ],
        ),
      );

      await expectLater(service.finish('recipe-t1'), throwsStateError);
      await harness.settle();

      expect(await harness.storedRun('recipe-t1'), isNotNull);
      expect(await harness.mealCount(), 0);
      expect((await harness.storedItem('rice'))!.currentAmount, 800);
    });

    test('without "Ins Kochbuch" saves no recipe', () async {
      final templates = FakePreparedMealTemplateRepository();
      service = _service(harness, templates: templates);
      await harness.start(free(toCookbook: false));

      final summary = await finish();

      expect(summary.inCookbook, isFalse);
      expect(templates.writeCount, 0);
    });

    test(
      'a recipe that is not saved stops the finish, nothing changes',
      () async {
        final templates = FakePreparedMealTemplateRepository()
          ..failWrites = true;
        service = _service(harness, templates: templates);
        await harness.start(free(toCookbook: true));

        await expectLater(service.finish('recipe-t1'), throwsStateError);
        await harness.settle();

        expect(await harness.storedRun('recipe-t1'), isNotNull);
        expect(await harness.mealCount(), 0);
        expect((await harness.storedItem('rice'))!.currentAmount, 800);
      },
    );
  });

  group('cooking ids', () {
    test('cooking the same recipe twice in one pot keeps both meals', () async {
      await harness.start(_oneRun());
      await finish();
      harness.inventory.items = [
        for (final id in ['rice', 'carrots', 'salt'])
          (await harness.storedItem(id))!,
      ];
      final later = cookRunStart.add(const Duration(days: 1));
      await harness.start(
        buildCookRun(
          step: CookRunStep.portion,
          pots: _pots(const [cookPotA]),
          meals: const [_oneGross],
          startedAt: later,
          lines: [
            textLine(
              'line-0',
              '100 g Reis',
              settlement: assigned({'rice': 100}),
            ),
          ],
        ),
      );

      await finish();

      expect(await harness.mealCount(), 2);
      expect(await harness.eventCount(), 3);
      expect((await harness.storedItem('rice'))!.currentAmount, 400);
    });
  });

  group('waits and refuses', () {
    test('waits for the writes of the run that are still queued', () async {
      await harness.start(_oneRun(meals: const []));
      // Not awaited: without the wait the run has no meal for its pot.
      final change = harness.runs.mutate(
        'recipe-t1',
        (run) => run.withMeal(_oneGross),
      );

      final summary = await service.finish('recipe-t1');
      await change;

      expect(summary.meals, hasLength(1));
    });

    test('a run that is gone throws', () async {
      await expectLater(
        service.finish('recipe-t1'),
        throwsA(isA<CookRunGoneException>()),
      );
    });

    test('a pot without a typed-in meal throws, nothing is written', () async {
      await harness.start(_oneRun(meals: const []));

      await expectLater(service.finish('recipe-t1'), throwsStateError);
      await harness.settle();

      expect(await harness.mealCount(), 0);
      expect(await harness.storedRun('recipe-t1'), isNotNull);
    });

    test('a run without pots throws, nothing is written', () async {
      await harness.start(
        buildCookRun(
          step: CookRunStep.portion,
          meals: const [_oneGross],
          lines: [
            textLine(
              'line-0',
              '300 g Reis',
              settlement: assigned({'rice': 300}),
            ),
          ],
        ),
      );

      await expectLater(service.finish('recipe-t1'), throwsStateError);
      await harness.settle();

      expect(await harness.mealCount(), 0);
      expect(await harness.storedRun('recipe-t1'), isNotNull);
    });

    test('a counted run with only ignored lines is blocked', () async {
      await harness.start(
        buildCookRun(
          step: CookRunStep.portion,
          pots: const CookCounted(),
          meals: const [
            CookMealDraft(
              potId: countedMealPotId,
              name: 'Kekse',
              count: 12,
              inPieces: true,
              grossWeight: null,
            ),
          ],
          lines: [textLine('line-0', 'Salz', settlement: const LineIgnored())],
        ),
      );

      await expectLater(service.finish('recipe-t1'), throwsStateError);
      await harness.settle();

      expect(await harness.mealCount(), 0);
      expect(await harness.storedRun('recipe-t1'), isNotNull);
    });

    test('a line that still needs shopping blocks the finish', () async {
      await harness.start(
        _oneRun(
          lines: [
            textLine(
              'line-0',
              '300 g Reis',
              settlement: assigned({'rice': 300}),
            ),
            textLine('line-1', 'Zwiebel', settlement: const LineShopping()),
          ],
        ),
      );

      await expectLater(service.finish('recipe-t1'), throwsStateError);
      await harness.settle();

      expect(await harness.mealCount(), 0);
      expect((await harness.storedItem('rice'))!.currentAmount, 800);
    });

    test('stock that fell short since blocks the finish', () async {
      await harness.start(
        _oneRun(
          lines: [
            textLine(
              'line-0',
              '900 g Reis',
              settlement: assigned({'rice': 900}),
            ),
          ],
        ),
      );

      await expectLater(service.finish('recipe-t1'), throwsStateError);
      await harness.settle();

      expect(await harness.mealCount(), 0);
      expect(await harness.storedRun('recipe-t1'), isNotNull);
    });
  });
}

CookRunFinishService _service(
  CookHarness harness, {
  FakePreparedMealTemplateRepository? templates,
}) => CookRunFinishService(
  runs: harness.runs,
  inventory: harness.inventory,
  meals: harness.meals,
  templates: templates ?? harness.templates,
  clock: () => _now,
);
