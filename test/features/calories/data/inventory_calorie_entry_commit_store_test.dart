import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';

const _usersCollection = 'users';
const _calorieEntriesCollection = 'calorie_entries';
const _inventoryItemsCollection = 'inventory_items';

CollectionReference<Map<String, dynamic>> _inventoryCollection({
  required FirebaseFirestore firestore,
}) {
  return firestore
      .collection(_usersCollection)
      .doc('user-1')
      .collection(_inventoryItemsCollection);
}

CollectionReference<Map<String, dynamic>> _entryCollection({
  required FirebaseFirestore firestore,
}) {
  return firestore
      .collection(_usersCollection)
      .doc('user-1')
      .collection(_calorieEntriesCollection);
}

InventoryItem _inventoryItem({int currentAmount = 750}) {
  return InventoryItem.create(
    id: 'inventory-1',
    name: 'Milk',
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    initialAmount: 1000,
    currentAmount: currentAmount,
    amountUnit: InventoryAmountUnit.milliliter,
  );
}

CalorieEntry _entry() {
  return CalorieEntry.create(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Milk',
    mealType: MealType.breakfast,
    consumedAmount: 250,
    consumedUnit: ConsumedUnit.milliliters,
    per100Kcal: 60,
    per100Protein: 3.2,
    per100Carbs: 4.8,
    per100Fat: 1.5,
    sourceInventoryItemId: 'inventory-1',
    sourceInventoryAmountToRestore: 250,
    loggedAt: DateTime(2026, 3, 27, 8),
    createdAt: DateTime(2026, 3, 27, 8),
    updatedAt: DateTime(2026, 3, 27, 8),
  );
}

Map<String, dynamic> _withDocumentId(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
) {
  return <String, dynamic>{'id': snapshot.id, ...?snapshot.data()};
}

void main() {
  test(
    'commitEntryAndInventory saves entry and reduces inventory together',
    () async {
      final firestore = FakeFirebaseFirestore();
      await _inventoryCollection(
        firestore: firestore,
      ).doc('inventory-1').set(_inventoryItem().toJson());

      final store = FirestoreInventoryCalorieEntryCommitStore(
        firestore: firestore,
        currentUserId: 'user-1',
      );

      final result = await store.commitEntryAndInventory(
        entry: _entry(),
        pendingConsumption: const PendingInventoryConsumption(
          id: 'pending-1',
          itemId: 'inventory-1',
          amount: 250,
        ),
      );

      expect(result, isNotNull);
      expect(result?.itemId, 'inventory-1');
      expect(result?.quantity, 1);
      expect(result?.currentAmount, 500);

      final savedEntrySnapshot = await _entryCollection(
        firestore: firestore,
      ).doc('entry-1').get();
      expect(savedEntrySnapshot.exists, isTrue);
      expect(
        savedEntrySnapshot.data()?['source_inventory_item_id'],
        'inventory-1',
      );

      final savedItemSnapshot = await _inventoryCollection(
        firestore: firestore,
      ).doc('inventory-1').get();
      final savedItem = InventoryItem.fromJson(
        _withDocumentId(savedItemSnapshot),
      );
      expect(savedItem.currentAmount, 500);
      expect(savedItem.quantity, 1);
    },
  );

  test(
    'commitEntryAndInventory fails when pending amount exceeds stock',
    () async {
      final firestore = FakeFirebaseFirestore();
      await _inventoryCollection(
        firestore: firestore,
      ).doc('inventory-1').set(_inventoryItem(currentAmount: 100).toJson());

      final store = FirestoreInventoryCalorieEntryCommitStore(
        firestore: firestore,
        currentUserId: 'user-1',
      );

      final result = await store.commitEntryAndInventory(
        entry: _entry(),
        pendingConsumption: const PendingInventoryConsumption(
          id: 'pending-1',
          itemId: 'inventory-1',
          amount: 250,
        ),
      );

      expect(result, isNull);

      final savedEntrySnapshot = await _entryCollection(
        firestore: firestore,
      ).doc('entry-1').get();
      expect(savedEntrySnapshot.exists, isFalse);

      final savedItemSnapshot = await _inventoryCollection(
        firestore: firestore,
      ).doc('inventory-1').get();
      final savedItem = InventoryItem.fromJson(
        _withDocumentId(savedItemSnapshot),
      );
      expect(savedItem.currentAmount, 100);
    },
  );

  test(
    'commitEntryAndInventory preserves unknown inventory document fields',
    () async {
      final firestore = FakeFirebaseFirestore();
      final itemJson = _inventoryItem().toJson()
        ..['custom_server_flag'] = true
        ..['notes'] = 'keep me';
      await _inventoryCollection(
        firestore: firestore,
      ).doc('inventory-1').set(itemJson);

      final store = FirestoreInventoryCalorieEntryCommitStore(
        firestore: firestore,
        currentUserId: 'user-1',
      );

      await store.commitEntryAndInventory(
        entry: _entry(),
        pendingConsumption: const PendingInventoryConsumption(
          id: 'pending-1',
          itemId: 'inventory-1',
          amount: 250,
        ),
      );

      final savedItemSnapshot = await _inventoryCollection(
        firestore: firestore,
      ).doc('inventory-1').get();
      expect(savedItemSnapshot.data()?['custom_server_flag'], isTrue);
      expect(savedItemSnapshot.data()?['notes'], 'keep me');
      expect(savedItemSnapshot.data()?['current_amount'], 500);
    },
  );
}
