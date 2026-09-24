import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_item_store.dart';

const _usersCollection = 'users';
const _shoppingListCollection = 'shopping_list_items';

class _HookedFakeFirebaseFirestore extends FakeFirebaseFirestore {
  new({required this.onBeforeRunTransaction});

  final Future<void> Function() onBeforeRunTransaction;

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    await onBeforeRunTransaction();
    return await super.runTransaction(
      transactionHandler,
      timeout: timeout,
      maxAttempts: maxAttempts,
    );
  }
}

class _ThrowingTransactionFakeFirebaseFirestore extends FakeFirebaseFirestore {
  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) {
    return Future<T>.error(
      FirebaseException(
        plugin: 'cloud_firestore',
        code: 'aborted',
        message: 'transaction failed',
      ),
    );
  }
}

CollectionReference<Map<String, dynamic>> _shoppingListCollectionRef({
  required FirebaseFirestore firestore,
  required String userId,
}) {
  return firestore
      .collection(_usersCollection)
      .doc(userId)
      .collection(_shoppingListCollection);
}

late PayloadCipher _cipher;

Future<void> _put(
  CollectionReference<Map<String, dynamic>> collection,
  String id,
  Map<String, dynamic> data,
) async {
  final sealed = SealedCollection(collection, cipher: _cipher);
  await collection.doc(id).set(await sealed.seal(id, data));
}

Future<Map<String, Map<String, dynamic>>> _openAll(
  CollectionReference<Map<String, dynamic>> collection,
) async {
  final sealed = SealedCollection(collection, cipher: _cipher);
  return <String, Map<String, dynamic>>{
    for (final document in await sealed.openAll(await collection.get()))
      document.id: document.data,
  };
}

Future<void> _seedStaleDocuments({
  required CollectionReference<Map<String, dynamic>> collection,
  required int count,
}) async {
  for (var index = 0; index < count; index++) {
    await _put(collection, 'stale-$index', <String, dynamic>{
      'name': 'Item $index',
    });
  }
}

void main() {
  setUp(() async {
    _cipher = PayloadCipher(await PayloadCipher.newDataKey());
  });

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
      await _put(collection, 'a', <String, dynamic>{'name': 'Old Milk'});
      await _put(collection, 'b', <String, dynamic>{'name': 'Bread'});

      final store = FirestoreShoppingListItemStore(
        firestore: firestore,
        cipher: _cipher,
      );
      final replaced = await store.replaceAll(
        userId: 'user-1',
        documentsById: <String, Map<String, dynamic>>{
          'b': <String, dynamic>{'name': 'Bread v2'},
          'c': <String, dynamic>{'name': 'Cheese'},
        },
      );

      final snapshot = await collection.get();
      final dataById = await _openAll(collection);

      expect(replaced, isTrue);
      expect(snapshot.docs, hasLength(2));
      expect(dataById.containsKey('a'), isFalse);
      expect(dataById['b'], <String, dynamic>{'name': 'Bread v2'});
      expect(dataById['c'], <String, dynamic>{'name': 'Cheese'});
    },
  );

  test('replaceAll keeps stale document changed during delete phase', () async {
    late final CollectionReference<Map<String, dynamic>> collection;
    final firestore = _HookedFakeFirebaseFirestore(
      onBeforeRunTransaction: () async {
        await _put(collection, 'a', <String, dynamic>{
          'name': 'Changed elsewhere',
        });
      },
    );
    collection = _shoppingListCollectionRef(
      firestore: firestore,
      userId: 'user-1',
    );
    await _put(collection, 'a', <String, dynamic>{'name': 'Old Milk'});
    await _put(collection, 'b', <String, dynamic>{'name': 'Bread'});

    final store = FirestoreShoppingListItemStore(
      firestore: firestore,
      cipher: _cipher,
    );

    final replaced = await store.replaceAll(
      userId: 'user-1',
      documentsById: <String, Map<String, dynamic>>{
        'b': <String, dynamic>{'name': 'Bread v2'},
      },
    );

    final snapshot = await collection.get();
    final dataById = await _openAll(collection);

    expect(replaced, isTrue);
    expect(snapshot.docs, hasLength(2));
    expect(dataById['a'], <String, dynamic>{'name': 'Changed elsewhere'});
    expect(dataById['b'], <String, dynamic>{'name': 'Bread v2'});
  });

  test(
    'replaceAll tolerates stale document deleted during delete phase',
    () async {
      late final CollectionReference<Map<String, dynamic>> collection;
      final firestore = _HookedFakeFirebaseFirestore(
        onBeforeRunTransaction: () async {
          await collection.doc('a').delete();
        },
      );
      collection = _shoppingListCollectionRef(
        firestore: firestore,
        userId: 'user-1',
      );
      await _put(collection, 'a', <String, dynamic>{'name': 'Old Milk'});
      await _put(collection, 'b', <String, dynamic>{'name': 'Bread'});

      final store = FirestoreShoppingListItemStore(
        firestore: firestore,
        cipher: _cipher,
      );
      final replaced = await store.replaceAll(
        userId: 'user-1',
        documentsById: <String, Map<String, dynamic>>{
          'b': <String, dynamic>{'name': 'Bread v2'},
        },
      );

      final snapshot = await collection.get();
      final dataById = await _openAll(collection);

      expect(replaced, isTrue);
      expect(snapshot.docs, hasLength(1));
      expect(dataById.containsKey('a'), isFalse);
      expect(dataById['b'], <String, dynamic>{'name': 'Bread v2'});
    },
  );

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

      final store = FirestoreShoppingListItemStore(
        firestore: firestore,
        cipher: _cipher,
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

  test(
    'replaceAll chunks stale deletes into 100, 100, and 50 transactions',
    () async {
      late final CollectionReference<Map<String, dynamic>> collection;
      final staleCountsBeforeTransaction = <int>[];
      final firestore = _HookedFakeFirebaseFirestore(
        onBeforeRunTransaction: () async {
          final snapshot = await collection.get();
          final staleCount = snapshot.docs
              .where((doc) => doc.id.startsWith('stale-'))
              .length;
          staleCountsBeforeTransaction.add(staleCount);
        },
      );
      collection = _shoppingListCollectionRef(
        firestore: firestore,
        userId: 'user-1',
      );
      await _seedStaleDocuments(collection: collection, count: 250);

      final documentsById = <String, Map<String, dynamic>>{
        for (var index = 0; index < 251; index++)
          'keep-$index': <String, dynamic>{'name': 'Keep $index'},
      };

      final store = FirestoreShoppingListItemStore(
        firestore: firestore,
        cipher: _cipher,
      );
      final replaced = await store.replaceAll(
        userId: 'user-1',
        documentsById: documentsById,
      );

      final snapshot = await collection.get();
      final staleCountAfter = snapshot.docs
          .where((doc) => doc.id.startsWith('stale-'))
          .length;

      expect(replaced, isTrue);
      expect(staleCountsBeforeTransaction, orderedEquals(<int>[250, 150, 50]));
      expect(staleCountAfter, 0);
      expect(snapshot.docs, hasLength(251));
    },
  );

  test(
    'replaceAll returns false when stale delete transaction fails',
    () async {
      final firestore = _ThrowingTransactionFakeFirebaseFirestore();
      final collection = _shoppingListCollectionRef(
        firestore: firestore,
        userId: 'user-1',
      );
      await _seedStaleDocuments(collection: collection, count: 501);

      final store = FirestoreShoppingListItemStore(
        firestore: firestore,
        cipher: _cipher,
      );
      final replaced = await store.replaceAll(
        userId: 'user-1',
        documentsById: <String, Map<String, dynamic>>{
          'keep': <String, dynamic>{'name': 'Keep'},
        },
      );

      final snapshot = await collection.get();
      final staleCount = snapshot.docs
          .where((doc) => doc.id.startsWith('stale-'))
          .length;
      final keepData = (await _openAll(collection))['keep'];

      expect(replaced, isFalse);
      expect(staleCount, 501);
      expect(keepData, <String, dynamic>{'name': 'Keep'});
    },
  );
}
