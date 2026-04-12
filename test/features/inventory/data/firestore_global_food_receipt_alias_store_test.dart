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

    final store = FirestoreGlobalFoodReceiptAliasStore(firestore: firestore);
    final documents = await store.searchCandidates(lookupKey: 'aldi|milch 3 5');

    expect(documents, hasLength(1));
    expect(documents.single.id, 'alias-1');
  });

  test(
    'upsertAll increments the selection counter for a duplicate id',
    () async {
      final firestore = FakeFirebaseFirestore();
      final store = FirestoreGlobalFoodReceiptAliasStore(firestore: firestore);

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

      final snapshot = await _aliasCollection(
        firestore: firestore,
      ).doc('alias-1').get();

      expect(snapshot.data()!['receipt_name'], 'OVERRIDDEN');
      expect(snapshot.data()!['selection_count'], 3);
      expect(snapshot.data()!['created_at'], '2026-03-01T10:00:00.000Z');
      expect(snapshot.data()!['updated_at'], '2026-03-01T11:00:00.000Z');
    },
  );
}
