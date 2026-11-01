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

PreparedMeal _meal() => PreparedMeal(
  id: 'meal-1',
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

  CookedMealRepository repository({InventoryActivityActor? actor = _actor}) =>
      CookedMealRepository(
        scope: (
          householdId: 'household-1',
          firestore: firestore,
          cipher: cipher,
        ),
        actor: actor,
      );

  CookedStockChange change(InventoryItem before, int amount) =>
      (before: before, after: before.reducedBy(amount)!);

  test('patches the stock, writes events and the meal in one batch', () async {
    final mince = _grams('mince', 'Hackfleisch', 800);
    final carrots = _grams('carrots', 'Karotten', 500);
    await store(mince);
    await store(carrots);

    await repository().addCookedMeal(
      meal: _meal(),
      changes: [change(mince, 600), change(carrots, 200)],
      happenedAt: _now,
    );
    await pumpEventQueue();

    expect((await readItem('mince'))!.currentAmount, 200);
    expect((await readItem('carrots'))!.currentAmount, 300);
    expect((await readItem('mince'))!.name, 'Hackfleisch');

    final meals = SealedCollection(
      household.collection('prepared_meals'),
      cipher: cipher,
    );
    final stored = await meals.open(await meals.reference.doc('meal-1').get());
    expect(PreparedMeal.fromJson(stored!).name, 'Eintopf');

    final events = SealedCollection(
      household.collection('inventory_activity_events'),
      cipher: cipher,
      plaintextFields: inventoryActivityEventPlaintextFields,
    );
    final snapshot = await events.reference.get();
    final written = [
      for (final doc in snapshot.docs)
        InventoryActivityEvent.fromJson((await events.open(doc))!),
    ];
    expect(written, hasLength(2));
    expect(written.map((event) => event.type).toSet(), {
      InventoryActivityEventType.itemUsedInPreparedMeal,
    });
    expect(written.map((event) => event.amount).toSet(), {600, 200});
    expect(written.every((event) => event.happenedAt == _now), isTrue);
  });

  test('writes no events without an actor', () async {
    final mince = _grams('mince', 'Hackfleisch', 800);
    await store(mince);

    await repository(actor: null).addCookedMeal(
      meal: _meal(),
      changes: [change(mince, 600)],
      happenedAt: _now,
    );
    await pumpEventQueue();

    expect((await readItem('mince'))!.currentAmount, 200);
    final events = await household
        .collection('inventory_activity_events')
        .get();
    expect(events.docs, isEmpty);
  });

  test('a meal without stock changes is still added', () async {
    await repository().addCookedMeal(
      meal: _meal(),
      changes: const [],
      happenedAt: _now,
    );
    await pumpEventQueue();

    final doc = await household
        .collection('prepared_meals')
        .doc('meal-1')
        .get();
    expect(doc.exists, isTrue);
  });

  test('a missing item throws a StateError and writes nothing', () async {
    final mince = _grams('mince', 'Hackfleisch', 800);
    final gone = _grams('gone', 'Reis', 900);
    await store(mince);

    await expectLater(
      repository().addCookedMeal(
        meal: _meal(),
        changes: [change(mince, 600), change(gone, 100)],
        happenedAt: _now,
      ),
      throwsStateError,
    );
    await pumpEventQueue();

    expect((await readItem('mince'))!.currentAmount, 800);
    final doc = await household
        .collection('prepared_meals')
        .doc('meal-1')
        .get();
    expect(doc.exists, isFalse);
  });

  test('a stock change since the read throws and keeps it', () async {
    final mince = _grams('mince', 'Hackfleisch', 800);
    await store(_grams('mince', 'Hackfleisch', 500));

    await expectLater(
      repository().addCookedMeal(
        meal: _meal(),
        changes: [change(mince, 600)],
        happenedAt: _now,
      ),
      throwsStateError,
    );
    await pumpEventQueue();

    expect((await readItem('mince'))!.currentAmount, 500);
  });

  test('signed out throws a StateError', () async {
    await expectLater(
      const CookedMealRepository(
        scope: null,
        actor: null,
      ).addCookedMeal(meal: _meal(), changes: const [], happenedAt: _now),
      throwsStateError,
    );
  });
}
