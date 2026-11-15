import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/inventory/data/cooked_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';

import '../../recipes/cook_run_fixtures.dart';

const _actor = InventoryActivityActor(userId: 'user-1', displayName: 'Ada');
final _now = DateTime.utc(2026, 11, 1, 12);

InventoryItem _grams(String id, String name, int amount) =>
    InventoryItem.create(
      id: id,
      name: name,
      entryDate: DateTime.utc(2026, 10),
      storeName: 'Store',
      quantity: 1,
      initialAmount: 1000,
      currentAmount: amount,
      amountUnit: InventoryAmountUnit.gram,
    );

PreparedMeal _meal([String id = 'meal-1']) => PreparedMeal(
  id: id,
  name: 'Eintopf',
  totalPortions: 4,
  remainingPortions: 4,
  totalKcal: 0,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
  createdAt: _now,
  updatedAt: _now,
  components: const [],
);

void main() {
  late PayloadCipher cipher;
  late FakeFirebaseFirestore firestore;
  late DocumentReference<Map<String, dynamic>> household;

  setUp(() async {
    cipher = PayloadCipher(await PayloadCipher.newDataKey());
    firestore = FakeFirebaseFirestore();
    household = firestore.collection('households').doc('household-1');
  });

  SealedCollection items() => SealedCollection(
    household.collection('inventory_items'),
    cipher: cipher,
    plaintextFields: inventoryItemPlaintextFields,
  );

  Future<void> store(InventoryItem item) async {
    await items().reference
        .doc(item.id)
        .set(await items().seal(item.id, item.toJson()));
  }

  Future<InventoryItem?> readItem(String id) async {
    final data = await items().open(await items().reference.doc(id).get());
    return data == null ? null : InventoryItem.fromJson(data);
  }

  CookedMealRepository repository({InventoryActivityActor? actor = _actor}) {
    final scope = (
      householdId: 'household-1',
      firestore: firestore,
      cipher: cipher,
    );
    return CookedMealRepository(
      scope: scope,
      actor: actor,
      cookRuns: CookRunRepository(scope: scope),
    );
  }

  CookedStockChange change(InventoryItem before, int amount) =>
      (before: before, after: before.reducedBy(amount)!);

  group('addCookedMeals', () {
    CookRunRepository runs() => CookRunRepository(
      scope: (householdId: 'household-1', firestore: firestore, cipher: cipher),
    );

    Future<void> startRun([String id = 'run-1']) async {
      final repo = runs();
      await repo.create(buildCookRun(id: id));
      await repo.pending;
      await pumpEventQueue();
    }

    Future<bool> exists(String collection, String id) async =>
        (await household.collection(collection).doc(id).get()).exists;

    Future<void> finish(
      CookedMealRepository repo, {
      List<PreparedMeal>? meals,
      List<CookedStockChange> changes = const [],
      List<String> deleteItemIds = const [],
      DateTime? startedAt,
    }) => repo.addCookedMeals(
      meals: meals ?? [_meal()],
      changes: changes,
      deleteItemIds: deleteItemIds,
      happenedAt: _now,
      endedRun: buildCookRun(id: 'run-1', startedAt: startedAt),
    );

    final cookingId = buildCookRun(id: 'run-1').cookingId;

    test('writes every meal under its own id', () async {
      await startRun();

      await finish(
        repository(),
        meals: [_meal('pot-a'), _meal('pot-b'), _meal('pot-c')],
      );
      await pumpEventQueue();

      for (final id in ['pot-a', 'pot-b', 'pot-c']) {
        expect(await exists('prepared_meals', id), isTrue, reason: id);
      }
    });

    test('takes the stock once with an event per item and run', () async {
      final mince = _grams('mince', 'Hackfleisch', 800);
      final carrots = _grams('carrots', 'Karotten', 500);
      await store(mince);
      await store(carrots);
      await startRun();

      await finish(
        repository(),
        changes: [change(mince, 600), change(carrots, 200)],
      );
      await pumpEventQueue();

      expect((await readItem('mince'))!.currentAmount, 200);
      expect((await readItem('carrots'))!.currentAmount, 300);
      final events = await household
          .collection('inventory_activity_events')
          .get();
      expect(events.docs.map((doc) => doc.id).toSet(), {
        '$cookingId-mince',
        '$cookingId-carrots',
      });
    });

    test('an old piece item without a scale keeps its pieces', () async {
      final legacy = {
        ...InventoryItem.create(
          id: 'eggs',
          name: 'Eier',
          entryDate: DateTime.utc(2026, 3),
          storeName: 'Store',
          quantity: 6,
          initialAmount: 6,
          currentAmount: 6,
          amountUnit: InventoryAmountUnit.piece,
        ).toJson(),
        'initial_amount': 6,
        'current_amount': 6,
      }..remove('amount_scale');
      await items().reference
          .doc('eggs')
          .set(await items().seal('eggs', legacy));
      await startRun();
      final eggs = (await readItem('eggs'))!;
      expect(eggs.availableAmount, 6000);

      await finish(repository(), changes: [change(eggs, 2000)]);
      await pumpEventQueue();

      final stored = (await readItem('eggs'))!;
      expect(stored.availableAmount, 4000);
      expect(stored.initialAmount, 6000);
      expect(stored.amountScale, inventoryPieceAmountScale);
    });

    test('a stock change keeps the initial amount and scale', () async {
      final eggs = InventoryItem.create(
        id: 'eggs',
        name: 'Eier',
        entryDate: DateTime.utc(2026, 10),
        storeName: 'Store',
        quantity: 10,
        initialAmount: 10000,
        currentAmount: 6000,
        amountScale: inventoryPieceAmountScale,
        amountUnit: InventoryAmountUnit.piece,
      );
      final mince = _grams('mince', 'Hackfleisch', 800);
      await store(eggs);
      await store(mince);
      await startRun();

      await finish(
        repository(),
        changes: [change(eggs, 2000), change(mince, 300)],
      );
      await pumpEventQueue();

      final storedEggs = (await readItem('eggs'))!;
      expect(storedEggs.availableAmount, 4000);
      expect(storedEggs.initialAmount, 10000);
      expect(storedEggs.amountScale, inventoryPieceAmountScale);
      final storedMince = (await readItem('mince'))!;
      expect(storedMince.availableAmount, 500);
      expect(storedMince.initialAmount, 1000);
      expect(storedMince.amountScale, mince.amountScale);
    });

    test('a later cooking of the same run id writes new event ids', () async {
      final mince = _grams('mince', 'Hackfleisch', 800);
      await store(mince);
      await startRun();
      await finish(repository(), changes: [change(mince, 200)]);
      await pumpEventQueue();
      await startRun();

      await finish(
        repository(),
        changes: [change(_grams('mince', 'Hackfleisch', 600), 100)],
        startedAt: cookRunStart.add(const Duration(days: 1)),
      );
      await pumpEventQueue();

      expect((await readItem('mince'))!.currentAmount, 500);
      final events = await household
          .collection('inventory_activity_events')
          .get();
      expect(events.docs, hasLength(2));
    });

    test('a second finish of the run does not take the stock twice', () async {
      final mince = _grams('mince', 'Hackfleisch', 800);
      await store(mince);
      await startRun();

      await finish(repository(), changes: [change(mince, 600)]);
      await pumpEventQueue();
      // The second device read the stock before the first one finished.
      await expectLater(
        finish(repository(), changes: [change(mince, 600)]),
        throwsStateError,
      );
      await pumpEventQueue();

      expect((await readItem('mince'))!.currentAmount, 200);
      final events = await household
          .collection('inventory_activity_events')
          .get();
      expect(events.docs, hasLength(1));
    });

    test('writes no events without an actor', () async {
      final mince = _grams('mince', 'Hackfleisch', 800);
      await store(mince);
      await startRun();

      await finish(repository(actor: null), changes: [change(mince, 600)]);
      await pumpEventQueue();

      expect((await readItem('mince'))!.currentAmount, 200);
      final events = await household
          .collection('inventory_activity_events')
          .get();
      expect(events.docs, isEmpty);
    });

    test('deletes the added items and the run in the same batch', () async {
      await store(_grams('added', 'Zwiebel', 300));
      await store(_grams('kept', 'Reis', 900));
      await startRun();

      await finish(repository(), deleteItemIds: ['added']);
      await pumpEventQueue();

      expect(await exists('inventory_items', 'added'), isFalse);
      expect(await exists('inventory_items', 'kept'), isTrue);
      expect(await exists('cook_runs', 'run-1'), isFalse);
      expect(await exists('prepared_meals', 'meal-1'), isTrue);
    });

    test('a missing item writes nothing and keeps the run', () async {
      final mince = _grams('mince', 'Hackfleisch', 800);
      final gone = _grams('gone', 'Reis', 900);
      await store(mince);
      await store(_grams('added', 'Zwiebel', 300));
      await startRun();

      await expectLater(
        finish(
          repository(),
          changes: [change(mince, 600), change(gone, 100)],
          deleteItemIds: ['added'],
        ),
        throwsStateError,
      );
      await pumpEventQueue();

      expect((await readItem('mince'))!.currentAmount, 800);
      expect(await exists('prepared_meals', 'meal-1'), isFalse);
      expect(await exists('inventory_items', 'added'), isTrue);
      expect(await exists('cook_runs', 'run-1'), isTrue);
    });

    test('a changed item writes nothing and keeps the run', () async {
      final mince = _grams('mince', 'Hackfleisch', 800);
      await store(_grams('mince', 'Hackfleisch', 500));
      await startRun();

      await expectLater(
        finish(repository(), changes: [change(mince, 600)]),
        throwsStateError,
      );
      await pumpEventQueue();

      expect((await readItem('mince'))!.currentAmount, 500);
      expect(await exists('prepared_meals', 'meal-1'), isFalse);
      expect(await exists('cook_runs', 'run-1'), isTrue);
    });

    test('more than 500 writes throws before anything is written', () async {
      await startRun();

      await expectLater(
        finish(
          repository(),
          deleteItemIds: [for (var i = 0; i < 500; i++) 'item-$i'],
        ),
        throwsStateError,
      );
      await pumpEventQueue();

      expect(await exists('prepared_meals', 'meal-1'), isFalse);
      expect(await exists('cook_runs', 'run-1'), isTrue);
    });

    test('exactly 500 writes still go through', () async {
      await startRun();

      await finish(
        repository(),
        deleteItemIds: [for (var i = 0; i < 498; i++) 'item-$i'],
      );
      await pumpEventQueue();

      expect(await exists('prepared_meals', 'meal-1'), isTrue);
      expect(await exists('cook_runs', 'run-1'), isFalse);
    });

    test('the same item twice throws an ArgumentError', () async {
      final mince = _grams('mince', 'Hackfleisch', 800);
      await store(mince);
      await startRun();

      await expectLater(
        finish(repository(), changes: [change(mince, 300), change(mince, 200)]),
        throwsArgumentError,
      );
      await pumpEventQueue();

      expect((await readItem('mince'))!.currentAmount, 800);
      expect(await exists('cook_runs', 'run-1'), isTrue);
    });

    test('signed out throws a StateError', () async {
      await expectLater(
        finish(
          CookedMealRepository(
            scope: null,
            actor: null,
            cookRuns: CookRunRepository(scope: null),
          ),
        ),
        throwsStateError,
      );
    });
  });
}
