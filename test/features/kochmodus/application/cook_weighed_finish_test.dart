import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_line_amount.dart';
import 'package:yamt/features/kochmodus/application/cook_run_finish_service.dart';
import 'package:yamt/features/kochmodus/application/cook_takes.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'cook_services_harness.dart';

const _meal = CookMealDraft(
  potId: 'pot-a',
  name: 'Gemüsepfanne',
  count: 2,
  inPieces: false,
  grossWeight: 1500,
);

// Lines on items kept in grams and ml, like the cooking that took only 5 of
// 10 lines: "1 Möhre" and "1 Zwiebel" without a piece weight, "1 EL Öl" on
// an ml item.
const _texts = {
  'carrot-line': '1 Möhre',
  'onion-line': '1 Zwiebel',
  'oil-line': '1 EL Öl',
};
const _itemOf = {
  'carrot-line': 'carrot',
  'onion-line': 'onion',
  'oil-line': 'oil',
};
const _weights = {'carrot-line': 60, 'onion-line': 80, 'oil-line': 15};

CookRun _run(Map<String, int?> weighed, List<InventoryItem> items) {
  final run = buildCookRun(
    step: CookRunStep.portion,
    pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
    meals: const [_meal],
    lines: [
      for (final MapEntry(:key, :value) in _texts.entries)
        textLine(
          key,
          value,
          settlement: assigned({_itemOf[key]!: 0}),
          weighed: weighed[key],
        ),
    ],
  );
  // The takes the cooking page gives each line from what it weighed.
  return CookRun(
    id: run.id,
    kind: run.kind,
    step: run.step,
    recipeId: run.recipeId,
    name: run.name,
    imageAssetId: run.imageAssetId,
    imageUrl: run.imageUrl,
    basePortions: run.basePortions,
    portions: run.portions,
    steps: run.steps,
    startedBy: run.startedBy,
    startedByName: run.startedByName,
    startedAt: run.startedAt,
    lines: [
      for (final line in run.lines)
        line.copyWith(
          settlement: LineAssigned(
            cookTakesFor(
              run: run,
              line: line,
              need: cookLineNeed(
                run,
                line,
                const TemplateIngredientParser().parseRequirement(
                  ingredient: line.text,
                  selectedPortions: run.portions,
                  basePortions: run.basePortions,
                ),
              ),
              items: [items.firstWhere((item) => item.id == _itemOf[line.id])],
              otherReservations: const {},
            ),
          ),
        ),
    ],
    pots: run.pots,
    withGuide: run.withGuide,
    guideStep: run.guideStep,
    timers: run.timers,
    meals: run.meals,
    toCookbook: run.toCookbook,
    droppedItemIds: run.droppedItemIds,
  );
}

void main() {
  late CookHarness harness;
  late CookRunFinishService service;
  late List<InventoryItem> items;

  setUp(() async {
    harness = await CookHarness.open();
    service = CookRunFinishService(
      runs: harness.runs,
      inventory: harness.inventory,
      meals: harness.meals,
      templates: harness.templates,
      clock: () => DateTime.utc(2026, 11, 8, 12),
    );
    items = [
      stockItem('carrot', 1000),
      stockItem('onion', 1000),
      stockItem('oil', 500, unit: InventoryAmountUnit.milliliter),
    ];
    await harness.stock(items);
  });

  group('weighed lines on items kept in grams and ml', () {
    test(
      'each line becomes a component with its weight, stock and kcal',
      () async {
        await harness.start(_run(_weights, items));

        await service.finish('recipe-t1');
        await harness.settle();

        final meal = (await harness.storedMeal(
          '${buildCookRun().cookingId}-pot-a',
        ))!;
        expect(
          {for (final c in meal.components) c.inventoryItemId: c.usedAmount},
          {'carrot': 60, 'onion': 80, 'oil': 15},
        );
        expect(
          meal.components
              .firstWhere((c) => c.inventoryItemId == 'oil')
              .usedUnit,
          InventoryAmountUnit.milliliter,
        );
        expect((await harness.storedItem('carrot'))!.currentAmount, 940);
        expect((await harness.storedItem('onion'))!.currentAmount, 920);
        expect((await harness.storedItem('oil'))!.currentAmount, 485);
        // The fixture counts 100 kcal per 100 g, so a gram is a kcal.
        expect(meal.totalKcal, 60 + 80 + 15);
        expect(await harness.storedRun('recipe-t1'), isNull);
      },
    );

    test(
      'without the weighing the finish is refused, nothing written',
      () async {
        await harness.start(_run(const {}, items));

        await expectLater(service.finish('recipe-t1'), throwsStateError);
        await harness.settle();

        expect(await harness.mealCount(), 0);
        expect((await harness.storedItem('carrot'))!.currentAmount, 1000);
        expect(await harness.storedRun('recipe-t1'), isNotNull);
      },
    );

    test('one line still unweighed refuses the finish', () async {
      await harness.start(_run({..._weights, 'onion-line': null}, items));

      await expectLater(service.finish('recipe-t1'), throwsStateError);
      await harness.settle();

      expect(await harness.mealCount(), 0);
    });
  });
}
