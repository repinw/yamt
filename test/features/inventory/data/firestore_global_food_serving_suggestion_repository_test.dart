import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/data/'
    'firestore_global_food_serving_suggestion_repository.dart';

const _globalCollection = 'global_food_item_serving_sizes';
const _usersCollection = 'users';
const _prefsCollection = 'global_food_item_serving_prefs';
const _votesCollection = 'global_food_item_serving_votes';

class _DenyingTransactionFakeFirebaseFirestore extends FakeFirebaseFirestore {
  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'Denied',
    );
  }
}

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class, mocktail verifies Firestore query chaining.
class _MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class, mocktail verifies Firestore query chaining.
class _MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class _MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

void main() {
  test('readSuggestions applies global query ordering and limit', () async {
    final firestore = _MockFirebaseFirestore();
    final collection = _MockCollectionReference();
    final query = _MockQuery();
    final snapshot = _MockQuerySnapshot();
    when(() => firestore.collection(_globalCollection)).thenReturn(collection);
    when(
      () => collection.where('item_key', isEqualTo: 'global_off-cheese'),
    ).thenReturn(query);
    when(
      () => query.orderBy('unique_user_count', descending: true),
    ).thenReturn(query);
    when(
      () => query.orderBy('selection_count', descending: true),
    ).thenReturn(query);
    when(() => query.orderBy('updated_at', descending: true)).thenReturn(query);
    when(() => query.limit(3)).thenReturn(query);
    when(query.get).thenAnswer((_) async => snapshot);
    when(() => snapshot.docs).thenReturn(const []);

    final repository = FirestoreGlobalFoodServingSuggestionRepository(
      firestore: firestore,
      currentUserId: null,
    );

    await repository.readSuggestions(
      foodFingerprint: '',
      globalFoodItemId: 'off-cheese',
      limit: 3,
    );

    verifyInOrder([
      () => collection.where('item_key', isEqualTo: 'global_off-cheese'),
      () => query.orderBy('unique_user_count', descending: true),
      () => query.orderBy('selection_count', descending: true),
      () => query.orderBy('updated_at', descending: true),
      () => query.limit(3),
      query.get,
    ]);
  });

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
    'readSuggestions dedupes shared keys while preserving labels',
    () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection(_globalCollection).doc('global').set(
        <String, dynamic>{
          'id': 'global',
          'item_key': 'global_off-cheese',
          'global_food_item_id': 'off-cheese',
          'amount': 35,
          'unit': 'g',
          'selection_count': 5,
          'unique_user_count': 4,
          'created_at': '2026-04-09T10:00:00.000Z',
          'updated_at': '2026-04-09T10:00:00.000Z',
        },
      );
      await firestore.collection(_globalCollection).doc('fingerprint').set(
        <String, dynamic>{
          'id': 'fingerprint',
          'item_key': 'fingerprint_cheese__brand',
          'amount': 35,
          'unit': 'g',
          'label': 'Scheibe',
          'selection_count': 1,
          'unique_user_count': 1,
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

      expect(suggestions.globalSuggestions, hasLength(1));
      expect(suggestions.globalSuggestions.single.itemKey, 'global_off-cheese');
      expect(suggestions.globalSuggestions.single.amount, 35);
      expect(suggestions.globalSuggestions.single.label, 'Scheibe');
    },
  );

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
        label: 'Scheibe',
        selectedAt: DateTime.parse('2026-04-10T10:00:00.000Z'),
      );
      await repository.recordSelection(
        foodFingerprint: 'cheese__brand',
        globalFoodItemId: 'off-cheese',
        amount: 35,
        unit: ConsumedUnit.grams,
        label: 'Scheibe',
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
      final secondUserRepository =
          FirestoreGlobalFoodServingSuggestionRepository(
            firestore: firestore,
            currentUserId: 'user-2',
          );
      final secondUserSuggestions = await secondUserRepository.readSuggestions(
        foodFingerprint: 'cheese__brand',
        globalFoodItemId: 'off-cheese',
      );

      expect(sharedSnapshot.data()!['selection_count'], 2);
      expect(sharedSnapshot.data()!['unique_user_count'], 1);
      expect(sharedSnapshot.data()!['label'], 'Scheibe');
      expect(globalPrefSnapshot.data()!['amount'], 35);
      expect(globalPrefSnapshot.data()!['label'], 'Scheibe');
      expect(fingerprintPrefSnapshot.data()!['amount'], 35);
      expect(fingerprintPrefSnapshot.data()!['label'], 'Scheibe');
      expect(
        voteSnapshot.data()!['suggestion_id'],
        'global_off-cheese_g_35000',
      );
      expect(secondUserSuggestions.globalSuggestions.single.amount, 35);
      expect(secondUserSuggestions.globalSuggestions.single.label, 'Scheibe');
    },
  );

  test(
    'recordSelection keeps same-serving labels when later call has none',
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
        label: 'Scheibe',
        selectedAt: DateTime.parse('2026-04-10T10:00:00.000Z'),
      );
      await repository.recordSelection(
        foodFingerprint: 'cheese__brand',
        globalFoodItemId: 'off-cheese',
        amount: 35,
        unit: ConsumedUnit.grams,
        selectedAt: DateTime.parse('2026-04-11T10:00:00.000Z'),
      );

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

      expect(globalPrefSnapshot.data()!['label'], 'Scheibe');
      expect(fingerprintPrefSnapshot.data()!['label'], 'Scheibe');
    },
  );

  test(
    'recordSelection shares fingerprint servings without global items',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repository = FirestoreGlobalFoodServingSuggestionRepository(
        firestore: firestore,
        currentUserId: 'user-1',
      );

      await repository.recordSelection(
        foodFingerprint: 'cheese__brand',
        globalFoodItemId: 'pending-cheese__brand',
        amount: 35,
        unit: ConsumedUnit.grams,
        label: 'Scheibe',
        selectedAt: DateTime.parse('2026-04-10T10:00:00.000Z'),
      );
      await repository.recordSelection(
        foodFingerprint: 'cheese__brand',
        globalFoodItemId: 'pending-cheese__brand',
        amount: 35,
        unit: ConsumedUnit.grams,
        selectedAt: DateTime.parse('2026-04-11T10:00:00.000Z'),
      );

      final sharedSnapshot = await firestore
          .collection(_globalCollection)
          .doc('fingerprint_cheese__brand_g_35000')
          .get();
      final fingerprintPrefSnapshot = await firestore
          .collection(_usersCollection)
          .doc('user-1')
          .collection(_prefsCollection)
          .doc('fingerprint_cheese__brand')
          .get();
      final secondUserRepository =
          FirestoreGlobalFoodServingSuggestionRepository(
            firestore: firestore,
            currentUserId: 'user-2',
          );
      final suggestions = await secondUserRepository.readSuggestions(
        foodFingerprint: 'cheese__brand',
        globalFoodItemId: 'pending-cheese__brand',
      );

      expect(sharedSnapshot.data()!['item_key'], 'fingerprint_cheese__brand');
      expect(sharedSnapshot.data()!['label'], 'Scheibe');
      expect(fingerprintPrefSnapshot.data()!['label'], 'Scheibe');
      expect(suggestions.globalSuggestions, hasLength(1));
      expect(suggestions.globalSuggestions.single.amount, 35);
      expect(suggestions.globalSuggestions.single.label, 'Scheibe');
    },
  );

  test(
    'recordSelection uses fingerprint key for pending global food items',
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
          .doc('fingerprint_cheese__brand_g_27000')
          .get();
      final fingerprintPrefSnapshot = await firestore
          .collection(_usersCollection)
          .doc('user-1')
          .collection(_prefsCollection)
          .doc('fingerprint_cheese__brand')
          .get();

      expect(sharedSnapshot.data()!['amount'], 27);
      expect(sharedSnapshot.data()!['global_food_item_id'], isNull);
      expect(fingerprintPrefSnapshot.data()!['amount'], 27);
    },
  );

  test(
    'recordSelection keeps personal preference and throws '
    'when shared write is denied',
    () async {
      final firestore = _DenyingTransactionFakeFirebaseFirestore();
      final repository = FirestoreGlobalFoodServingSuggestionRepository(
        firestore: firestore,
        currentUserId: 'user-1',
      );

      await expectLater(
        repository.recordSelection(
          foodFingerprint: 'cheese__brand',
          globalFoodItemId: 'off-cheese',
          amount: 35,
          unit: ConsumedUnit.grams,
          label: 'Scheibe',
          selectedAt: DateTime.parse('2026-04-10T10:00:00.000Z'),
        ),
        throwsA(
          isA<FirebaseException>().having(
            (error) => error.code,
            'code',
            'permission-denied',
          ),
        ),
      );

      final sharedSnapshot = await firestore
          .collection(_globalCollection)
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
      final votesSnapshot = await firestore
          .collection(_usersCollection)
          .doc('user-1')
          .collection(_votesCollection)
          .get();

      expect(sharedSnapshot.docs, isEmpty);
      expect(votesSnapshot.docs, isEmpty);
      expect(globalPrefSnapshot.data()!['amount'], 35);
      expect(globalPrefSnapshot.data()!['label'], 'Scheibe');
      expect(fingerprintPrefSnapshot.data()!['amount'], 35);
      expect(fingerprintPrefSnapshot.data()!['label'], 'Scheibe');
    },
  );
}
