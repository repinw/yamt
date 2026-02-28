import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_item_store.dart';

const _usersCollection = 'users';
const _shoppingListCollection = 'shopping_list_items';

CollectionReference<Map<String, dynamic>> _shoppingListCollectionRef({
  required FirebaseFirestore firestore,
  required String userId,
}) {
  return firestore
      .collection(_usersCollection)
      .doc(userId)
      .collection(_shoppingListCollection);
}

void main() {
  test('chunker returns no chunks for empty operations', () {
    final chunks = FirestoreBatchChunker.chunk<int>(
      operations: const <int>[],
      maxChunkSize: 500,
    ).toList(growable: false);

    expect(chunks, isEmpty);
  });

  test('chunker keeps chunk size below max limit', () {
    final input = List<int>.generate(1201, (index) => index);

    final chunks = FirestoreBatchChunker.chunk<int>(
      operations: input,
      maxChunkSize: 500,
    ).toList(growable: false);

    expect(chunks, hasLength(3));
    expect(chunks[0], hasLength(500));
    expect(chunks[1], hasLength(500));
    expect(chunks[2], hasLength(201));
    expect(chunks.expand((chunk) => chunk), orderedEquals(input));
  });

  test('chunker throws when maxChunkSize is zero', () {
    expect(
      () => FirestoreBatchChunker.chunk<int>(
        operations: const <int>[1, 2, 3],
        maxChunkSize: 0,
      ).toList(growable: false),
      throwsArgumentError,
    );
  });

  test(
    'replaceAll diffs existing documents and removes stale entries',
    () async {
      final firestore = FakeFirebaseFirestore();
      final collection = _shoppingListCollectionRef(
        firestore: firestore,
        userId: 'user-1',
      );
      await collection.doc('a').set(<String, dynamic>{'name': 'Old Milk'});
      await collection.doc('b').set(<String, dynamic>{'name': 'Bread'});

      final store = FirestoreShoppingListItemStore(firestore: firestore);
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
    final collection = _shoppingListCollectionRef(
      firestore: firestore,
      userId: 'user-1',
    );
    await collection.doc('a').set(<String, dynamic>{'name': 'Old Milk'});
    await collection.doc('b').set(<String, dynamic>{'name': 'Bread'});

    final store = FirestoreShoppingListItemStore(
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
    'replaceAll supports more than 500 operations via chunked batches',
    () async {
      final firestore = FakeFirebaseFirestore();
      final collection = _shoppingListCollectionRef(
        firestore: firestore,
        userId: 'user-1',
      );
      final documentsById = <String, Map<String, dynamic>>{
        for (var index = 0; index < 501; index++)
          'item-$index': <String, dynamic>{'index': index},
      };

      final store = FirestoreShoppingListItemStore(firestore: firestore);
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
