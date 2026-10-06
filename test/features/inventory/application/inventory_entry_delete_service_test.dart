import 'package:cryptography/cryptography.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/domain/combined_calorie_entry.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_entry_delete_service.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

const _householdId = 'household-1';
final _loggedAt = DateTime(2026, 3, 27, 8);

late PayloadCipher _dataCipher;

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

late SecretKey _householdKey;

/// Lists the items that the Vorrat holds, for the source checks.
class _Items implements InventoryItemRepository {
  new(this.items);

  List<InventoryItem> items;
  Error? readError;

  @override
  Future<List<InventoryItem>> readAll() async {
    if (readError case final error?) throw error;
    return items;
  }

  @override
  Stream<List<InventoryItem>> watchAll() => Stream.value(items);

  @override
  Future<bool> saveAll(List<InventoryItem> items) async => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;
}

class _Meals implements PreparedMealRepository {
  new(this.meals);

  List<PreparedMeal> meals;

  @override
  Future<List<PreparedMeal>> readAll() async => meals;

  @override
  Stream<List<PreparedMeal>> watchAll() => Stream.value(meals);

  @override
  Future<bool> saveAll(List<PreparedMeal> meals) async => true;
}

/// The service on one fake Firestore, with the real commit stores and the
/// real diary repository.
class _World {
  new() {
    final household = (
      householdId: _householdId,
      key: _householdKey,
      cipher: PayloadCipher(_householdKey),
    );
    final dataCipher = (uid: 'user-1', cipher: _dataCipher);
    diary = FirestoreCalorieLogRepository(
      dataCipher: dataCipher,
      firestore: firestore,
    );
    service = InventoryEntryDeleteService(
      diary: diary,
      saver: _save,
      dayChange: (day) async => changedDays.add(day),
      itemStore: FirestoreInventoryCalorieEntryCommitStore(
        firestore: firestore,
        dataCipher: dataCipher,
        householdCipher: household,
        actor: null,
      ),
      mealStore: FirestorePreparedMealCalorieEntryCommitStore(
        firestore: firestore,
        dataCipher: dataCipher,
        householdCipher: household,
      ),
      items: items,
      meals: meals,
      pendings: pendings,
    );
    pendings.finalizations.listen(reportedStock.add);
  }

  final InventoryPendingConsumptionStore pendings = _container().read(
    inventoryPendingConsumptionStoreProvider,
  );
  final reportedStock = <InventoryPendingConsumptionFinalized>[];

  final firestore = FakeFirebaseFirestore();
  final items = _Items([]);
  final meals = _Meals([]);
  final changedDays = <DateTime>[];
  late final FirestoreCalorieLogRepository diary;
  late final InventoryEntryDeleteService service;

  Future<bool> _save(
    CalorieEntry entry, {
    bool isNewEntry = false,
    CalorieScannedSourceRef? scannedSourceRef,
    Future<bool> Function(CalorieEntry entry)? persistEntry,
  }) => persistEntry?.call(entry) ?? diary.saveEntry(entry);

  SealedCollection get _itemCollection => SealedCollection(
    firestore
        .collection('households')
        .doc(_householdId)
        .collection('inventory_items'),
    cipher: PayloadCipher(_householdKey),
    plaintextFields: inventoryItemPlaintextFields,
  );

  SealedCollection get _mealCollection => SealedCollection(
    firestore
        .collection('households')
        .doc(_householdId)
        .collection('prepared_meals'),
    cipher: PayloadCipher(_householdKey),
  );

  Future<void> putItem(InventoryItem item) async {
    items.items = [...items.items, item];
    final ref = _itemCollection.reference.doc(item.id);
    await ref.set(await _itemCollection.seal(item.id, item.toJson()));
  }

  Future<InventoryItem> item(String id) async {
    final snapshot = await _itemCollection.reference.doc(id).get();
    return InventoryItem.fromJson({
      ...?await _itemCollection.open(snapshot),
      'id': id,
    });
  }

  Future<void> putMeal(PreparedMeal meal) async {
    meals.meals = [...meals.meals, meal];
    final ref = _mealCollection.reference.doc(meal.id);
    await ref.set(await _mealCollection.seal(meal.id, meal.toJson()));
  }

  Future<PreparedMeal> meal(String id) async {
    final snapshot = await _mealCollection.reference.doc(id).get();
    return PreparedMeal.fromJson({
      ...?await _mealCollection.open(snapshot),
      'id': id,
    });
  }

  Future<bool> hasEntry(String id) async {
    final snapshot = await firestore
        .collection('users')
        .doc('user-1')
        .collection('calorie_entries')
        .doc(id)
        .get();
    return snapshot.exists;
  }
}

InventoryItem _milk({String id = 'milk', int currentAmount = 750}) {
  return InventoryItem.create(
    id: id,
    name: 'Milch',
    entryDate: DateTime(2026, 3, 20),
    storeName: 'Aldi',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: currentAmount,
    amountUnit: InventoryAmountUnit.milliliter,
  );
}

CalorieEntry _milkEntry() {
  return CalorieEntry.create(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Milch',
    mealType: MealType.breakfast,
    consumedAmount: 250,
    consumedUnit: ConsumedUnit.milliliters,
    per100Kcal: 60,
    per100Protein: 3.2,
    per100Carbs: 4.8,
    per100Fat: 1.5,
    sourceInventoryItemId: 'milk',
    sourceInventoryAmountToRestore: 250,
    loggedAt: _loggedAt,
    createdAt: _loggedAt,
    updatedAt: _loggedAt,
  );
}

CalorieEntryBundleComponent _food(String itemId, int amount) {
  return CalorieEntryBundleComponent(
    name: itemId,
    amountLabel: '$amount ml',
    totalKcal: 100,
    totalProtein: 1,
    totalCarbs: 1,
    totalFat: 1,
    sourceInventoryItemId: itemId,
    sourceInventoryAmountToRestore: amount,
  );
}

CalorieEntry _combinedEntry() {
  return buildCombinedCalorieEntry(
    id: 'entry-1',
    userId: 'user-1',
    mealType: MealType.breakfast,
    loggedAt: _loggedAt,
    now: _loggedAt,
    components: [_food('milk', 200), _food('oat-milk', 100)],
  );
}

PreparedMeal _chili({num remainingPortions = 2}) {
  return PreparedMeal(
    id: 'chili',
    name: 'Chili',
    totalPortions: 4,
    remainingPortions: remainingPortions,
    totalKcal: 2000,
    totalProtein: 100,
    totalCarbs: 200,
    totalFat: 80,
    createdAt: DateTime(2026, 3, 26),
    updatedAt: DateTime(2026, 3, 26),
    components: const <PreparedMealComponent>[],
  );
}

CalorieEntry _chiliEntry() {
  return CalorieEntry.bundle(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Chili',
    mealType: MealType.lunch,
    totalKcal: 500,
    totalProtein: 25,
    totalCarbs: 50,
    totalFat: 20,
    bundleSourcePreparedMealId: 'chili',
    bundleConsumedPortions: 1,
    bundleTotalPortions: 4,
    bundleComponents: const <CalorieEntryBundleComponent>[],
    loggedAt: _loggedAt,
    createdAt: _loggedAt,
    updatedAt: _loggedAt,
  );
}

void main() {
  setUpAll(() async {
    _dataCipher = PayloadCipher(await PayloadCipher.newDataKey());
    _householdKey = await PayloadCipher.newDataKey();
  });

  group('delete', () {
    test('gives the stock back and deletes the entry in one write', () async {
      final world = _World();
      await world.putItem(_milk());
      await world.diary.saveEntry(_milkEntry());

      final result = await world.service.delete(
        _milkEntry(),
        restoreToInventory: true,
      );
      await pumpEventQueue();

      expect(result.isSuccess, isTrue);
      expect(result.restoredToInventory, isTrue);
      expect(await world.hasEntry('entry-1'), isFalse);
      expect((await world.item('milk')).currentAmount, 1000);
      expect(world.reportedStock.single.currentAmount, 1000);
      expect(world.changedDays, [_loggedAt]);
    });

    test('a missing item keeps the entry', () async {
      final world = _World();
      await world.diary.saveEntry(_milkEntry());

      final result = await world.service.delete(
        _milkEntry(),
        restoreToInventory: true,
      );
      await pumpEventQueue();

      expect(
        result.failureReason,
        CalorieEntryDeleteFailureReason.sourceMissing,
      );
      expect(await world.hasEntry('entry-1'), isTrue);
      expect(world.changedDays, isEmpty);
    });

    test('without restore the stock stays', () async {
      final world = _World();
      await world.putItem(_milk());
      await world.diary.saveEntry(_milkEntry());

      final result = await world.service.delete(
        _milkEntry(),
        restoreToInventory: false,
      );
      await pumpEventQueue();

      expect(result.isSuccess, isTrue);
      expect(result.restoredToInventory, isFalse);
      expect(await world.hasEntry('entry-1'), isFalse);
      expect((await world.item('milk')).currentAmount, 750);
      expect(world.changedDays, [_loggedAt]);
    });

    test('a combined entry gives stock to the foods that exist', () async {
      final world = _World();
      await world.putItem(_milk());
      await world.diary.saveEntry(_combinedEntry());

      final result = await world.service.delete(
        _combinedEntry(),
        restoreToInventory: true,
      );
      await pumpEventQueue();

      expect(result.restoredToInventory, isTrue);
      expect(await world.hasEntry('entry-1'), isFalse);
      expect((await world.item('milk')).currentAmount, 950);
    });

    test('a cooked meal gets its portions back', () async {
      final world = _World();
      await world.putMeal(_chili());
      await world.diary.saveEntry(_chiliEntry());

      final result = await world.service.delete(
        _chiliEntry(),
        restoreToInventory: true,
      );
      await pumpEventQueue();

      expect(result.restoredToInventory, isTrue);
      expect(await world.hasEntry('entry-1'), isFalse);
      expect((await world.meal('chili')).remainingPortions, 3);
    });

    test('a cooked meal with all portions left takes none back', () async {
      final world = _World();
      await world.putMeal(_chili(remainingPortions: 4));
      await world.diary.saveEntry(_chiliEntry());

      final result = await world.service.delete(
        _chiliEntry(),
        restoreToInventory: true,
      );
      await pumpEventQueue();

      expect(
        result.failureReason,
        CalorieEntryDeleteFailureReason.restoreFailed,
      );
      expect(await world.hasEntry('entry-1'), isTrue);
    });
  });

  group('undoDelete', () {
    test('saves the entry and takes the given-back stock again', () async {
      final world = _World();
      await world.putItem(_milk());
      await world.diary.saveEntry(_milkEntry());
      await world.service.delete(_milkEntry(), restoreToInventory: true);
      await pumpEventQueue();

      final undone = await world.service.undoDelete(
        _milkEntry(),
        restoredToInventory: true,
      );
      await pumpEventQueue();

      expect(undone, isTrue);
      expect(await world.hasEntry('entry-1'), isTrue);
      expect((await world.item('milk')).currentAmount, 750);
      expect(world.reportedStock.last.currentAmount, 750);
    });

    test('takes the portions of a cooked meal again', () async {
      final world = _World();
      await world.putMeal(_chili());
      await world.diary.saveEntry(_chiliEntry());
      await world.service.delete(_chiliEntry(), restoreToInventory: true);
      await pumpEventQueue();

      final undone = await world.service.undoDelete(
        _chiliEntry(),
        restoredToInventory: true,
      );
      await pumpEventQueue();

      expect(undone, isTrue);
      expect(await world.hasEntry('entry-1'), isTrue);
      expect((await world.meal('chili')).remainingPortions, 2);
    });

    test('a single entry whose item is gone stays deleted', () async {
      final world = _World();
      await world.diary.saveEntry(_milkEntry());

      final undone = await world.service.undoDelete(
        _milkEntry(),
        restoredToInventory: true,
      );
      await pumpEventQueue();

      expect(undone, isFalse);
    });

    test('takes at most the stock that the item holds now', () async {
      final world = _World();
      await world.putItem(_milk(currentAmount: 100));

      final undone = await world.service.undoDelete(
        _milkEntry(),
        restoredToInventory: true,
      );
      await pumpEventQueue();

      expect(undone, isTrue);
      expect(await world.hasEntry('entry-1'), isTrue);
      expect((await world.item('milk')).currentAmount, 0);
    });

    test('a failed item read reports the undo as failed', () async {
      final world = _World();
      world.items.readError = StateError('read failed');

      final undone = await world.service.undoDelete(
        _milkEntry(),
        restoredToInventory: true,
      );

      expect(undone, isFalse);
      expect(await world.hasEntry('entry-1'), isFalse);
    });
  });

  test('canRestoreSource checks that the stock source still exists', () async {
    final world = _World();
    expect(await world.service.canRestoreSource(_milkEntry()), isFalse);
    expect(await world.service.canRestoreSource(_chiliEntry()), isFalse);

    await world.putItem(_milk());
    await world.putMeal(_chili());

    expect(await world.service.canRestoreSource(_milkEntry()), isTrue);
    expect(await world.service.canRestoreSource(_combinedEntry()), isTrue);
    expect(await world.service.canRestoreSource(_chiliEntry()), isTrue);
  });
}
