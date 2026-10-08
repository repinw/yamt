import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/encrypted_payload.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_store.dart';

const _householdsCollection = 'households';
const _inventoryItemsCollection = 'inventory_items';

CollectionReference<Map<String, dynamic>> _inventoryCollection({
  required FirebaseFirestore firestore,
  required String householdId,
}) {
  return firestore
      .collection(_householdsCollection)
      .doc(householdId)
      .collection(_inventoryItemsCollection);
}

void main() {
  late PayloadCipher cipher;

  setUp(() async {
    cipher = PayloadCipher(await PayloadCipher.newDataKey());
  });

  SealedCollection sealed(CollectionReference<Map<String, dynamic>> reference) {
    return SealedCollection(
      reference,
      cipher: cipher,
      plaintextFields: inventoryItemPlaintextFields,
    );
  }

  Future<void> put(
    CollectionReference<Map<String, dynamic>> reference,
    String id,
    Map<String, dynamic> data,
  ) async {
    await reference.doc(id).set(await sealed(reference).seal(id, data));
  }

  test('readAll maps documents to InventoryItemDocument', () async {
    final firestore = FakeFirebaseFirestore();
    final collection = _inventoryCollection(
      firestore: firestore,
      householdId: 'household-1',
    );
    await put(collection, 'a', <String, dynamic>{'name': 'Milk'});
    await put(collection, 'b', <String, dynamic>{'name': 'Bread'});

    final store = FirestoreInventoryItemStore(
      firestore: firestore,
      cipher: cipher,
    );
    final documents = await store.readAll(householdId: 'household-1');
    final mappedById = <String, Map<String, dynamic>>{
      for (final document in documents) document.id: document.data,
    };

    expect(documents, hasLength(2));
    expect(mappedById['a'], <String, dynamic>{'name': 'Milk'});
    expect(mappedById['b'], <String, dynamic>{'name': 'Bread'});
  });

  test('watchAll maps streamed snapshots to inventory documents', () async {
    final firestore = FakeFirebaseFirestore();
    final collection = _inventoryCollection(
      firestore: firestore,
      householdId: 'household-1',
    );
    final store = FirestoreInventoryItemStore(
      firestore: firestore,
      cipher: cipher,
    );

    final nextEmission = store
        .watchAll(householdId: 'household-1')
        .skip(1)
        .first;
    await put(collection, 'a', <String, dynamic>{'name': 'Milk'});
    final documents = await nextEmission;

    expect(documents, hasLength(1));
    expect(documents.single.id, 'a');
    expect(documents.single.data, <String, dynamic>{'name': 'Milk'});
  });

  test('save writes one item and leaves the other items alone', () async {
    final firestore = FakeFirebaseFirestore();
    final collection = _inventoryCollection(
      firestore: firestore,
      householdId: 'household-1',
    );
    await put(collection, 'a', <String, dynamic>{'name': 'Milk'});
    await put(collection, 'b', <String, dynamic>{'name': 'Bread'});
    final store = FirestoreInventoryItemStore(
      firestore: firestore,
      cipher: cipher,
    );

    final saved = await store.save(
      householdId: 'household-1',
      id: 'b',
      data: <String, dynamic>{'name': 'Bread v2'},
    );
    await pumpEventQueue();

    final dataById = <String, Map<String, dynamic>>{
      for (final doc in await sealed(
        collection,
      ).openAll(await collection.get()))
        doc.id: doc.data,
    };
    expect(saved, isTrue);
    expect(dataById['a'], <String, dynamic>{'name': 'Milk'});
    expect(dataById['b'], <String, dynamic>{'name': 'Bread v2'});
  });

  test('delete removes one item and leaves the other items alone', () async {
    final firestore = FakeFirebaseFirestore();
    final collection = _inventoryCollection(
      firestore: firestore,
      householdId: 'household-1',
    );
    await put(collection, 'a', <String, dynamic>{'name': 'Milk'});
    await collection.doc('plain').set(<String, dynamic>{'name': 'Bread'});
    final store = FirestoreInventoryItemStore(
      firestore: firestore,
      cipher: cipher,
    );

    final deleted = await store.delete(householdId: 'household-1', id: 'a');
    await pumpEventQueue();

    expect(deleted, isTrue);
    expect((await collection.doc('a').get()).exists, isFalse);
    expect((await collection.doc('plain').get()).exists, isTrue);
  });

  test('stores only the payload and the query fields', () async {
    final firestore = FakeFirebaseFirestore();
    final store = FirestoreInventoryItemStore(
      firestore: firestore,
      cipher: cipher,
    );
    await store.save(
      householdId: 'household-1',
      id: 'a',
      data: <String, dynamic>{
        'name': 'Milk',
        'origin': 'manualAdd',
        'is_deposit': false,
        'is_discount': false,
        'entry_date': '2026-09-24T10:00:00.000',
      },
    );
    await pumpEventQueue();

    final raw = await _inventoryCollection(
      firestore: firestore,
      householdId: 'household-1',
    ).doc('a').get();
    expect(
      raw.data()!.keys,
      unorderedEquals(<String>[
        encryptedPayloadField,
        'origin',
        'is_deposit',
        'is_discount',
        'entry_date',
      ]),
    );
    final recent = await store.readRecentManual(
      householdId: 'household-1',
      limit: 5,
    );
    expect(recent.single.data['name'], 'Milk');
  });
}
