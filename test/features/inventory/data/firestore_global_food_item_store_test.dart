import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/global_food_item_store.dart';

const _globalFoodItemsCollection = 'global_food_items';

CollectionReference<Map<String, dynamic>> _globalFoodCollection({
  required FirebaseFirestore firestore,
}) {
  return firestore.collection(_globalFoodItemsCollection);
}

Future<void> _seedProduct({
  required CollectionReference<Map<String, dynamic>> collection,
  required String id,
  required String name,
  required String normalizedName,
  required List<String> searchTokens,
  String? storeName,
  String? normalizedStoreName,
  String? barcode,
  String? foodFingerprint,
}) async {
  final data = <String, dynamic>{
    'id': id,
    'name': name,
    'food_fingerprint': foodFingerprint ?? '${normalizedName}_fingerprint',
    'normalized_name': normalizedName,
    'search_tokens': searchTokens,
    'status': 'active',
    'created_at': '2026-03-01T10:00:00.000Z',
    'updated_at': '2026-03-01T10:00:00.000Z',
  };
  if (storeName != null) {
    data['store_name'] = storeName;
  }
  if (normalizedStoreName != null) {
    data['normalized_store_name'] = normalizedStoreName;
  }
  if (barcode != null) {
    data['barcode'] = barcode;
  }
  await collection.doc(id).set(data);
}

void main() {
  test(
    'searchCandidates merges exact and token-based matches without duplicates',
    () async {
      final firestore = FakeFirebaseFirestore();
      final collection = _globalFoodCollection(firestore: firestore);
      await _seedProduct(
        collection: collection,
        id: 'milk',
        name: 'Whole Milk',
        normalizedName: 'whole milk',
        searchTokens: const <String>['whole milk', 'whole', 'milk'],
        foodFingerprint: 'milk__acme',
      );

      final store = FirestoreGlobalFoodItemStore(firestore: firestore);
      final documents = await store.searchCandidates(
        normalizedName: 'whole milk',
        foodFingerprint: 'milk__acme',
        searchTokens: const <String>['whole milk', 'milk'],
      );

      expect(documents, hasLength(1));
      expect(documents.single.id, 'milk');
    },
  );

  test(
    'searchCandidates returns barcode matches when token query is empty',
    () async {
      final firestore = FakeFirebaseFirestore();
      final collection = _globalFoodCollection(firestore: firestore);
      await _seedProduct(
        collection: collection,
        id: 'apple',
        name: 'Apple Juice',
        normalizedName: 'apple juice',
        searchTokens: const <String>['apple juice', 'apple', 'juice'],
        barcode: '4006381333931',
      );

      final store = FirestoreGlobalFoodItemStore(firestore: firestore);
      final documents = await store.searchCandidates(
        barcode: '4006381333931',
      );

      expect(documents, hasLength(1));
      expect(documents.single.id, 'apple');
    },
  );

  test('searchCandidates returns store matches when available', () async {
    final firestore = FakeFirebaseFirestore();
    final collection = _globalFoodCollection(firestore: firestore);
    await _seedProduct(
      collection: collection,
      id: 'milk',
      name: 'Whole Milk',
      normalizedName: 'whole milk',
      normalizedStoreName: 'aldi',
      searchTokens: const <String>['whole milk', 'whole', 'milk'],
      storeName: 'Aldi',
    );

    final store = FirestoreGlobalFoodItemStore(firestore: firestore);
    final documents = await store.searchCandidates(normalizedStoreName: 'aldi');

    expect(documents, hasLength(1));
    expect(documents.single.id, 'milk');
  });

  test(
    'upsertAll fills missing fields without overwriting existing values',
    () async {
      final firestore = FakeFirebaseFirestore();
      final collection = _globalFoodCollection(firestore: firestore);
      await collection.doc('milk').set(<String, dynamic>{
        'id': 'milk',
        'name': 'Milk',
        'food_fingerprint': 'milk__old_brand',
        'normalized_name': 'milk',
        'search_tokens': const <String>['milk'],
        'status': 'active',
        'created_at': '2026-03-01T10:00:00.000Z',
        'updated_at': '2026-03-01T10:00:00.000Z',
      });

      final store = FirestoreGlobalFoodItemStore(firestore: firestore);
      await store.upsertAll(
        documentsById: <String, Map<String, dynamic>>{
          'milk': <String, dynamic>{
            'id': 'milk',
            'name': 'Milk',
            'brand': 'New Brand',
            'food_fingerprint': 'milk__new_brand',
            'normalized_name': 'milk',
            'normalized_brand': 'new brand',
            'search_tokens': const <String>['milk'],
            'status': 'active',
            'created_at': '2026-04-13T10:00:00.000Z',
            'updated_at': '2026-04-13T10:00:00.000Z',
          },
        },
      );

      final snapshot = await collection.doc('milk').get();
      expect(snapshot.data()!['brand'], 'New Brand');
      expect(snapshot.data()!['normalized_brand'], 'new brand');
      expect(snapshot.data()!['food_fingerprint'], 'milk__old_brand');
      expect(snapshot.data()!['search_tokens'], const <String>['milk']);
      expect(snapshot.data()!['created_at'], '2026-03-01T10:00:00.000Z');
      expect(snapshot.data()!['updated_at'], '2026-04-13T10:00:00.000Z');
    },
  );

  test(
    'upsertAll keeps sparse existing docs sparse while filling missing values',
    () async {
      final firestore = FakeFirebaseFirestore();
      final collection = _globalFoodCollection(firestore: firestore);
      await collection.doc('milk').set(<String, dynamic>{
        'id': 'milk',
        'name': 'Milk',
        'food_fingerprint': 'milk__fingerprint',
        'normalized_name': 'milk',
        'search_tokens': const <String>['milk'],
        'status': 'active',
        'created_at': '2026-03-01T10:00:00.000Z',
        'updated_at': '2026-03-01T10:00:00.000Z',
      });

      final store = FirestoreGlobalFoodItemStore(firestore: firestore);
      await store.upsertAll(
        documentsById: <String, Map<String, dynamic>>{
          'milk': <String, dynamic>{
            'id': 'milk',
            'name': 'Milk',
            'brand': 'Acme',
            'category': null,
            'store_name': null,
            'barcode': '4006381333931',
            'image_url': null,
            'package_weight': '500 g',
            'serving_size': null,
            'serving_quantity': null,
            'serving_quantity_unit': null,
            'nutrition': <String, dynamic>{
              'quality_status': 'verified',
              'per_100_kcal': 100.0,
              'per_100_protein': null,
            },
            'normalized_name': 'milk',
            'normalized_brand': 'acme',
            'normalized_store_name': null,
            'search_tokens': const <String>['milk'],
            'status': 'active',
            'merged_into_id': null,
            'created_at': '2026-04-13T10:00:00.000Z',
            'updated_at': '2026-04-13T10:00:00.000Z',
          },
        },
      );

      final snapshot = await collection.doc('milk').get();
      final data = snapshot.data()!;
      final nutrition = Map<String, dynamic>.from(
        data['nutrition']! as Map<String, dynamic>,
      );

      expect(data['brand'], 'Acme');
      expect(data['normalized_brand'], 'acme');
      expect(data['barcode'], '4006381333931');
      expect(data['package_weight'], '500 g');
      expect(data, isNot(contains('category')));
      expect(data, isNot(contains('merged_into_id')));
      expect(data, isNot(contains('store_name')));
      expect(data, isNot(contains('image_url')));
      expect(nutrition['quality_status'], 'verified');
      expect(nutrition['per_100_kcal'], 100.0);
      expect(nutrition, isNot(contains('per_100_protein')));
    },
  );
}
