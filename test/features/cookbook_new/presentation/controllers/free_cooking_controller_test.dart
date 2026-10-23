import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/domain/free_cooking_row.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'free_cooking_controller.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_cooking_service.dart';
import 'package:yamt/features/inventory/application/prepared_meal_from_vorlage.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

InventoryItem _item(
  String name, {
  String? brand,
  InventoryAmountUnit unit = InventoryAmountUnit.gram,
}) {
  return InventoryItem.create(
    id: name.toLowerCase(),
    name: name,
    brand: brand,
    entryDate: DateTime.utc(2026, 9, 29),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 600,
    currentAmount: 600,
    amountUnit: unit,
  );
}

class _FakeCookingService implements PreparedMealCookingService {
  new({this.succeeds = true});

  final bool succeeds;
  final calls =
      <
        ({
          String name,
          List<String> ingredients,
          Map<String, List<String>> assignments,
        })
      >[];

  @override
  Future<PreparedMealCreationResult> cook({
    required String name,
    required List<String> ingredients,
    required Map<String, List<String>> assignments,
  }) async {
    calls.add((name: name, ingredients: ingredients, assignments: assignments));
    return succeeds
        ? const PreparedMealCreationResult.success('meal')
        : const PreparedMealCreationResult.failure(
            PreparedMealCreationFailureReason.mealSaveFailed,
          );
  }

  @override
  Future<PreparedMealCreationResult> cookRecipe({
    required PreparedMeal recipe,
    required int portions,
    required Map<String, List<String>> assignments,
  }) => throw UnimplementedError();

  @override
  Future<PreparedMealCreationResult> cookVorlage({
    required PreparedMeal vorlage,
    required int portions,
    required List<VorlageFood> foods,
  }) => throw UnimplementedError();

  @override
  Future<PreparedMeal> finishCooking({
    required String mealId,
    required int totalPortions,
    required bool servedInPieces,
    required int? potTareWeight,
    required int? finalNetWeight,
  }) => throw UnimplementedError();

  @override
  Future<void> discard(String mealId) => throw UnimplementedError();
}

ProviderContainer _container(
  _FakeCookingService service, {
  List<InventoryItem>? items,
}) {
  final container = ProviderContainer(
    overrides: [
      inventoryQuickEatItemsProvider.overrideWith(
        (ref) => Stream.value(items ?? [_item('Hähnchen')]),
      ),
      preparedMealCookingServiceProvider.overrideWithValue(service),
    ],
  );
  addTearDown(container.dispose);
  container.listen(freeCookingControllerProvider, (_, _) {});
  return container;
}

Future<List<FreeCookingRow>> _rows(ProviderContainer container) async {
  final provider = freeCookingRowsProvider('de');
  final subscription = container.listen(provider, (_, _) {});
  addTearDown(subscription.close);
  while (!container.read(provider).hasValue) {
    await Future<void>.delayed(Duration.zero);
  }
  return container.read(provider).requireValue;
}

void main() {
  test('splits spoken text into rows and marks the ones in stock', () async {
    final container = _container(_FakeCookingService());

    container
        .read(freeCookingControllerProvider.notifier)
        .addText('500 g Hähnchen 200 g Reis');
    final rows = await _rows(container);

    expect(rows.map((row) => row.text), ['500 g Hähnchen', '200 g Reis']);
    expect(rows.first.stockItem?.id, 'hähnchen');
    expect(rows.first.requirement?.amount, 500);
    expect(rows.last.isInStock, isFalse);
  });

  test('a row without a usable amount does not count as in stock', () async {
    final container = _container(_FakeCookingService())
      ..read(freeCookingControllerProvider.notifier)
          .addText('Hähnchen, 2 EL Hähnchen');

    final rows = await _rows(container);

    expect(rows.map((row) => row.isInStock), [false, false]);
  });

  test('an undo word takes the rows added last out again', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(freeCookingControllerProvider.notifier)
      ..addText('500 g Hähnchen')
      ..addText('200 g Reis, Salz')
      ..addText('nein, 200 g Nudeln');

    expect(container.read(freeCookingControllerProvider).rows, [
      '500 g Hähnchen',
      '200 g Nudeln',
    ]);

    controller.addText('Nein!');
    expect(container.read(freeCookingControllerProvider).rows, [
      '500 g Hähnchen',
    ]);
    // Only the text before it is taken back; nothing was added since.
    controller.addText('nein');
    expect(container.read(freeCookingControllerProvider).rows, [
      '500 g Hähnchen',
    ]);

    // A swipe on an older row keeps the rows added last; empty text too.
    controller
      ..addText('Salz, 200 ml Sahne')
      ..removeRow(0)
      ..addText(',')
      ..addText('nein');
    expect(container.read(freeCookingControllerProvider).rows, isEmpty);

    controller
      ..addText('No Name Ketchup')
      ..addText('No-Name Senf');
    expect(container.read(freeCookingControllerProvider).rows, [
      'No Name Ketchup',
      'No-Name Senf',
    ]);
  });

  test('removes a row', () {
    final container = _container(_FakeCookingService());
    container.read(freeCookingControllerProvider.notifier)
      ..addText('500 g Hähnchen, Salz')
      ..removeRow(0);

    expect(container.read(freeCookingControllerProvider).rows, ['Salz']);
  });

  test('cook assigns stock rows and clears the draft', () async {
    final service = _FakeCookingService();
    final container = _container(service);
    final notifier = container.read(freeCookingControllerProvider.notifier)
      ..addText('500 g Hähnchen, Salz');
    final rows = await _rows(container);

    final saved = await notifier.cook(name: 'Pfanne', rows: rows);

    expect(saved, 'meal');
    expect(service.calls.single.ingredients, ['500 g Hähnchen', 'Salz']);
    expect(service.calls.single.assignments, {
      '500 g Hähnchen': ['hähnchen'],
    });
    expect(container.read(freeCookingControllerProvider).rows, isEmpty);
  });

  test('a row cooks from the item it shows, and an exact name in another '
      'unit lets no weaker match stand in (#785)', () async {
    // "Reis" in the brand makes Langkornreis a weak match for "Testreis".
    final longGrain = _item('Langkornreis', brand: 'Reis-Fit');
    final service = _FakeCookingService();
    final pieces = _container(
      service,
      items: [
        longGrain,
        _item('Testreis', unit: InventoryAmountUnit.piece),
      ],
    );
    final notifier = pieces.read(freeCookingControllerProvider.notifier)
      ..addText('100 g Testreis');
    final rows = await _rows(pieces);

    expect(rows.single.isInStock, isFalse);
    await notifier.cook(name: 'Test', rows: rows);
    expect(service.calls.single.assignments, isEmpty);

    final grams = _container(service, items: [longGrain, _item('Testreis')]);
    grams
        .read(freeCookingControllerProvider.notifier)
        .addText('100 g Testreis');
    final shown = await _rows(grams);

    expect(shown.single.stockItem?.id, 'testreis');
    await grams
        .read(freeCookingControllerProvider.notifier)
        .cook(name: 'Test', rows: shown);
    expect(service.calls.last.assignments, {
      '100 g Testreis': ['testreis'],
    });
  });

  test('the cook picks the item of a row, also for a row without an '
      'amount, and "Kochen" takes the pick (#837)', () async {
    final service = _FakeCookingService();
    final container = _container(
      service,
      items: [_item('Hähnchen'), _item('Hähnchenbrust'), _item('Salz')],
    );
    final notifier = container.read(freeCookingControllerProvider.notifier)
      ..addText('500 g Hähnchen, Salz, Pfeffer');
    var rows = await _rows(container);

    expect(rows.map((row) => row.stockItem?.id), ['hähnchen', null, null]);
    expect(rows[1].candidates.map((item) => item.id), ['salz']);
    expect(rows[2].candidates, isEmpty);

    notifier
      ..pick('500 g Hähnchen', 'hähnchenbrust')
      ..pick('Salz', 'salz');
    rows = await _rows(container);
    expect(rows.map((row) => row.stockItem?.id), [
      'hähnchenbrust',
      'salz',
      null,
    ]);

    notifier.pick('500 g Hähnchen', null);
    rows = await _rows(container);
    expect(rows.first.isInStock, isFalse);

    await notifier.cook(name: 'Pfanne', rows: rows);
    expect(service.calls.single.assignments, {
      'Salz': ['salz'],
    });
    expect(container.read(freeCookingControllerProvider).picks, isEmpty);
  });

  test('rows with the same text share their pick, "Kochen" saves it for '
      'all of them, and it goes with the last row of its text', () async {
    final service = _FakeCookingService();
    final container = _container(service, items: [_item('Salz')]);
    final notifier = container.read(freeCookingControllerProvider.notifier)
      ..addText('Salz, Pfeffer, Salz')
      ..pick('Salz', 'salz');
    var rows = await _rows(container);
    expect(rows.map((row) => row.stockItem?.id), ['salz', null, 'salz']);

    notifier.removeRow(0);
    rows = await _rows(container);
    expect(rows.map((row) => row.stockItem?.id), [null, 'salz']);

    notifier
      ..removeRow(1)
      ..addText('Salz');
    rows = await _rows(container);
    expect(rows.map((row) => row.stockItem?.id), [null, null]);

    notifier
      ..pick('Salz', 'salz')
      ..addText('nein, Salz');
    rows = await _rows(container);
    expect(rows.map((row) => row.stockItem?.id), [null, null]);

    notifier
      ..addText('Salz')
      ..pick('Salz', 'salz');
    rows = await _rows(container);
    expect(rows.map((row) => row.stockItem?.id), [null, 'salz', 'salz']);
    await notifier.cook(name: 'Pfanne', rows: rows);
    expect(service.calls.single.assignments, {
      'Salz': ['salz'],
    });
  });

  test('cook keeps the rows when saving fails', () async {
    final container = _container(_FakeCookingService(succeeds: false));
    final notifier = container.read(freeCookingControllerProvider.notifier)
      ..addText('Salz');
    final rows = await _rows(container);

    final saved = await notifier.cook(name: 'Pfanne', rows: rows);

    expect(saved, isNull);
    final draft = container.read(freeCookingControllerProvider);
    expect(draft.rows, ['Salz']);
    expect(draft.isCooking, isFalse);
  });

  test('rows fail with the Vorrat', () async {
    final container = ProviderContainer(
      overrides: [
        inventoryQuickEatItemsProvider.overrideWith(
          (ref) => Stream<List<InventoryItem>>.error(StateError('offline')),
        ),
        preparedMealCookingServiceProvider.overrideWithValue(
          _FakeCookingService(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = freeCookingRowsProvider('de');
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    while (!container.read(provider).hasError) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(container.read(provider).hasError, isTrue);
  });
}
