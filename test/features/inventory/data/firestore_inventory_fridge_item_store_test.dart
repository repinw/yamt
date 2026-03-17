import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
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

Future<void> _seedStaleDocuments({
  required CollectionReference<Map<String, dynamic>> collection,
  required int count,
}) async {
  for (var index = 0; index < count; index++) {
    await collection.doc('stale-$index').set(<String, dynamic>{
      'name': 'Item $index',
    });
  }
}

void main() {
  test('readAll maps documents to InventoryItemDocument', () async {
    final firestore = FakeFirebaseFirestore();
    final collection = _inventoryCollection(
      firestore: firestore,
      userId: 'user-1',
    );
    await collection.doc('a').set(<String, dynamic>{'name': 'Milk'});
    await collection.doc('b').set(<String, dynamic>{'name': 'Bread'});

    final store = FirestoreInventoryItemStore(firestore: firestore);
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
    final store = FirestoreInventoryItemStore(firestore: firestore);

    final nextEmission = store.watchAll(userId: 'user-1').skip(1).first;
    await collection.doc('a').set(<String, dynamic>{'name': 'Milk'});
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
      await collection.doc('a').set(<String, dynamic>{'name': 'Old Milk'});
      await collection.doc('b').set(<String, dynamic>{'name': 'Bread'});

      final store = FirestoreInventoryItemStore(firestore: firestore);
      final replaced = await store.replaceAll(
        userId: 'user-1',
        documentsById: <String, Map<String, dynamic>>{
          'b': <String, dynamic>{'name': 'Bread v2'},
          'c': <String, dynamic>{'name': 'Cheese'},
        },
      );

      final snapshot = await collection.get();
      final dataById = <String, Map<String, dynamic>>{
        for (final doc in snapshot.docs) doc.id: doc.data(),
      };

      expect(replaced, isTrue);
      expect(snapshot.docs, hasLength(2));
      expect(dataById.containsKey('a'), isFalse);
      expect(dataById['b'], <String, dynamic>{'name': 'Bread v2'});
      expect(dataById['c'], <String, dynamic>{'name': 'Cheese'});
    },
  );

  test('replaceAll keeps stale document changed during delete phase', () async {
    final firestore = FakeFirebaseFirestore();
    final collection = _inventoryCollection(
      firestore: firestore,
      userId: 'user-1',
    );
    await collection.doc('a').set(<String, dynamic>{'name': 'Old Milk'});
    await collection.doc('b').set(<String, dynamic>{'name': 'Bread'});

    final store = FirestoreInventoryItemStore.testing(
      firestore: firestore,
      onBeforeDeleteStaleDocuments: () async {
        await collection.doc('a').set(<String, dynamic>{
          'name': 'Changed elsewhere',
        });
      },
    );

    final replaced = await store.replaceAll(
      userId: 'user-1',
      documentsById: <String, Map<String, dynamic>>{
        'b': <String, dynamic>{'name': 'Bread v2'},
      },
    );

    final snapshot = await collection.get();
    final dataById = <String, Map<String, dynamic>>{
      for (final doc in snapshot.docs) doc.id: doc.data(),
    };

    expect(replaced, isTrue);
    expect(snapshot.docs, hasLength(2));
    expect(dataById['a'], <String, dynamic>{'name': 'Changed elsewhere'});
    expect(dataById['b'], <String, dynamic>{'name': 'Bread v2'});
  });

  test(
    'replaceAll tolerates stale document deleted during delete phase',
    () async {
      final firestore = FakeFirebaseFirestore();
      final collection = _inventoryCollection(
        firestore: firestore,
        userId: 'user-1',
      );
      await collection.doc('a').set(<String, dynamic>{'name': 'Old Milk'});
      await collection.doc('b').set(<String, dynamic>{'name': 'Bread'});

      final store = FirestoreInventoryItemStore.testing(
        firestore: firestore,
        onBeforeDeleteStaleDocuments: () async {
          await collection.doc('a').delete();
        },
      );

      final replaced = await store.replaceAll(
        userId: 'user-1',
        documentsById: <String, Map<String, dynamic>>{
          'b': <String, dynamic>{'name': 'Bread v2'},
        },
      );

      final snapshot = await collection.get();
      final dataById = <String, Map<String, dynamic>>{
        for (final doc in snapshot.docs) doc.id: doc.data(),
      };

      expect(replaced, isTrue);
      expect(snapshot.docs, hasLength(1));
      expect(dataById.containsKey('a'), isFalse);
      expect(dataById['b'], <String, dynamic>{'name': 'Bread v2'});
    },
  );

  test(
    'fallback path keeps stale document changed during delete phase',
    () async {
      final firestore = FakeFirebaseFirestore();
      final collection = _inventoryCollection(
        firestore: firestore,
        userId: 'user-1',
      );
      await _seedStaleDocuments(collection: collection, count: 501);

      final store = FirestoreInventoryItemStore.testing(
        firestore: firestore,
        onBeforeDeleteStaleDocuments: () async {
          await collection.doc('stale-250').set(<String, dynamic>{
            'name': 'Changed elsewhere',
          });
        },
      );

      final replaced = await store.replaceAll(
        userId: 'user-1',
        documentsById: <String, Map<String, dynamic>>{
          'keep': <String, dynamic>{'name': 'Keep'},
        },
      );

      final snapshot = await collection.get();
      final dataById = <String, Map<String, dynamic>>{
        for (final doc in snapshot.docs) doc.id: doc.data(),
      };

      expect(replaced, isTrue);
      expect(snapshot.docs, hasLength(2));
      expect(dataById['stale-250'], <String, dynamic>{
        'name': 'Changed elsewhere',
      });
      expect(dataById['keep'], <String, dynamic>{'name': 'Keep'});
    },
  );

  test(
    'fallback path tolerates stale document deleted during delete phase',
    () async {
      final firestore = FakeFirebaseFirestore();
      final collection = _inventoryCollection(
        firestore: firestore,
        userId: 'user-1',
      );
      await _seedStaleDocuments(collection: collection, count: 501);

      final store = FirestoreInventoryItemStore.testing(
        firestore: firestore,
        onBeforeDeleteStaleDocuments: () async {
          await collection.doc('stale-250').delete();
        },
      );

      final replaced = await store.replaceAll(
        userId: 'user-1',
        documentsById: <String, Map<String, dynamic>>{
          'keep': <String, dynamic>{'name': 'Keep'},
        },
      );

      final snapshot = await collection.get();
      final dataById = <String, Map<String, dynamic>>{
        for (final doc in snapshot.docs) doc.id: doc.data(),
      };

      expect(replaced, isTrue);
      expect(snapshot.docs, hasLength(1));
      expect(dataById.containsKey('stale-250'), isFalse);
      expect(dataById['keep'], <String, dynamic>{'name': 'Keep'});
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

      final store = FirestoreInventoryItemStore(firestore: firestore);
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
}
