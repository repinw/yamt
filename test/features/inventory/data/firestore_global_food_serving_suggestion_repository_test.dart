import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/data/'
    'firestore_global_food_serving_suggestion_repository.dart';

const _globalCollection = 'global_food_item_serving_sizes';
const _usersCollection = 'users';
const _prefsCollection = 'global_food_item_serving_prefs';
const _votesCollection = 'global_food_item_serving_votes';

void main() {
  test('readSuggestions prefers the newest personal preference', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore
        .collection(_usersCollection)
        .doc('user-1')
        .collection(_prefsCollection)
        .doc('global_off-cheese')
        .set(<String, dynamic>{
          'item_key': 'global_off-cheese',
          'global_food_item_id': 'off-cheese',
          'food_fingerprint': 'cheese__brand',
          'amount': 35,
          'unit': 'g',
          'updated_at': '2026-04-10T10:00:00.000Z',
        });
    await firestore
        .collection(_usersCollection)
        .doc('user-1')
        .collection(_prefsCollection)
        .doc('fingerprint_cheese__brand')
        .set(<String, dynamic>{
          'item_key': 'fingerprint_cheese__brand',
          'food_fingerprint': 'cheese__brand',
          'amount': 30,
          'unit': 'g',
          'updated_at': '2026-04-09T10:00:00.000Z',
        });
    await firestore.collection(_globalCollection).doc('older').set(
      <String, dynamic>{
        'id': 'older',
        'item_key': 'global_off-cheese',
        'global_food_item_id': 'off-cheese',
        'amount': 34,
        'unit': 'g',
        'selection_count': 5,
        'unique_user_count': 2,
        'created_at': '2026-04-09T10:00:00.000Z',
        'updated_at': '2026-04-09T10:00:00.000Z',
      },
    );
    await firestore.collection(_globalCollection).doc('newer').set(
      <String, dynamic>{
        'id': 'newer',
        'item_key': 'global_off-cheese',
        'global_food_item_id': 'off-cheese',
        'amount': 36,
        'unit': 'g',
        'selection_count': 3,
        'unique_user_count': 4,
        'created_at': '2026-04-10T10:00:00.000Z',
        'updated_at': '2026-04-10T10:00:00.000Z',
      },
    );

    final repository = FirestoreGlobalFoodServingSuggestionRepository(
      firestore: firestore,
      currentUserId: 'user-1',
    );

    final suggestions = await repository.readSuggestions(
      foodFingerprint: 'cheese__brand',
      globalFoodItemId: 'off-cheese',
    );

    expect(suggestions.personalSuggestion?.amount, 35);
    expect(suggestions.personalSuggestion?.unit, ConsumedUnit.grams);
    expect(suggestions.globalSuggestions.map((item) => item.amount), <double>[
      36,
      34,
    ]);
  });

  test(
    'recordSelection writes shared counters and increments unique users once',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repository = FirestoreGlobalFoodServingSuggestionRepository(
        firestore: firestore,
        currentUserId: 'user-1',
      );

      await repository.recordSelection(
        foodFingerprint: 'cheese__brand',
        globalFoodItemId: 'off-cheese',
        amount: 35,
        unit: ConsumedUnit.grams,
        selectedAt: DateTime.parse('2026-04-10T10:00:00.000Z'),
      );
      await repository.recordSelection(
        foodFingerprint: 'cheese__brand',
        globalFoodItemId: 'off-cheese',
        amount: 35,
        unit: ConsumedUnit.grams,
        selectedAt: DateTime.parse('2026-04-11T10:00:00.000Z'),
      );

      final sharedSnapshot = await firestore
          .collection(_globalCollection)
          .doc('global_off-cheese_g_35000')
          .get();
      final globalPrefSnapshot = await firestore
          .collection(_usersCollection)
          .doc('user-1')
          .collection(_prefsCollection)
          .doc('global_off-cheese')
          .get();
      final fingerprintPrefSnapshot = await firestore
          .collection(_usersCollection)
          .doc('user-1')
          .collection(_prefsCollection)
          .doc('fingerprint_cheese__brand')
          .get();
      final voteSnapshot = await firestore
          .collection(_usersCollection)
          .doc('user-1')
          .collection(_votesCollection)
          .doc('global_off-cheese_g_35000')
          .get();

      expect(sharedSnapshot.data()!['selection_count'], 2);
      expect(sharedSnapshot.data()!['unique_user_count'], 1);
      expect(globalPrefSnapshot.data()!['amount'], 35);
      expect(fingerprintPrefSnapshot.data()!['amount'], 35);
      expect(
        voteSnapshot.data()!['suggestion_id'],
        'global_off-cheese_g_35000',
      );
    },
  );

  test(
    'recordSelection skips shared writes for pending global food items',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repository = FirestoreGlobalFoodServingSuggestionRepository(
        firestore: firestore,
        currentUserId: 'user-1',
      );

      await repository.recordSelection(
        foodFingerprint: 'cheese__brand',
        globalFoodItemId: 'pending-cheese__brand',
        amount: 27,
        unit: ConsumedUnit.grams,
        selectedAt: DateTime.parse('2026-04-10T10:00:00.000Z'),
      );

      final sharedSnapshot = await firestore
          .collection(_globalCollection)
          .get();
      final fingerprintPrefSnapshot = await firestore
          .collection(_usersCollection)
          .doc('user-1')
          .collection(_prefsCollection)
          .doc('fingerprint_cheese__brand')
          .get();

      expect(sharedSnapshot.docs, isEmpty);
      expect(fingerprintPrefSnapshot.data()!['amount'], 27);
    },
  );
}
