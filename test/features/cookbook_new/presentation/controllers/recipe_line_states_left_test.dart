import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'recipe_line_states.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/recipes/application/cook_run_providers.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';

import '../../../../helpers/fake_cook_run_repository.dart';
import '../../../../helpers/fake_inventory_item_repository.dart';
import '../../../kochmodus/kochmodus_fixtures.dart';
import '../../../recipes/cook_run_fixtures.dart';

InventoryItem _flour(String id, int amount) => InventoryItem.create(
  id: id,
  name: 'Mehl',
  entryDate: DateTime.utc(2026, 10, 9),
  storeName: 'Store',
  quantity: 1,
  initialAmount: 2000,
  currentAmount: amount,
  amountUnit: InventoryAmountUnit.gram,
);

Future<Map<int, RecipeLineState>?> _states({
  required CookRun run,
  List<InventoryItem> items = const [],
  Map<String, int>? reserved,
}) async {
  final container = ProviderContainer(
    overrides: [
      cookRunsProvider.overrideWith((ref) => Stream.value([run])),
      inventoryQuickEatItemsProvider.overrideWith((ref) => Stream.value(items)),
      if (reserved != null)
        cookRunReservationsProvider.overrideWith(
          (ref) => Stream.value(reserved),
        ),
    ],
  );
  addTearDown(container.dispose);
  container
    ..listen(recipeLineStatesProvider('t1'), (_, _) {})
    ..listen(inventoryQuickEatItemsProvider, (_, _) {})
    ..listen(cookRunReservationsProvider, (_, _) {});
  await container.read(recipeCookRunProvider('t1').future);
  await container.read(inventoryQuickEatItemsProvider.future);
  if (reserved != null) {
    await container.read(cookRunReservationsProvider.future);
  }
  final states = container.read(recipeLineStatesProvider('t1'));
  return states;
}

/// The states of the cooking of recipe `t1` with every run and the Vorrat
/// in the fakes of their repositories, so the providers between them run for
/// real.
Future<Map<int, RecipeLineState>?> _statesFromRepositories({
  required List<CookRun> runs,
  required List<InventoryItem> items,
}) async {
  final container = ProviderContainer(
    overrides: [
      cookRunRepositoryProvider.overrideWithValue(
        FakeCookRunRepository(runs: runs),
      ),
      inventoryItemRepositoryProvider.overrideWithValue(
        FakeInventoryItemRepository(items),
      ),
    ],
  );
  addTearDown(container.dispose);
  container
    ..listen(recipeLineStatesProvider('t1'), (_, _) {})
    ..listen(cookRunReservationsProvider, (_, _) {});
  await container.read(recipeCookRunProvider('t1').future);
  await container.read(inventoryQuickEatItemsProvider.future);
  await container.read(cookRunReservationsProvider.future);
  final states = container.read(recipeLineStatesProvider('t1'));
  return states;
}

CookRun _otherRecipeRun(String recipeId, int grams) => buildCookRun(
  id: 'recipe-$recipeId',
  recipeId: recipeId,
  lines: [
    textLine('x', '$grams g Mehl', settlement: assigned({'a': grams})),
  ],
);

CookRun _flourRun() => buildCookRun(
  lines: [
    textLine('line-0', '300 g Mehl', settlement: assigned({'a': 100})),
  ],
);

void main() {
  group('the stock of an assigned line is what is left for this cooking', () {
    test('without reservations read it is the stock', () async {
      final states = await _states(run: _flourRun(), items: [_flour('a', 700)]);

      expect((states![0]! as RecipeLineAssigned).stock, (
        amount: 700,
        unit: InventoryAmountUnit.gram,
      ));
    });

    test('other cook runs take their part away', () async {
      // All runs hold 600 of the item, 100 of it this line's own take.
      final states = await _states(
        run: _flourRun(),
        items: [_flour('a', 700)],
        reserved: const {'a': 600},
      );

      expect((states![0]! as RecipeLineAssigned).stock, (
        amount: 200,
        unit: InventoryAmountUnit.gram,
      ));
    });

    test('the line own take does not count against itself', () async {
      final states = await _states(
        run: _flourRun(),
        items: [_flour('a', 700)],
        reserved: const {'a': 100},
      );

      expect((states![0]! as RecipeLineAssigned).stock, (
        amount: 700,
        unit: InventoryAmountUnit.gram,
      ));
    });

    test('never goes below 0', () async {
      final states = await _states(
        run: _flourRun(),
        items: [_flour('a', 700)],
        reserved: const {'a': 5000},
      );

      expect((states![0]! as RecipeLineAssigned).stock, (
        amount: 0,
        unit: InventoryAmountUnit.gram,
      ));
    });
  });

  group('with the cook runs and the Vorrat in their repositories', () {
    test('two runs of other recipes that hold the same item take their '
        'parts away', () async {
      final states = await _statesFromRepositories(
        runs: [
          _flourRun(),
          _otherRecipeRun('t2', 300),
          _otherRecipeRun('t3', 200),
        ],
        items: [_flour('a', 700)],
      );

      // 700 in the Vorrat, 300 and 200 held by the other recipes.
      expect((states![0]! as RecipeLineAssigned).stock, (
        amount: 200,
        unit: InventoryAmountUnit.gram,
      ));
    });

    test(
      'a run of the same recipe is the line itself, not another run',
      () async {
        final states = await _statesFromRepositories(
          runs: [_flourRun(), _otherRecipeRun('t2', 300)],
          items: [_flour('a', 700)],
        );

        expect((states![0]! as RecipeLineAssigned).stock, (
          amount: 400,
          unit: InventoryAmountUnit.gram,
        ));
      },
    );

    test('other runs that hold nothing of the item leave the stock', () async {
      final other = buildCookRun(
        id: 'recipe-t2',
        recipeId: 't2',
        lines: [
          textLine('x', '300 g Reis', settlement: assigned({'b': 300})),
        ],
      );

      final states = await _statesFromRepositories(
        runs: [_flourRun(), other],
        items: [_flour('a', 700)],
      );

      expect((states![0]! as RecipeLineAssigned).stock, (
        amount: 700,
        unit: InventoryAmountUnit.gram,
      ));
    });
  });

  group('a line that does not count', () {
    test('a pinch of salt left out is marked not counted', () async {
      final states = await _states(
        run: buildCookRun(
          lines: [
            textLine('line-0', '1 Prise Salz', settlement: const LineIgnored()),
            textLine('line-1', 'Basilikum', settlement: const LineIgnored()),
          ],
        ),
      );

      expect((states![0]! as RecipeLineIgnored).notCounted, isTrue);
      expect((states[1]! as RecipeLineIgnored).notCounted, isFalse);
    });

    test('is skipped by the counts, a line the cook left out is not', () {
      final counts = recipeLineCounts({
        0: const RecipeLineIgnored('1 Prise Salz', notCounted: true),
        1: const RecipeLineIgnored('Basilikum'),
        2: const RecipeLineOpen('Eier'),
      });

      expect(counts, (ready: 0, shopping: 0, ignored: 1, open: 1));
    });

    test('counts nowhere when every line is not counted', () {
      final counts = recipeLineCounts({
        0: const RecipeLineIgnored('Salz', notCounted: true),
        1: const RecipeLineIgnored('Wasser', notCounted: true),
      });

      expect(counts, (ready: 0, shopping: 0, ignored: 0, open: 0));
    });
  });
}
