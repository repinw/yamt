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
        searchTokens: const <String>[],
      );

      expect(documents, hasLength(1));
      expect(documents.single.id, 'apple');
    },
  );
}
