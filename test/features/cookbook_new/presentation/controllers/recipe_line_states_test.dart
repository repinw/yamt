import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'recipe_line_states.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/recipes/application/cook_run_providers.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';

import '../../../kochmodus/kochmodus_fixtures.dart';
import '../../../recipes/cook_run_fixtures.dart';

InventoryItem _item(String id, {int amount = 2000}) => InventoryItem.create(
  id: id,
  name: 'Food $id',
  entryDate: DateTime.utc(2026, 10, 9),
  storeName: 'Store',
  quantity: 1,
  initialAmount: 2000,
  currentAmount: amount,
  amountUnit: InventoryAmountUnit.gram,
);

Future<Map<int, RecipeLineState>?> _states({
  required List<CookRun> runs,
  List<InventoryItem> items = const [],
}) async {
  final container = ProviderContainer(
    overrides: [
      cookRunsProvider.overrideWith((ref) => Stream.value(runs)),
      inventoryQuickEatItemsProvider.overrideWith((ref) => Stream.value(items)),
    ],
  );
  addTearDown(container.dispose);
  // Keep the provider alive while its inputs load.
  container
    ..listen(recipeLineStatesProvider('t1'), (_, _) {})
    ..listen(inventoryQuickEatItemsProvider, (_, _) {});
  await container.read(recipeCookRunProvider('t1').future);
  await container.read(inventoryQuickEatItemsProvider.future);
  final states = container.read(recipeLineStatesProvider('t1'));
  return states;
}

final _assigned = LineAssigned(const [ItemTake(itemId: 'a', amount: 1)]);

void main() {
  test('is null while the recipe has no cook run', () async {
    expect(await _states(runs: const []), isNull);
    expect(
      await _states(
        runs: [buildCookRun(id: 'other', recipeId: 'other')],
      ),
      isNull,
    );
  });

  test('an item that takes nothing next to a take counts no stock', () async {
    final states = await _states(
      runs: [
        buildCookRun(
          lines: [
            cookLine(
              'line-0',
              settlement: LineAssigned(const [
                ItemTake(itemId: 'spare', amount: 0),
                ItemTake(itemId: 'used', amount: 1),
              ]),
            ),
          ],
        ),
      ],
      items: [_item('spare', amount: 500), _item('used', amount: 300)],
    );

    expect((states![0]! as RecipeLineAssigned).stock, (
      amount: 300,
      unit: InventoryAmountUnit.gram,
    ));
  });

  test('a run without an assigned line still has states', () async {
    final states = await _states(
      runs: [
        buildCookRun(
          lines: [
            cookLine('line-0'),
            cookLine('line-1', settlement: const LineIgnored()),
            cookLine(
              'added-1',
              origin: CookLineOrigin.added,
              settlement: LineAssigned(const [
                ItemTake(itemId: 'a', amount: 1),
              ]),
            ),
          ],
        ),
      ],
    );

    expect(states!.keys, [0, 1]);
    expect(states[0], isA<RecipeLineOpen>());
    expect(states[1], isA<RecipeLineIgnored>());
  });

  test('maps the recipe lines by their index in the recipe', () async {
    final states = await _states(
      runs: [
        buildCookRun(
          lines: [
            cookLine('line-0', settlement: const LineIgnored()),
            cookLine('line-2'),
            cookLine('line-1', settlement: const LineIgnored()),
            cookLine('line-3', settlement: _assigned),
          ],
        ),
      ],
    );

    expect(states!.keys, unorderedEquals([0, 1, 2, 3]));
    expect(states[0], isA<RecipeLineIgnored>());
    expect(states[1], isA<RecipeLineIgnored>());
    expect(states[2], isA<RecipeLineOpen>());
    expect(states[3], isA<RecipeLineAssigned>());
  });

  test('each state keeps the text the run took from the recipe', () async {
    final states = await _states(
      runs: [
        buildCookRun(
          lines: [
            cookLine('line-0', settlement: _assigned),
            cookLine('line-1', settlement: const LineIgnored()),
            cookLine('line-2'),
          ],
        ),
      ],
    );

    expect(states![0]!.text, 'text line-0');
    expect(states[1]!.text, 'text line-1');
    expect(states[2]!.text, 'text line-2');
  });

  test('leaves out lines the cook run added or the cook spoke', () async {
    final states = await _states(
      runs: [
        buildCookRun(
          lines: [
            cookLine('line-0', settlement: _assigned),
            cookLine('added-1', origin: CookLineOrigin.added),
            cookLine('line-3', origin: CookLineOrigin.cooking),
            cookLine('free-text'),
          ],
        ),
      ],
    );

    expect(states!.keys, [0]);
  });

  test('a line on the shopping list is its own state', () async {
    final states = await _states(
      runs: [
        buildCookRun(
          lines: [
            cookLine('line-0', settlement: const LineShopping()),
            cookLine('line-1', settlement: _assigned),
          ],
        ),
      ],
    );

    expect(states![0], isA<RecipeLineShopping>());
    expect(states[1], isA<RecipeLineAssigned>());
  });

  test('an assigned line shows what its Vorrat items hold', () async {
    final states = await _states(
      runs: [
        buildCookRun(
          lines: [
            cookLine(
              'line-0',
              settlement: LineAssigned(const [
                ItemTake(itemId: 'a', amount: 100),
                ItemTake(itemId: 'b', amount: 50),
              ]),
            ),
          ],
        ),
      ],
      items: [_item('a', amount: 700), _item('b', amount: 300)],
    );

    final state = states![0]! as RecipeLineAssigned;
    expect(state.stock, (amount: 1000, unit: InventoryAmountUnit.gram));
  });

  test('an assigned line without a known Vorrat item has no stock', () async {
    final states = await _states(
      runs: [
        buildCookRun(
          lines: [
            cookLine(
              'line-0',
              settlement: LineAssigned(const [
                ItemTake(itemId: 'gone', amount: 100),
              ]),
            ),
          ],
        ),
      ],
      items: [_item('a')],
    );

    final state = states![0]! as RecipeLineAssigned;
    expect(state.stock, isNull);
  });

  test('the cook own amount is scaled to the portions of the run', () async {
    final states = await _states(
      runs: [
        buildCookRun(
          portions: 8,
          lines: [
            cookLine('line-0', settlement: _assigned, amount: 100),
            cookLine('line-1', settlement: const LineShopping(), amount: 3),
            cookLine('line-2', settlement: _assigned),
            cookLine('line-3', settlement: _assigned, amount: 0),
          ],
        ),
      ],
    );

    expect(states![0]!.own, (amount: 200, unit: null));
    expect(states[1]!.own, (amount: 6, unit: null));
    expect(states[2]!.own, isNull);
    expect(states[3]!.own, (amount: 0, unit: null));
  });

  test('the own amount never scales below 1', () async {
    final states = await _states(
      runs: [
        buildCookRun(
          portions: 1,
          lines: [cookLine('line-0', settlement: _assigned, amount: 1)],
        ),
      ],
    );

    expect(states![0]!.own, (amount: 1, unit: null));
  });

  test('a line with part in the Vorrat and the rest on the shopping list '
      'carries the rest', () async {
    final states = await _states(
      runs: [
        buildCookRun(
          lines: [
            textLine('line-0', '500 g Mehl', settlement: _assigned),
            textLine(
              cookRestLineId('line-0'),
              '200 g Mehl',
              settlement: const LineShopping(),
              origin: CookLineOrigin.added,
            ),
          ],
        ),
      ],
      items: [_item('a', amount: 300)],
    );

    expect(states, hasLength(1));
    final state = states![0]! as RecipeLineAssigned;
    expect(state.stock, (amount: 300, unit: InventoryAmountUnit.gram));
    expect(state.rest, (amount: 200, unit: InventoryAmountUnit.gram));
  });

  test('a rest line that is not on the shopping list is no rest', () async {
    final states = await _states(
      runs: [
        buildCookRun(
          lines: [
            textLine('line-0', '500 g Mehl', settlement: _assigned),
            textLine(
              cookRestLineId('line-0'),
              '200 g Mehl',
              settlement: const LineIgnored(),
              origin: CookLineOrigin.added,
            ),
          ],
        ),
      ],
    );

    expect((states![0]! as RecipeLineAssigned).rest, isNull);
  });

  test('a line with its rest on the list counts once, as shopping', () {
    final counts = recipeLineCounts({
      0: const RecipeLineAssigned(
        'Mehl',
        (amount: 300, unit: InventoryAmountUnit.gram),
        rest: (amount: 200, unit: InventoryAmountUnit.gram),
      ),
      1: const RecipeLineAssigned('Salz', null),
    });

    expect(counts, (ready: 1, shopping: 1, ignored: 0, open: 0));
  });

  test('counts the lines by state', () {
    final counts = recipeLineCounts({
      0: const RecipeLineAssigned('Mehl', null),
      1: const RecipeLineIgnored('Salz'),
      2: const RecipeLineOpen('Eier'),
      3: const RecipeLineOpen('Milch'),
      4: const RecipeLineShopping('Butter'),
    });

    expect(counts, (ready: 1, shopping: 1, ignored: 1, open: 2));
  });
}
