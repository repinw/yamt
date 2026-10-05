import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';
import 'package:yamt/features/inventory/application/inventory_eat_service.dart';
import 'package:yamt/features/inventory/application/inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_controller.dart';

import '../../../calories/support/fake_planned_entry_repository.dart';

class _MockEatService extends Mock implements InventoryEatService;

class _MockDeleteFlow extends Mock implements CalorieEntryDeleteFlow;

final DateTime _now = DateTime.parse('2026-10-05T12:00:00Z');

InventoryItem _item() {
  return InventoryItem.create(
    id: 'waffles',
    name: 'Waffles',
    entryDate: _now,
    storeName: 'Aldi',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: 750,
    amountUnit: InventoryAmountUnit.gram,
  );
}

CalorieEntry _entry() {
  return CalorieEntry.create(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Waffles',
    mealType: MealType.lunch,
    consumedAmount: 250,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 215,
    per100Protein: 4,
    per100Carbs: 25,
    per100Fat: 10,
    sourceInventoryItemId: 'waffles',
    sourceInventoryAmountToRestore: 250,
    loggedAt: _now,
    createdAt: _now,
    updatedAt: _now,
  );
}

ProviderContainer _container({List<Override> overrides = const []}) {
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('log keeps the eat service alive until its write is done', () async {
    final service = _MockEatService();
    var serviceDisposed = false;
    final container = _container(
      overrides: [
        inventoryEatServiceProvider.overrideWith((ref) {
          ref.onDispose(() => serviceDisposed = true);
          return service;
        }),
      ],
    );
    final eating = container.read(inventoryItemEatControllerProvider.notifier);
    final item = _item();
    final request = InventoryItemEatRequest(
      inventoryAmount: 250,
      loggedAt: _now,
      mealType: MealType.lunch,
    );
    final pending = eating.stage(item, 250)!;
    final write = Completer<InventoryEatOutcome>();
    when(() => service.log(item: item, request: request, pending: pending))
        .thenAnswer((_) => write.future);

    final outcome = eating.log(item: item, request: request, pending: pending);
    await container.pump();
    expect(serviceDisposed, isFalse);

    write.complete(const InventoryEatFailed(InventoryEatFailure.notSaved));
    expect(await outcome, isA<InventoryEatFailed>());
    await container.pump();
    expect(serviceDisposed, isTrue);
  });

  test(
    'discard releases the stock after the controller was disposed',
    () async {
      final container = _container();
      final eating = container.read(
        inventoryItemEatControllerProvider.notifier,
      );
      final pending = eating.stage(_item(), 250)!;
      await container.pump();
      expect(container.exists(inventoryItemEatControllerProvider), isFalse);

      expect(await eating.discard(pending.id), isTrue);

      expect(
        container
            .read(inventoryPendingConsumptionStoreProvider)
            .pendingConsumptionById(pending.id),
        isNull,
      );
    },
  );

  test('undo deletes the entry and returns its stock', () async {
    final deleteFlow = _MockDeleteFlow();
    final entry = _entry();
    when(() => deleteFlow.deleteEntry(entry: entry, restoreToInventory: true))
        .thenAnswer(
          (_) async =>
              const CalorieEntryDeleteResult.success(restoredToInventory: true),
        );
    final container = _container(
      overrides: [calorieEntryDeleteFlowProvider.overrideWithValue(deleteFlow)],
    );

    final undone = await container
        .read(inventoryItemEatControllerProvider.notifier)
        .undo(entry);

    expect(undone, isTrue);
    verify(() => deleteFlow.deleteEntry(entry: entry, restoreToInventory: true))
        .called(1);
  });

  test('unplan deletes the plan and reloads the diary', () async {
    final plan = _entry();
    final plans = FakePlannedEntryRepository(plans: [plan]);
    final container = _container(
      overrides: [plannedEntryRepositoryProvider.overrideWithValue(plans)],
    );

    final undone = await container
        .read(inventoryItemEatControllerProvider.notifier)
        .unplan(plan);

    expect(undone, isTrue);
    expect(plans.plans, isEmpty);
    expect(container.read(calorieOverviewRevisionProvider), 1);
  });

  test('a failed unplan keeps the plan and the diary', () async {
    final plan = _entry();
    final plans = FakePlannedEntryRepository(plans: [plan])
      ..writeShouldFail = true;
    final container = _container(
      overrides: [plannedEntryRepositoryProvider.overrideWithValue(plans)],
    );

    final undone = await container
        .read(inventoryItemEatControllerProvider.notifier)
        .unplan(plan);

    expect(undone, isFalse);
    expect(plans.plans, [plan]);
    expect(container.read(calorieOverviewRevisionProvider), 0);
  });
}
