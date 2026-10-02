import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/domain/free_cooking_row.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'free_cooking_controller.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_cooking_service.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

InventoryItem _item(String name) {
  return InventoryItem.create(
    id: name.toLowerCase(),
    name: name,
    entryDate: DateTime.utc(2026, 9, 29),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 600,
    currentAmount: 600,
    amountUnit: InventoryAmountUnit.gram,
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
  Future<void> finishCooking({
    required String mealId,
    required int totalPortions,
    required int? potTareWeight,
    required int? finalNetWeight,
  }) async {}
}

ProviderContainer _container(_FakeCookingService service) {
  final container = ProviderContainer(
    overrides: [
      inventoryQuickEatItemsProvider.overrideWith(
        (ref) => Stream.value([_item('Hähnchen')]),
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
