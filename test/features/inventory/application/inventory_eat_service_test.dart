import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/'
    'calorie_inventory_entry_save_handler.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/inventory_eat_service.dart';
import 'package:yamt/features/inventory/application/inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/data/inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';

import '../../calories/support/fake_calories_repositories.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

class _MockUser extends Mock implements User;

class _RecordingCommitStore implements InventoryCalorieEntryCommitStore {
  new({this.fails = false, this.gate});

  final bool fails;

  /// Holds the write open until it completes.
  final Future<void>? gate;
  CalorieEntry? entry;
  List<PendingInventoryConsumption>? pendings;

  @override
  Future<List<InventoryCalorieEntryCommitResult>?>
  commitEntryAndInventoryItems({
    required CalorieEntry entry,
    required List<PendingInventoryConsumption> pendingConsumptions,
  }) async {
    this.entry = entry;
    pendings = pendingConsumptions;
    await gate;
    if (fails) {
      return null;
    }
    return [
      for (final pending in pendingConsumptions)
        InventoryCalorieEntryCommitResult(
          itemId: pending.itemId,
          quantity: 1,
          currentAmount: 500,
        ),
    ];
  }
}

final DateTime _now = DateTime.parse('2026-10-05T12:00:00Z');

const _nutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 215,
  per100Protein: 4,
  per100Carbs: 25,
  per100Fat: 10,
);

InventoryItem _gramItem({GlobalFoodNutrition? nutrition = _nutrition}) {
  return InventoryItem.create(
    id: 'waffles',
    name: 'Waffles',
    barcode: '4061458029995',
    nutrition: nutrition,
    entryDate: _now,
    storeName: 'Aldi',
    quantity: 2,
    initialQuantity: 2,
    initialAmount: 1000,
    currentAmount: 750,
    amountUnit: InventoryAmountUnit.gram,
  );
}

InventoryItem _pieceItem() {
  return InventoryItem.create(
    id: 'eggs',
    name: 'Eggs',
    nutrition: _nutrition,
    entryDate: _now,
    storeName: 'Aldi',
    quantity: 6,
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
    loggedAt: _now,
    createdAt: _now,
    updatedAt: _now,
  );
}

InventoryItemEatRequest _request(int amount) {
  return InventoryItemEatRequest(
    inventoryAmount: amount,
    loggedAt: _now,
    mealType: MealType.lunch,
  );
}

typedef _Harness = ({
  ProviderContainer container,
  InventoryEatService service,
  InventoryPendingConsumptionStore pendings,
});

_Harness _harness(
  _RecordingCommitStore commitStore, {
  List<Override> overrides = const <Override>[],
}) {
  final auth = _MockFirebaseAuth();
  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');
  when(() => auth.currentUser).thenReturn(user);
  final calorieLog = FakeCalorieLogRepository();
  addTearDown(calorieLog.dispose);
  final container = ProviderContainer(
    overrides: [
      inventoryCalorieEntryCommitStoreProvider.overrideWithValue(commitStore),
      calorieLogRepositoryProvider.overrideWithValue(calorieLog),
      firebaseAuthProvider.overrideWithValue(auth),
      clockProvider.overrideWithValue(() => _now),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  final subscription = container.listen(inventoryEatServiceProvider, (_, _) {});
  addTearDown(subscription.close);
  return (
    container: container,
    service: subscription.read(),
    pendings: container.read(inventoryPendingConsumptionStoreProvider),
  );
}

void main() {
  group('log', () {
    test('saves the entry and the stock change in one write', () async {
      final commitStore = _RecordingCommitStore();
      final harness = _harness(commitStore);
      final finalized = <InventoryPendingConsumptionFinalized>[];
      harness.pendings.finalizations.listen(finalized.add);
      final pending = harness.pendings.stage(_gramItem(), 250)!;

      final outcome = await harness.service.log(
        item: _gramItem(),
        request: _request(250),
        pending: pending,
      );

      final entry = (outcome as InventoryEatLogged).entry;
      expect(entry.name, 'Waffles');
      expect(entry.userId, 'user-1');
      expect(entry.mealType, MealType.lunch);
      expect(entry.consumedAmount, 250);
      expect(entry.consumedUnit, ConsumedUnit.grams);
      expect(entry.sourceInventoryItemId, 'waffles');
      expect(entry.sourceInventoryAmountToRestore, 250);
      expect(entry.createdAt, _now);
      expect(commitStore.entry?.id, entry.id);
      expect(commitStore.pendings?.single.id, pending.id);
      expect(harness.pendings.pendingConsumptionById(pending.id), isNull);
      expect(finalized.single.itemId, 'waffles');
      expect(finalized.single.currentAmount, 500);
    });

    test('restores what the stock gave, not what was asked', () async {
      final commitStore = _RecordingCommitStore();
      final harness = _harness(commitStore);
      final pending = harness.pendings.stage(_gramItem(), 900)!;

      final outcome = await harness.service.log(
        item: _gramItem(),
        request: _request(900),
        pending: pending,
      );

      final entry = (outcome as InventoryEatLogged).entry;
      expect(entry.consumedAmount, 900);
      expect(entry.sourceInventoryAmountToRestore, 750);
    });

    test(
      'a failed write releases the stock and reports no new stock',
      () async {
        final harness = _harness(_RecordingCommitStore(fails: true));
        final finalized = <InventoryPendingConsumptionFinalized>[];
        harness.pendings.finalizations.listen(finalized.add);
        final pending = harness.pendings.stage(_gramItem(), 250)!;

        final outcome = await harness.service.log(
          item: _gramItem(),
          request: _request(250),
          pending: pending,
        );

        expect(outcome, isA<InventoryEatFailed>());
        expect(
          (outcome as InventoryEatFailed).failure,
          InventoryEatFailure.notSaved,
        );
        expect(harness.pendings.pendingConsumptionById(pending.id), isNull);
        expect(finalized, isEmpty);
      },
    );

    test('an item without nutrition fails and releases its stock', () async {
      final commitStore = _RecordingCommitStore();
      final harness = _harness(commitStore);
      final item = _gramItem(nutrition: null);
      final pending = harness.pendings.stage(item, 250)!;

      final outcome = await harness.service.log(
        item: item,
        request: _request(250),
        pending: pending,
      );

      expect(
        (outcome as InventoryEatFailed).failure,
        InventoryEatFailure.noNutrition,
      );
      expect(harness.pendings.pendingConsumptionById(pending.id), isNull);
      expect(commitStore.entry, isNull);
    });

    test('a portion in another unit than the stock needs the editor', () async {
      final commitStore = _RecordingCommitStore();
      final harness = _harness(commitStore);
      final pending = harness.pendings.stage(_gramItem(), 250)!;

      final outcome = await harness.service.log(
        item: _gramItem(),
        request: InventoryItemEatRequest(
          inventoryAmount: 250,
          loggedAt: _now,
          mealType: MealType.lunch,
          calorieAmount: 200,
          calorieUnit: ConsumedUnit.milliliters,
        ),
        pending: pending,
      );

      final editor = outcome as InventoryEatNeedsEditor;
      expect(editor.profile.name, 'Waffles');
      expect(editor.scannedSourceRef?.barcode, '4061458029995');
      expect(editor.inventoryContext.pendingConsumptionId, pending.id);
      expect(editor.inventoryContext.consumedUnit, ConsumedUnit.milliliters);
      expect(editor.inventoryContext.inventoryAmountToRestore, 250);
      expect(harness.pendings.pendingConsumptionById(pending.id), isNotNull);
      expect(commitStore.entry, isNull);
    });

    test('an eat that throws releases its stock', () async {
      final harness = _harness(_RecordingCommitStore());
      // A piece item needs a calorie portion; without one the eat throws.
      final pending = harness.pendings.stage(_pieceItem(), 2)!;

      await expectLater(
        harness.service.log(
          item: _pieceItem(),
          request: _request(2),
          pending: pending,
        ),
        throwsStateError,
      );

      expect(harness.pendings.pendingConsumptionById(pending.id), isNull);
    });
  });

  test('a write that lands after its stock was released still reports the '
      'new stock', () async {
    final gate = Completer<void>();
    final harness = _harness(_RecordingCommitStore(gate: gate.future));
    final finalized = <InventoryPendingConsumptionFinalized>[];
    harness.pendings.finalizations.listen(finalized.add);
    final pending = harness.pendings.stage(_gramItem(), 250)!;

    final logged = harness.service.log(
      item: _gramItem(),
      request: _request(250),
      pending: pending,
    );
    await Future<void>.delayed(Duration.zero);
    await harness.pendings.discard(pending.id);
    gate.complete();

    expect(await logged, isA<InventoryEatLogged>());
    expect(finalized.single.id, pending.id);
    expect(finalized.single.currentAmount, 500);
  });

  test('the calorie editor seams commit and release through the store, '
      'wired as in main.dart', () async {
    final commitStore = _RecordingCommitStore();
    final harness = _harness(
      commitStore,
      overrides: [
        calorieInventoryEntrySaveHandlerProvider.overrideWith(
          (ref) => ref.watch(inventoryEatServiceProvider).commitStaged,
        ),
        calorieInventoryPendingConsumptionDiscarderProvider.overrideWith(
          (ref) => ref.watch(inventoryPendingConsumptionStoreProvider).discard,
        ),
      ],
    );
    final saved = harness.pendings.stage(_gramItem(), 250)!;
    final canceled = harness.pendings.stage(_gramItem(), 100)!;

    final committed = await harness.container.read(
      calorieInventoryEntrySaveHandlerProvider,
    )!(entry: _entry(), pendingConsumptionId: saved.id);
    await harness.container.read(
      calorieInventoryPendingConsumptionDiscarderProvider,
    )!(canceled.id);

    expect(committed, isTrue);
    expect(commitStore.pendings?.single.id, saved.id);
    expect(harness.pendings.pendingConsumptionById(saved.id), isNull);
    expect(harness.pendings.pendingConsumptionById(canceled.id), isNull);
  });

  group('commitStaged', () {
    test('commits the consumption staged under the id', () async {
      final commitStore = _RecordingCommitStore();
      final harness = _harness(commitStore);
      final pending = harness.pendings.stage(_gramItem(), 250)!;
      final entry = _entry();

      final saved = await harness.service.commitStaged(
        entry: entry,
        pendingConsumptionId: pending.id,
      );
      final unknown = await harness.service.commitStaged(
        entry: entry,
        pendingConsumptionId: 'unknown',
      );

      expect(saved, isTrue);
      expect(commitStore.pendings?.single.id, pending.id);
      expect(harness.pendings.pendingConsumptionById(pending.id), isNull);
      expect(unknown, isFalse);
    });
  });
}
