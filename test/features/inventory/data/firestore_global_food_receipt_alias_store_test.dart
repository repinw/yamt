import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/global_food_receipt_alias_store.dart';

const _globalFoodReceiptAliasesCollection = 'global_food_item_receipt_aliases';

CollectionReference<Map<String, dynamic>> _aliasCollection({
  required FirebaseFirestore firestore,
}) {
  return firestore.collection(_globalFoodReceiptAliasesCollection);
}

Map<String, dynamic> _aliasData({
  required String id,
  required String storeName,
  required String normalizedStoreName,
  required String receiptName,
  required String normalizedReceiptName,
  required String globalFoodItemId,
  int selectionCount = 1,
  String createdAt = '2026-03-01T10:00:00.000Z',
  String updatedAt = '2026-03-01T10:00:00.000Z',
}) {
  return <String, dynamic>{
    'id': id,
    'global_food_item_id': globalFoodItemId,
    'store_name': storeName,
    'normalized_store_name': normalizedStoreName,
    'receipt_name': receiptName,
    'normalized_receipt_name': normalizedReceiptName,
    'compact_receipt_name': normalizedReceiptName.replaceAll(' ', ''),
    'receipt_search_tokens': <String>[
      normalizedReceiptName,
      normalizedReceiptName.replaceAll(' ', ''),
      ...normalizedReceiptName.split(' ').where((token) => token.isNotEmpty),
    ],
    'lookup_key': '$normalizedStoreName|$normalizedReceiptName',
    'selection_count': selectionCount,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'global_food_item': <String, dynamic>{
      'id': globalFoodItemId,
      'name': 'Whole Milk',
      'food_fingerprint': 'whole_milk__milsani',
      'normalized_name': 'whole milk',
      'search_tokens': const <String>['whole milk', 'whole', 'milk'],
      'status': 'active',
      'created_at': '2026-03-01T09:00:00.000Z',
      'updated_at': '2026-03-01T09:00:00.000Z',
    },
  };
}

void main() {
  test('searchCandidates finds aliases by lookup key', () async {
    final firestore = FakeFirebaseFirestore();
    final collection = _aliasCollection(firestore: firestore);
    await collection
        .doc('alias-1')
        .set(
          _aliasData(
            id: 'alias-1',
            storeName: 'Aldi',
            normalizedStoreName: 'aldi',
            receiptName: 'MILCH 3,5%',
            normalizedReceiptName: 'milch 3 5',
            globalFoodItemId: 'milk',
          ),
        );

    final store = FirestoreGlobalFoodReceiptAliasStore(
      firestore: firestore,
      currentUserId: 'user-1',
    );
    final documents = await store.searchCandidates(
      normalizedStoreName: 'aldi',
      lookupKey: 'aldi|milch 3 5',
      compactReceiptName: 'milch35',
      receiptSearchTokens: const <String>['milch 3 5', 'milch35', 'milch'],
    );

    expect(documents, hasLength(1));
    expect(documents.single.id, 'alias-1');
  });

  test(
    'searchCandidates finds similar receipt names by token overlap',
    () async {
      final firestore = FakeFirebaseFirestore();
      final collection = _aliasCollection(firestore: firestore);
      await collection
          .doc('alias-1')
          .set(
            _aliasData(
              id: 'alias-1',
              storeName: 'Aldi',
              normalizedStoreName: 'aldi',
              receiptName: 'KAESE SCHEIBEN 150G',
              normalizedReceiptName: 'kaese scheiben 150g',
              globalFoodItemId: 'cheese',
            ),
          );

      final store = FirestoreGlobalFoodReceiptAliasStore(
        firestore: firestore,
        currentUserId: 'user-1',
      );
      final documents = await store.searchCandidates(
        normalizedStoreName: 'aldi',
        lookupKey: 'aldi|kaese scheiben',
        compactReceiptName: 'kaesescheiben',
        receiptSearchTokens: const <String>[
          'kaese scheiben',
          'kaesescheiben',
          'kaese',
          'scheiben',
        ],
      );

      expect(documents, hasLength(1));
      expect(documents.single.id, 'alias-1');
    },
  );

  test('upsertAll adds one save per call and keeps the alias text', () async {
    final firestore = FakeFirebaseFirestore();
    final store = FirestoreGlobalFoodReceiptAliasStore(
      firestore: firestore,
      currentUserId: 'user-1',
    );

    final firstData = _aliasData(
      id: 'alias-1',
      storeName: 'Aldi',
      normalizedStoreName: 'aldi',
      receiptName: 'MILCH 3,5%',
      normalizedReceiptName: 'milch 3 5',
      globalFoodItemId: 'milk',
    );
    final secondData = _aliasData(
      id: 'alias-1',
      storeName: 'Aldi',
      normalizedStoreName: 'aldi',
      receiptName: 'OVERRIDDEN',
      normalizedReceiptName: 'overridden',
      globalFoodItemId: 'milk',
      selectionCount: 2,
      updatedAt: '2026-03-01T11:00:00.000Z',
    );

    await store.upsertAll(
      documentsById: <String, Map<String, dynamic>>{'alias-1': firstData},
    );
    await store.upsertAll(
      documentsById: <String, Map<String, dynamic>>{'alias-1': secondData},
    );

    final snapshot = await _aliasCollection(firestore: firestore)
        .doc('alias-1')
        .get();

    // Only counters, the product and the time change on a later save.
    expect(snapshot.data()!['receipt_name'], 'MILCH 3,5%');
    expect(snapshot.data()!['selection_count'], 2);
    expect(snapshot.data()!['unique_user_count'], 1);
    expect(snapshot.data()!['created_at'], '2026-03-01T10:00:00.000Z');
    expect(snapshot.data()!['updated_at'], '2026-03-01T11:00:00.000Z');
  });

  test('upsertAll records the creator and keeps it on updates', () async {
    final firestore = FakeFirebaseFirestore();
    final data = _aliasData(
      id: 'alias-1',
      storeName: 'Aldi',
      normalizedStoreName: 'aldi',
      receiptName: 'MILCH 3,5%',
      normalizedReceiptName: 'milch 3 5',
      globalFoodItemId: 'milk',
    );

    await FirestoreGlobalFoodReceiptAliasStore(
      firestore: firestore,
      currentUserId: 'creator',
    ).upsertAll(documentsById: <String, Map<String, dynamic>>{'alias-1': data});
    await FirestoreGlobalFoodReceiptAliasStore(
      firestore: firestore,
      currentUserId: 'other-user',
    ).upsertAll(documentsById: <String, Map<String, dynamic>>{'alias-1': data});

    final snapshot = await _aliasCollection(firestore: firestore)
        .doc('alias-1')
        .get();
    expect(snapshot.data()!['created_by_uid'], 'creator');
    expect(snapshot.data()!['selection_count'], 2);
  });

  group('user votes', () {
    Map<String, dynamic> milkAlias() => _aliasData(
      id: 'alias-1',
      storeName: 'Aldi',
      normalizedStoreName: 'aldi',
      receiptName: 'MILCH 3,5%',
      normalizedReceiptName: 'milch 3 5',
      globalFoodItemId: 'milk',
    );

    Future<void> saveAs(FakeFirebaseFirestore firestore, String userId) {
      return FirestoreGlobalFoodReceiptAliasStore(
        firestore: firestore,
        currentUserId: userId,
      ).upsertAll(
        documentsById: <String, Map<String, dynamic>>{'alias-1': milkAlias()},
      );
    }

    Future<Map<String, dynamic>> aliasData(
      FakeFirebaseFirestore firestore,
    ) async {
      final snapshot = await _aliasCollection(firestore: firestore)
          .doc('alias-1')
          .get();
      return snapshot.data()!;
    }

    test('count each user once', () async {
      final firestore = FakeFirebaseFirestore();

      await saveAs(firestore, 'user-1');
      await saveAs(firestore, 'user-1');
      expect((await aliasData(firestore))['unique_user_count'], 1);

      await saveAs(firestore, 'user-2');
      final data = await aliasData(firestore);
      expect(data['unique_user_count'], 2);
      expect(data['selection_count'], 3);

      final vote = await firestore
          .collection('users')
          .doc('user-2')
          .collection('global_food_item_receipt_alias_votes')
          .doc('alias-1')
          .get();
      expect(vote.data(), <String, dynamic>{
        'alias_id': 'alias-1',
        'lookup_key': 'aldi|milch 3 5',
        'global_food_item_id': 'milk',
        'created_at': '2026-03-01T10:00:00.000Z',
        'updated_at': '2026-03-01T10:00:00.000Z',
      });
    });

    test('an older alias counts its author as its one user', () async {
      final firestore = FakeFirebaseFirestore();
      await _aliasCollection(firestore: firestore)
          .doc('alias-1')
          .set(<String, dynamic>{
            ...milkAlias(),
            'selection_count': 5,
            'created_by_uid': 'author',
          });

      await saveAs(firestore, 'author');
      expect((await aliasData(firestore))['unique_user_count'], 1);

      await saveAs(firestore, 'user-2');
      final data = await aliasData(firestore);
      expect(data['unique_user_count'], 2);
      expect(data['selection_count'], 7);
    });

    test('readOwnAliasIds returns the aliases the user voted for', () async {
      final firestore = FakeFirebaseFirestore();
      await saveAs(firestore, 'user-1');

      final ownIds = await FirestoreGlobalFoodReceiptAliasStore(
        firestore: firestore,
        currentUserId: 'user-1',
      ).readOwnAliasIds(lookupKey: 'aldi|milch 3 5');
      final otherIds = await FirestoreGlobalFoodReceiptAliasStore(
        firestore: firestore,
        currentUserId: 'user-2',
      ).readOwnAliasIds(lookupKey: 'aldi|milch 3 5');

      expect(ownIds, <String>{'alias-1'});
      expect(otherIds, isEmpty);
    });

    test('upsertAll fails without a signed-in user', () async {
      final firestore = FakeFirebaseFirestore();
      final saved =
          await FirestoreGlobalFoodReceiptAliasStore(
            firestore: firestore,
            currentUserId: null,
          ).upsertAll(
            documentsById: <String, Map<String, dynamic>>{
              'alias-1': milkAlias(),
            },
          );

      expect(saved, isFalse);
    });
  });
}
