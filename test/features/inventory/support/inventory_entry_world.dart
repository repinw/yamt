import 'package:cryptography/cryptography.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_entry_amount_service.dart';
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
final entryLoggedAt = DateTime(2026, 3, 27, 8);

late PayloadCipher _dataCipher;

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

late SecretKey _householdKey;

/// Lists the items that the Vorrat holds, for the source checks.
class FakeEntryItems implements InventoryItemRepository {
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

class FakeEntryMeals implements PreparedMealRepository {
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
class InventoryEntryWorld {
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
    final itemStore = FirestoreInventoryCalorieEntryCommitStore(
      firestore: firestore,
      dataCipher: dataCipher,
      householdCipher: household,
      actor: null,
    );
    amounts = InventoryEntryAmountService(
      saver: _save,
      itemStore: itemStore,
      items: items,
      pendings: pendings,
      now: () => entryLoggedAt,
    );
    service = InventoryEntryDeleteService(
      diary: diary,
      saver: _save,
      dayChange: (day) async => changedDays.add(day),
      itemStore: itemStore,
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
  final items = FakeEntryItems([]);
  final meals = FakeEntryMeals([]);
  final changedDays = <DateTime>[];
  late final FirestoreCalorieLogRepository diary;
  late final InventoryEntryDeleteService service;
  late final InventoryEntryAmountService amounts;

  Future<CalorieEntry> entry(String id) async => (await diary.getById(id))!;

  Future<bool> _save(
    CalorieEntry entry, {
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

InventoryItem milkItem({String id = 'milk', int currentAmount = 750}) {
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

CalorieEntry milkEntry() {
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
    loggedAt: entryLoggedAt,
    createdAt: entryLoggedAt,
    updatedAt: entryLoggedAt,
  );
}

/// Creates the keys of the diary and the household. Call it in `setUpAll`.
Future<void> setUpInventoryEntryKeys() async {
  _dataCipher = PayloadCipher(await PayloadCipher.newDataKey());
  _householdKey = await PayloadCipher.newDataKey();
}
