import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

const _usersCollection = 'users';
const _calorieEntriesCollection = 'calorie_entries';
const _preparedMealsCollection = 'prepared_meals';

CollectionReference<Map<String, dynamic>> _preparedMealCollection({
  required FirebaseFirestore firestore,
  String userId = 'user-1',
}) {
  return firestore
      .collection(_usersCollection)
      .doc(userId)
      .collection(_preparedMealsCollection);
}

CollectionReference<Map<String, dynamic>> _entryCollection({
  required FirebaseFirestore firestore,
  String userId = 'user-1',
}) {
  return firestore
      .collection(_usersCollection)
      .doc(userId)
      .collection(_calorieEntriesCollection);
}

PreparedMeal _meal({num remainingPortions = 4}) {
  return PreparedMeal(
    id: 'meal-1',
    name: 'Lunch box',
    imageAssetId: 'asset-meal-1',
    totalPortions: 4,
    remainingPortions: remainingPortions,
    totalKcal: 400,
    totalProtein: 20,
    totalCarbs: 40,
    totalFat: 10,
    createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
    updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
    components: const <PreparedMealComponent>[],
  );
}

CalorieEntry _entry({num consumedPortions = 2}) {
  return CalorieEntry.bundle(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Lunch box',
    imageAssetId: 'asset-meal-1',
    mealType: MealType.lunch,
    totalKcal: 200,
    totalProtein: 10,
    totalCarbs: 20,
    totalFat: 5,
    bundleSourcePreparedMealId: 'meal-1',
    bundleConsumedPortions: consumedPortions,
    bundleTotalPortions: 4,
    bundleComponents: const <CalorieEntryBundleComponent>[],
    loggedAt: DateTime(2026, 3, 27, 13),
    createdAt: DateTime(2026, 3, 27, 13),
    updatedAt: DateTime(2026, 3, 27, 13),
  );
}

void main() {
  test(
    'commitEntryAndPreparedMeal saves entry and reduces meal together',
    () async {
      final firestore = FakeFirebaseFirestore();
      await _preparedMealCollection(
        firestore: firestore,
      ).doc('meal-1').set(_meal().toJson());

      final store = FirestorePreparedMealCalorieEntryCommitStore(
        firestore: firestore,
        currentUserId: 'user-1',
        preparedMealOwnerUserId: 'user-1',
      );

      final saved = await store.commitEntryAndPreparedMeal(entry: _entry());

      expect(saved, isTrue);

      final savedEntry = await _entryCollection(
        firestore: firestore,
      ).doc('entry-1').get();
      expect(savedEntry.exists, isTrue);
      expect(savedEntry.data()?['bundle_source_prepared_meal_id'], 'meal-1');
      expect(
        savedEntry.data()?['updated_at'],
        Timestamp.fromDate(_entry().updatedAt),
      );

      final savedMeal = await _preparedMealCollection(
        firestore: firestore,
      ).doc('meal-1').get();
      expect(savedMeal.data()?['remaining_portions'], 2);
      expect(
        savedMeal.data()?['updated_at'],
        _entry().updatedAt.toIso8601String(),
      );
    },
  );

  test(
    'commitEntryAndPreparedMeal persists fractional remaining portions',
    () async {
      final firestore = FakeFirebaseFirestore();
      await _preparedMealCollection(
        firestore: firestore,
      ).doc('meal-1').set(_meal(remainingPortions: 1).toJson());

      final store = FirestorePreparedMealCalorieEntryCommitStore(
        firestore: firestore,
        currentUserId: 'user-1',
        preparedMealOwnerUserId: 'user-1',
      );

      final saved = await store.commitEntryAndPreparedMeal(
        entry: _entry(consumedPortions: 0.5),
      );

      expect(saved, isTrue);

      final savedEntry = await _entryCollection(
        firestore: firestore,
      ).doc('entry-1').get();
      expect(savedEntry.data()?['bundle_consumed_portions'], 0.5);

      final savedMeal = await _preparedMealCollection(
        firestore: firestore,
      ).doc('meal-1').get();
      expect(savedMeal.data()?['remaining_portions'], 0.5);
    },
  );

  test('commitEntryAndPreparedMeal leaves meal untouched when portions '
      'exceed remaining stock', () async {
    final firestore = FakeFirebaseFirestore();
    await _preparedMealCollection(
      firestore: firestore,
    ).doc('meal-1').set(_meal(remainingPortions: 1).toJson());

    final store = FirestorePreparedMealCalorieEntryCommitStore(
      firestore: firestore,
      currentUserId: 'user-1',
      preparedMealOwnerUserId: 'user-1',
    );

    final saved = await store.commitEntryAndPreparedMeal(entry: _entry());

    expect(saved, isFalse);

    final savedEntry = await _entryCollection(
      firestore: firestore,
    ).doc('entry-1').get();
    expect(savedEntry.exists, isFalse);

    final savedMeal = await _preparedMealCollection(
      firestore: firestore,
    ).doc('meal-1').get();
    expect(savedMeal.data()?['remaining_portions'], 1);
  });

  test(
    'commitEntryAndPreparedMeal returns false when meal is missing',
    () async {
      final firestore = FakeFirebaseFirestore();

      final store = FirestorePreparedMealCalorieEntryCommitStore(
        firestore: firestore,
        currentUserId: 'user-1',
        preparedMealOwnerUserId: 'user-1',
      );

      final saved = await store.commitEntryAndPreparedMeal(entry: _entry());

      expect(saved, isFalse);

      final savedEntry = await _entryCollection(
        firestore: firestore,
      ).doc('entry-1').get();
      expect(savedEntry.exists, isFalse);
    },
  );

  test('commitEntryAndPreparedMeal returns false for meals with pending '
      'ingredients', () async {
    final firestore = FakeFirebaseFirestore();
    await _preparedMealCollection(firestore: firestore)
        .doc('meal-1')
        .set(
          _meal()
              .copyWith(pendingRecipeIngredients: const <String>['200 g Rice'])
              .toJson(),
        );

    final store = FirestorePreparedMealCalorieEntryCommitStore(
      firestore: firestore,
      currentUserId: 'user-1',
      preparedMealOwnerUserId: 'user-1',
    );

    final saved = await store.commitEntryAndPreparedMeal(entry: _entry());

    expect(saved, isFalse);

    final savedEntry = await _entryCollection(
      firestore: firestore,
    ).doc('entry-1').get();
    expect(savedEntry.exists, isFalse);

    final savedMeal = await _preparedMealCollection(
      firestore: firestore,
    ).doc('meal-1').get();
    expect(savedMeal.data()?['pending_recipe_ingredients'], const <String>[
      '200 g Rice',
    ]);
    expect(savedMeal.data()?['remaining_portions'], 4);
  });

  test('commitEntryAndPreparedMeal uses shared meal owner and personal '
      'entry user', () async {
    final firestore = FakeFirebaseFirestore();
    await _preparedMealCollection(
      firestore: firestore,
      userId: 'host-1',
    ).doc('meal-1').set(_meal().toJson());

    final store = FirestorePreparedMealCalorieEntryCommitStore(
      firestore: firestore,
      currentUserId: 'member-1',
      preparedMealOwnerUserId: 'host-1',
    );

    final saved = await store.commitEntryAndPreparedMeal(
      entry: _entry().copyWith(userId: 'member-1'),
    );

    expect(saved, isTrue);

    final savedEntry = await _entryCollection(
      firestore: firestore,
      userId: 'member-1',
    ).doc('entry-1').get();
    final savedMeal = await _preparedMealCollection(
      firestore: firestore,
      userId: 'host-1',
    ).doc('meal-1').get();

    expect(savedEntry.exists, isTrue);
    expect(savedEntry.data()?['user_id'], 'member-1');
    expect(savedMeal.data()?['remaining_portions'], 2);
  });
}
