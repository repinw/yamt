import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/firestore_atomic_replace_service.dart';

const _usersCollection = 'users';
const _itemsCollection = 'items';

class _HookedFakeFirebaseFirestore extends FakeFirebaseFirestore {
  _HookedFakeFirebaseFirestore({this.onBeforeRunTransaction});

  final Future<void> Function()? onBeforeRunTransaction;
  int runTransactionCalls = 0;

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    runTransactionCalls += 1;
    await onBeforeRunTransaction?.call();
    return super.runTransaction(
      transactionHandler,
      timeout: timeout,
      maxAttempts: maxAttempts,
    );
  }
}

CollectionReference<Map<String, dynamic>> _itemsCollectionRef({
  required FirebaseFirestore firestore,
  required String userId,
}) {
  return firestore
      .collection(_usersCollection)
      .doc(userId)
      .collection(_itemsCollection);
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
  test('replaceAll stays atomic exactly at transaction write limit', () async {
    final firestore = _HookedFakeFirebaseFirestore();
    final collection = _itemsCollectionRef(
      firestore: firestore,
      userId: 'user-atomic-limit',
    );
    await collection.doc('stale').set(<String, dynamic>{'name': 'Old'});

    var sawUpsertBeforeDeleteCallback = false;
    final service = FirestoreAtomicReplaceService(
      firestore: firestore,
      maxFirestoreTransactionWrites: 2,
    );
    await service.replaceAll(
      collection: collection,
      documentsById: <String, Map<String, dynamic>>{
        'keep': <String, dynamic>{'name': 'Fresh'},
      },
      onBeforeDeleteStaleDocuments: () async {
        sawUpsertBeforeDeleteCallback =
            (await collection.doc('keep').get()).exists;
      },
    );

    expect(sawUpsertBeforeDeleteCallback, isFalse);
    expect(firestore.runTransactionCalls, 1);
  });

  test(
    'replaceAll falls back when transaction write limit is exceeded',
    () async {
      final firestore = _HookedFakeFirebaseFirestore();
      final collection = _itemsCollectionRef(
        firestore: firestore,
        userId: 'user-fallback-limit',
      );
      await collection.doc('stale').set(<String, dynamic>{'name': 'Old'});

      var sawUpsertBeforeDeleteCallback = false;
      final service = FirestoreAtomicReplaceService(
        firestore: firestore,
        maxFirestoreTransactionWrites: 1,
      );
      await service.replaceAll(
        collection: collection,
        documentsById: <String, Map<String, dynamic>>{
          'keep': <String, dynamic>{'name': 'Fresh'},
        },
        onBeforeDeleteStaleDocuments: () async {
          sawUpsertBeforeDeleteCallback =
              (await collection.doc('keep').get()).exists;
        },
      );

      expect(sawUpsertBeforeDeleteCallback, isTrue);
      expect(firestore.runTransactionCalls, 1);
    },
  );

  test('replaceAll uses atomic transaction under write limit', () async {
    final firestore = _HookedFakeFirebaseFirestore();
    final collection = _itemsCollectionRef(
      firestore: firestore,
      userId: 'user-1',
    );
    await collection.doc('a').set(<String, dynamic>{'name': 'Old Milk'});
    await collection.doc('b').set(<String, dynamic>{'name': 'Bread'});

    final service = FirestoreAtomicReplaceService(firestore: firestore);
    await service.replaceAll(
      collection: collection,
      documentsById: <String, Map<String, dynamic>>{
        'b': <String, dynamic>{'name': 'Bread v2'},
        'c': <String, dynamic>{'name': 'Cheese'},
      },
    );

    final snapshot = await collection.get();
    final dataById = <String, Map<String, dynamic>>{
      for (final doc in snapshot.docs) doc.id: doc.data(),
    };

    expect(firestore.runTransactionCalls, 1);
    expect(snapshot.docs, hasLength(2));
    expect(dataById.containsKey('a'), isFalse);
    expect(dataById['b'], <String, dynamic>{'name': 'Bread v2'});
    expect(dataById['c'], <String, dynamic>{'name': 'Cheese'});
  });

  test('replaceAll falls back and chunks stale deletes', () async {
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
    collection = _itemsCollectionRef(firestore: firestore, userId: 'user-1');
    await _seedStaleDocuments(collection: collection, count: 250);

    final documentsById = <String, Map<String, dynamic>>{
      for (var index = 0; index < 251; index++)
        'keep-$index': <String, dynamic>{'name': 'Keep $index'},
    };

    final service = FirestoreAtomicReplaceService(firestore: firestore);
    await service.replaceAll(
      collection: collection,
      documentsById: documentsById,
    );

    final snapshot = await collection.get();
    final staleCountAfter = snapshot.docs
        .where((doc) => doc.id.startsWith('stale-'))
        .length;

    expect(firestore.runTransactionCalls, 3);
    expect(staleCountsBeforeTransaction, orderedEquals(<int>[250, 150, 50]));
    expect(staleCountAfter, 0);
    expect(snapshot.docs, hasLength(251));
  });

  test('replaceAll keeps stale documents changed before transaction', () async {
    final firestore = _HookedFakeFirebaseFirestore();
    final collection = _itemsCollectionRef(
      firestore: firestore,
      userId: 'user-1',
    );
    await collection.doc('a').set(<String, dynamic>{'name': 'Old Milk'});
    await collection.doc('b').set(<String, dynamic>{'name': 'Bread'});

    final service = FirestoreAtomicReplaceService(firestore: firestore);
    await service.replaceAll(
      collection: collection,
      documentsById: <String, Map<String, dynamic>>{
        'b': <String, dynamic>{'name': 'Bread v2'},
      },
      onBeforeDeleteStaleDocuments: () async {
        await collection.doc('a').set(<String, dynamic>{
          'name': 'Changed elsewhere',
        });
      },
    );

    final snapshot = await collection.get();
    final dataById = <String, Map<String, dynamic>>{
      for (final doc in snapshot.docs) doc.id: doc.data(),
    };

    expect(firestore.runTransactionCalls, 1);
    expect(snapshot.docs, hasLength(2));
    expect(dataById['a'], <String, dynamic>{'name': 'Changed elsewhere'});
    expect(dataById['b'], <String, dynamic>{'name': 'Bread v2'});
  });

  test(
    'deleteStaleDocumentsIfUnchanged skips missing stale documents',
    () async {
      final firestore = _HookedFakeFirebaseFirestore();
      final collection = _itemsCollectionRef(
        firestore: firestore,
        userId: 'user-1',
      );
      await collection.doc('keep').set(<String, dynamic>{'name': 'Keep'});
      await collection.doc('missing').set(<String, dynamic>{
        'name': 'Missing later',
      });

      final initialSnapshot = await collection.get();
      final service = FirestoreAtomicReplaceService(firestore: firestore);
      final staleCandidates = service.buildStaleDeleteCandidates(
        existingSnapshot: initialSnapshot,
        documentsById: const <String, Map<String, dynamic>>{},
      );

      await collection.doc('missing').delete();
      await service.deleteStaleDocumentsIfUnchanged(
        staleDeleteCandidates: staleCandidates,
      );

      final snapshot = await collection.get();
      final dataById = <String, Map<String, dynamic>>{
        for (final doc in snapshot.docs) doc.id: doc.data(),
      };

      expect(dataById.containsKey('keep'), isFalse);
      expect(dataById.containsKey('missing'), isFalse);
    },
  );

  test(
    'deleteStaleDocumentsIfUnchanged skips changed stale documents',
    () async {
      final firestore = _HookedFakeFirebaseFirestore();
      final collection = _itemsCollectionRef(
        firestore: firestore,
        userId: 'user-1',
      );
      await collection.doc('stale').set(<String, dynamic>{'name': 'Old'});

      final initialSnapshot = await collection.get();
      final service = FirestoreAtomicReplaceService(firestore: firestore);
      final staleCandidates = service.buildStaleDeleteCandidates(
        existingSnapshot: initialSnapshot,
        documentsById: const <String, Map<String, dynamic>>{},
      );

      await collection.doc('stale').set(<String, dynamic>{'name': 'Changed'});
      await service.deleteStaleDocumentsIfUnchanged(
        staleDeleteCandidates: staleCandidates,
      );

      final snapshot = await collection.get();
      final staleData = snapshot.docs
          .firstWhere((doc) => doc.id == 'stale')
          .data();

      expect(staleData, <String, dynamic>{'name': 'Changed'});
    },
  );

  test(
    'deleteStaleDocumentsIfUnchanged deletes unchanged stale documents',
    () async {
      final firestore = _HookedFakeFirebaseFirestore();
      final collection = _itemsCollectionRef(
        firestore: firestore,
        userId: 'user-1',
      );
      await collection.doc('stale').set(<String, dynamic>{'name': 'Old'});

      final initialSnapshot = await collection.get();
      final service = FirestoreAtomicReplaceService(firestore: firestore);
      final staleCandidates = service.buildStaleDeleteCandidates(
        existingSnapshot: initialSnapshot,
        documentsById: const <String, Map<String, dynamic>>{},
      );

      await service.deleteStaleDocumentsIfUnchanged(
        staleDeleteCandidates: staleCandidates,
      );

      final snapshot = await collection.get();

      expect(snapshot.docs.any((doc) => doc.id == 'stale'), isFalse);
    },
  );
}
