import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/plaintext_document_encryption.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';

const _usersCollection = 'users';
const _calorieEntriesCollection = 'calorie_entries';
const _inventoryItemsCollection = 'inventory_items';
const _activityEventsCollection = 'inventory_activity_events';
const _actor = InventoryActivityActor(userId: 'user-1', displayName: 'Alex');

CollectionReference<Map<String, dynamic>> _inventoryCollection({
  required FirebaseFirestore firestore,
  String userId = 'user-1',
}) {
  return firestore
      .collection(_usersCollection)
      .doc(userId)
      .collection(_inventoryItemsCollection);
}

CollectionReference<Map<String, dynamic>> _entryCollection({
  required FirebaseFirestore firestore,
  String userId = 'user-1',
}) {
  return firestore
      .collection(_usersCollection)
      .doc(userId)
      .collection(_calorieEntriesCollection);
}

CollectionReference<Map<String, dynamic>> _activityCollection({
  required FirebaseFirestore firestore,
  String userId = 'user-1',
}) {
  return firestore
      .collection(_usersCollection)
      .doc(userId)
      .collection(_activityEventsCollection);
}

InventoryItem _inventoryItem({int currentAmount = 750}) {
  return InventoryItem.create(
    id: 'inventory-1',
    name: 'Milk',
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
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

late PayloadCipher _cipher;
late SecretKey _householdKey;

HouseholdCipher _household(String ownerUid) {
  return (
    ownerUid: ownerUid,
    key: _householdKey,
    cipher: PayloadCipher(_householdKey),
  );
}

SealedCollection _sealedItems(
  FirebaseFirestore firestore, {
  String userId = 'user-1',
}) {
  return SealedCollection(
    _inventoryCollection(firestore: firestore, userId: userId),
    cipher: PayloadCipher(_householdKey),
    plaintextFields: inventoryItemPlaintextFields,
  );
}

Future<void> _putItem(
  FirebaseFirestore firestore,
  Map<String, dynamic> json, {
  String userId = 'user-1',
}) async {
  final items = _sealedItems(firestore, userId: userId);
  await items.reference
      .doc('inventory-1')
      .set(await items.seal('inventory-1', json));
}

Future<Map<String, dynamic>> _openItem(
  FirebaseFirestore firestore, {
  String userId = 'user-1',
}) async {
  final items = _sealedItems(firestore, userId: userId);
  final snapshot = await items.reference.doc('inventory-1').get();
  return <String, dynamic>{'id': snapshot.id, ...?await items.open(snapshot)};
}

Future<List<Map<String, dynamic>>> _openActivity(
  FirebaseFirestore firestore, {
  String userId = 'user-1',
}) async {
  final events = SealedCollection(
    _activityCollection(firestore: firestore, userId: userId),
    cipher: PayloadCipher(_householdKey),
    plaintextFields: inventoryActivityEventPlaintextFields,
  );
  final opened = await events.openAll(await events.reference.get());
  return opened.map((document) => document.data).toList();
}

UserDataCipher _signedIn(String uid) => (uid: uid, cipher: _cipher);

Future<Map<String, dynamic>> _decrypted(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
) {
  return _cipher.decryptJson(
    snapshot.data()!['payload'] as String,
    aad: snapshot.reference.path,
  );
}

void main() {
  setUpAll(() async {
    _cipher = PayloadCipher(await PayloadCipher.newDataKey());
    _householdKey = await PayloadCipher.newDataKey();
  });
  test(
    'commitEntryAndInventory saves entry and reduces inventory together',
    () async {
      final firestore = FakeFirebaseFirestore();
      await _putItem(firestore, _inventoryItem().toJson());

      final store = FirestoreInventoryCalorieEntryCommitStore(
        firestore: firestore,
        dataCipher: _signedIn('user-1'),
        householdCipher: _household('user-1'),
        actor: _actor,
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
      await pumpEventQueue();

      final savedEntrySnapshot = await _entryCollection(firestore: firestore)
          .doc('entry-1')
          .get();
      expect(savedEntrySnapshot.exists, isTrue);
      expect(
        savedEntrySnapshot.data()!.keys,
        unorderedEquals(<String>['payload', 'logged_at']),
      );
      expect(
        (await _decrypted(savedEntrySnapshot))['source_inventory_item_id'],
        'inventory-1',
      );

      final rawItem = await _inventoryCollection(firestore: firestore)
          .doc('inventory-1')
          .get();
      expect(
        rawItem.data()!.keys,
        unorderedEquals(<String>[
          encryptedPayloadField,
          ...inventoryItemPlaintextFields,
        ]),
      );
      final savedItem = InventoryItem.fromJson(await _openItem(firestore));
      expect(savedItem.name, 'Milk');
      expect(savedItem.currentAmount, 500);
      expect(savedItem.quantity, 1);
      expect(savedItem.lastConsumedAt, _entry().loggedAt);

      final activitySnapshot = await _activityCollection(firestore: firestore)
          .get();
      expect(
        activitySnapshot.docs.single.data().keys,
        unorderedEquals(<String>[encryptedPayloadField, 'happened_at']),
      );
      final activityEvent = InventoryActivityEvent.fromJson(
        (await _openActivity(firestore)).single,
      );
      expect(activityEvent.type, InventoryActivityEventType.itemConsumed);
      expect(activityEvent.actorUserId, 'user-1');
      expect(activityEvent.actorDisplayName, 'Alex');
      expect(activityEvent.itemId, 'inventory-1');
      expect(activityEvent.amount, 250);
      expect(activityEvent.beforeCurrentAmount, 750);
      expect(activityEvent.afterCurrentAmount, 500);
    },
  );

  test(
    'commitEntryAndInventory fails when pending amount exceeds stock',
    () async {
      final firestore = FakeFirebaseFirestore();
      await _putItem(firestore, _inventoryItem(currentAmount: 100).toJson());

      final store = FirestoreInventoryCalorieEntryCommitStore(
        firestore: firestore,
        dataCipher: _signedIn('user-1'),
        householdCipher: _household('user-1'),
        actor: _actor,
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

      final savedEntrySnapshot = await _entryCollection(firestore: firestore)
          .doc('entry-1')
          .get();
      expect(savedEntrySnapshot.exists, isFalse);

      final savedItem = InventoryItem.fromJson(await _openItem(firestore));
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
      await _putItem(firestore, itemJson);

      final store = FirestoreInventoryCalorieEntryCommitStore(
        firestore: firestore,
        dataCipher: _signedIn('user-1'),
        householdCipher: _household('user-1'),
        actor: _actor,
      );

      await store.commitEntryAndInventory(
        entry: _entry(),
        pendingConsumption: const PendingInventoryConsumption(
          id: 'pending-1',
          itemId: 'inventory-1',
          amount: 250,
        ),
      );
      await pumpEventQueue();

      final savedItem = await _openItem(firestore);
      expect(savedItem['custom_server_flag'], isTrue);
      expect(savedItem['notes'], 'keep me');
      expect(savedItem['current_amount'], 500);
    },
  );

  test('commitEntryAndInventory uses shared inventory owner '
      'and personal entry user', () async {
    final firestore = FakeFirebaseFirestore();
    await _putItem(firestore, _inventoryItem().toJson(), userId: 'host-1');

    final store = FirestoreInventoryCalorieEntryCommitStore(
      firestore: firestore,
      dataCipher: _signedIn('member-1'),
      householdCipher: _household('host-1'),
      actor: const InventoryActivityActor(
        userId: 'member-1',
        displayName: 'Jamie',
      ),
    );
    final entry = _entry().copyWith(userId: 'member-1');

    final result = await store.commitEntryAndInventory(
      entry: entry,
      pendingConsumption: const PendingInventoryConsumption(
        id: 'pending-1',
        itemId: 'inventory-1',
        amount: 250,
      ),
    );

    expect(result, isNotNull);
    await pumpEventQueue();

    final savedEntry = await _entryCollection(
      firestore: firestore,
      userId: 'member-1',
    ).doc('entry-1').get();
    final savedItem = await _openItem(firestore, userId: 'host-1');

    expect(savedEntry.exists, isTrue);
    expect((await _decrypted(savedEntry))['user_id'], 'member-1');
    expect(savedItem['current_amount'], 500);
    final activity = await _openActivity(firestore, userId: 'host-1');
    expect(activity.single['actor_user_id'], 'member-1');
  });
}
