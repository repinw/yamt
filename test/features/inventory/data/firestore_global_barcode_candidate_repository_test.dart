import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/'
    'firestore_global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

const _candidatesCollection = 'global_barcode_candidates';

CollectionReference<Map<String, dynamic>> _candidateCollection({
  required FirebaseFirestore firestore,
}) {
  return firestore.collection(_candidatesCollection);
}

GlobalBarcodeCandidate _candidate({
  required String id,
  required String barcode,
  required String globalFoodItemId,
  required int selectionCount,
  required int uniqueUserCount,
  required String name,
  String? brand,
  String? imageUrl,
  GlobalFoodNutrition? nutrition,
}) {
  final now = DateTime.parse('2026-04-13T10:00:00Z');
  return GlobalBarcodeCandidate(
    id: id,
    barcode: barcode,
    globalFoodItemId: globalFoodItemId,
    selectionCount: selectionCount,
    uniqueUserCount: uniqueUserCount,
    completenessScore: computeGlobalBarcodeCandidateCompletenessScore(
      GlobalFoodItem.create(
        id: globalFoodItemId,
        name: name,
        now: now,
        brand: brand,
        barcode: barcode,
        imageUrl: imageUrl,
        nutrition: nutrition,
      ),
    ),
    globalFoodItem: GlobalFoodItem.create(
      id: globalFoodItemId,
      name: name,
      now: now,
      brand: brand,
      barcode: barcode,
      imageUrl: imageUrl,
      nutrition: nutrition,
    ),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test(
    'readCandidates returns highest-ranked barcode candidates first',
    () async {
      final firestore = FakeFirebaseFirestore();
      final collection = _candidateCollection(firestore: firestore);
      await collection
          .doc('low')
          .set(
            _candidate(
              id: 'low',
              barcode: '4006381333931',
              globalFoodItemId: 'milk-low',
              selectionCount: 10,
              uniqueUserCount: 1,
              name: 'Milk',
            ).toJson(),
          );
      await collection
          .doc('high')
          .set(
            _candidate(
              id: 'high',
              barcode: '4006381333931',
              globalFoodItemId: 'milk-high',
              selectionCount: 3,
              uniqueUserCount: 2,
              name: 'Milk',
              imageUrl: 'https://example.com/milk.png',
            ).toJson(),
          );

      final repository = FirestoreGlobalBarcodeCandidateRepository(
        firestore: firestore,
        currentUserId: 'user-1',
      );
      final candidates = await repository.readCandidates(
        barcode: '4006381333931',
      );

      expect(candidates, hasLength(2));
      expect(candidates.first.globalFoodItemId, 'milk-high');
      expect(candidates.last.globalFoodItemId, 'milk-low');
    },
  );

  test(
    'recordSelection increments vote counters without rewriting payload',
    () async {
      final firestore = FakeFirebaseFirestore();
      final now = DateTime.parse('2026-04-13T10:00:00Z');
      final product = GlobalFoodItem.create(
        id: 'off-4006381333931',
        name: 'Milk',
        now: now,
        barcode: '4006381333931',
        nutrition: const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.verified,
          per100Kcal: 100,
        ),
      );

      final firstRepository = FirestoreGlobalBarcodeCandidateRepository(
        firestore: firestore,
        currentUserId: 'user-1',
      );
      final secondRepository = FirestoreGlobalBarcodeCandidateRepository(
        firestore: firestore,
        currentUserId: 'user-2',
      );

      await firstRepository.recordSelection(
        barcode: '4006381333931',
        globalFoodItem: product,
        selectedAt: now,
      );
      await firstRepository.recordSelection(
        barcode: '4006381333931',
        globalFoodItem: product.copyWith(
          imageUrl: 'https://example.com/milk.png',
        ),
        selectedAt: now.add(const Duration(minutes: 1)),
      );
      await secondRepository.recordSelection(
        barcode: '4006381333931',
        globalFoodItem: product.copyWith(
          imageUrl: 'https://example.com/milk.png',
        ),
        selectedAt: now.add(const Duration(minutes: 2)),
      );

      final snapshot = await _candidateCollection(
        firestore: firestore,
      ).doc('barcode-4006381333931-off-4006381333931').get();

      expect(snapshot.exists, isTrue);
      expect(snapshot.data()!['selection_count'], 3);
      expect(snapshot.data()!['unique_user_count'], 2);
      expect(snapshot.data()!['completeness_score'], 8);
      expect(snapshot.data()!['global_food_item']['image_url'], isNull);
    },
  );

  test(
    'readCandidates falls back to client-side sort when index query fails',
    () async {
      final firestore = FakeFirebaseFirestore();
      final collection = _candidateCollection(firestore: firestore);
      await collection
          .doc('low')
          .set(
            _candidate(
              id: 'low',
              barcode: '4006381333931',
              globalFoodItemId: 'milk-low',
              selectionCount: 10,
              uniqueUserCount: 1,
              name: 'Milk',
            ).toJson(),
          );
      await collection
          .doc('high')
          .set(
            _candidate(
              id: 'high',
              barcode: '4006381333931',
              globalFoodItemId: 'milk-high',
              selectionCount: 3,
              uniqueUserCount: 2,
              name: 'Milk',
              imageUrl: 'https://example.com/milk.png',
            ).toJson(),
          );

      final repository = FirestoreGlobalBarcodeCandidateRepository(
        firestore: firestore,
        currentUserId: 'user-1',
        indexedReaderOverride: (normalizedBarcode, limit) async {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'failed-precondition',
            message: 'The query requires an index.',
          );
        },
      );

      final candidates = await repository.readCandidates(
        barcode: '4006381333931',
      );

      expect(candidates, hasLength(2));
      expect(candidates.first.globalFoodItemId, 'milk-high');
      expect(candidates.last.globalFoodItemId, 'milk-low');
    },
  );
}
