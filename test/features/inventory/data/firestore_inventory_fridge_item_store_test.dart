import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/plaintext_document_encryption.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_store.dart';

const _usersCollection = 'users';
const _inventoryItemsCollection = 'inventory_items';

CollectionReference<Map<String, dynamic>> _inventoryCollection({
  required FirebaseFirestore firestore,
  required String userId,
}) {
  return firestore
      .collection(_usersCollection)
      .doc(userId)
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
      userId: 'user-1',
    );
    await put(collection, 'a', <String, dynamic>{'name': 'Milk'});
    await put(collection, 'b', <String, dynamic>{'name': 'Bread'});

    final store = FirestoreInventoryItemStore(
      firestore: firestore,
      cipher: cipher,
    );
    final documents = await store.readAll(userId: 'user-1');
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
      userId: 'user-1',
    );
    final store = FirestoreInventoryItemStore(
      firestore: firestore,
      cipher: cipher,
    );

    final nextEmission = store.watchAll(userId: 'user-1').skip(1).first;
    await put(collection, 'a', <String, dynamic>{'name': 'Milk'});
    final documents = await nextEmission;

    expect(documents, hasLength(1));
    expect(documents.single.id, 'a');
    expect(documents.single.data, <String, dynamic>{'name': 'Milk'});
  });

  test(
    'replaceAll diffs existing documents and removes stale entries',
    () async {
      final firestore = FakeFirebaseFirestore();
      final collection = _inventoryCollection(
        firestore: firestore,
        userId: 'user-1',
      );
      await put(collection, 'a', <String, dynamic>{'name': 'Old Milk'});
      await put(collection, 'b', <String, dynamic>{'name': 'Bread'});

      final store = FirestoreInventoryItemStore(
        firestore: firestore,
        cipher: cipher,
      );
      final replaced = await store.replaceAll(
        userId: 'user-1',
        documentsById: <String, Map<String, dynamic>>{
          'b': <String, dynamic>{'name': 'Bread v2'},
          'c': <String, dynamic>{'name': 'Cheese'},
        },
      );

      final snapshot = await collection.get();
      final dataById = <String, Map<String, dynamic>>{
        for (final doc in await sealed(collection).openAll(snapshot))
          doc.id: doc.data,
      };

      expect(replaced, isTrue);
      expect(snapshot.docs, hasLength(2));
      expect(dataById.containsKey('a'), isFalse);
      expect(dataById['b'], <String, dynamic>{'name': 'Bread v2'});
      expect(dataById['c'], <String, dynamic>{'name': 'Cheese'});
    },
  );

  test(
    'replaceAll supports more than 500 operations via chunked batches',
    () async {
      final firestore = FakeFirebaseFirestore();
      final collection = _inventoryCollection(
        firestore: firestore,
        userId: 'user-1',
      );

      final documentsById = <String, Map<String, dynamic>>{
        for (var index = 0; index < 501; index++)
          'item-$index': <String, dynamic>{'index': index},
      };

      final store = FirestoreInventoryItemStore(
        firestore: firestore,
        cipher: cipher,
      );
      final replaced = await store.replaceAll(
        userId: 'user-1',
        documentsById: documentsById,
      );

      final snapshot = await collection.get();

      expect(replaced, isTrue);
      expect(snapshot.docs, hasLength(501));
      expect(snapshot.docs.any((doc) => doc.id == 'item-0'), isTrue);
      expect(snapshot.docs.any((doc) => doc.id == 'item-500'), isTrue);
    },
  );

  test('stores only the payload and the query fields', () async {
    final firestore = FakeFirebaseFirestore();
    final store = FirestoreInventoryItemStore(
      firestore: firestore,
      cipher: cipher,
    );
    await store.replaceAll(
      userId: 'user-1',
      documentsById: <String, Map<String, dynamic>>{
        'a': <String, dynamic>{
          'name': 'Milk',
          'origin': 'manualAdd',
          'is_deposit': false,
          'is_discount': false,
          'entry_date': '2026-09-24T10:00:00.000',
        },
      },
    );

    final raw = await _inventoryCollection(
      firestore: firestore,
      userId: 'user-1',
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
    final recent = await store.readRecentManual(userId: 'user-1', limit: 5);
    expect(recent.single.data['name'], 'Milk');
  });

  test('replaceAll keeps a plaintext document and reports failure', () async {
    final firestore = FakeFirebaseFirestore();
    final collection = _inventoryCollection(
      firestore: firestore,
      userId: 'user-1',
    );
    await collection.doc('plain').set(<String, dynamic>{'name': 'Milk'});
    final store = FirestoreInventoryItemStore(
      firestore: firestore,
      cipher: cipher,
    );

    final replaced = await store.replaceAll(
      userId: 'user-1',
      documentsById: <String, Map<String, dynamic>>{
        'b': <String, dynamic>{'name': 'Bread'},
      },
    );

    expect(replaced, isFalse);
    expect((await collection.doc('plain').get()).exists, isTrue);
  });
}
