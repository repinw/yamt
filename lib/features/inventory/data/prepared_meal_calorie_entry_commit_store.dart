// Commit store stays class-based for provider overrides and test fakes.

import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/firestore_offline_writes.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/data/calorie_entry_document_codec.dart';
import 'package:yamt/features/calories/data/calorie_product_image_url.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'prepared_meal_calorie_entry_commit_store.g.dart';

const _commitStoreLogName = 'PreparedMealCalorieEntryCommitStore';
const _usersCollection = 'users';
const _calorieEntriesCollection = 'calorie_entries';
const _preparedMealsCollection = 'prepared_meals';

/// The prepared meal calorie entry commit store provider.
@riverpod
PreparedMealCalorieEntryCommitStore? preparedMealCalorieEntryCommitStore(
  Ref ref,
) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    return null;
  }

  return FirestorePreparedMealCalorieEntryCommitStore(
    firestore: firestore,
    dataCipher: ref.watch(userDataCipherProvider),
    householdCipher: ref.watch(householdCipherProvider),
  );
}

/// Defines prepared meal calorie entry commit store.
abstract interface class PreparedMealCalorieEntryCommitStore {
  /// Commit entry and prepared meal.
  Future<bool> commitEntryAndPreparedMeal({required CalorieEntry entry});
}

/// Defines firestore prepared meal calorie entry commit store.
class FirestorePreparedMealCalorieEntryCommitStore
    implements PreparedMealCalorieEntryCommitStore {
  /// The firestore prepared meal calorie entry commit store.
  const new({
    required this._firestore,
    required this._dataCipher,
    required this._householdCipher,
  });

  final FirebaseFirestore _firestore;
  final UserDataCipher? _dataCipher;
  final HouseholdCipher? _householdCipher;

  @override
  Future<bool> commitEntryAndPreparedMeal({required CalorieEntry entry}) async {
    final dataCipher = _dataCipher;
    final household = _householdCipher;
    final preparedMealId = entry.bundleSourcePreparedMealId?.trim();
    final consumedPortions = entry.bundleConsumedPortions ?? 0;
    if (dataCipher == null ||
        household == null ||
        preparedMealId == null ||
        preparedMealId.isEmpty) {
      log(
        'Cannot commit prepared meal calorie entry ${entry.id}: '
        'missing data key, household key, or meal id.',
        name: _commitStoreLogName,
      );
      return false;
    }
    if (consumedPortions <= 0) {
      log(
        'Cannot commit prepared meal calorie entry ${entry.id}: '
        'invalid consumedPortions=$consumedPortions.',
        name: _commitStoreLogName,
      );
      return false;
    }

    // A batch instead of a transaction: Firestore queues batches while
    // offline, but transactions fail. The portions are computed from the
    // local copy, so two offline consumptions of the same meal may overwrite
    // each other.
    try {
      final mealCollection = _preparedMealCollection(household);
      final mealRef = mealCollection.reference.doc(preparedMealId);
      final mealSnapshot = await readDocumentLocalFirst(mealRef);
      final storedMeal = await mealCollection.open(mealSnapshot);
      if (storedMeal == null) {
        log(
          'Prepared meal $preparedMealId missing while committing '
          'calorie entry ${entry.id}.',
          name: _commitStoreLogName,
        );
        return false;
      }

      final rawMeal = Map<String, dynamic>.from(storedMeal)
        ..['id'] = mealSnapshot.id;
      final currentMeal = PreparedMeal.fromJson(rawMeal);
      if (currentMeal.hasPendingRecipeIngredients) {
        log(
          'Prepared meal $preparedMealId still has pending ingredients.',
          name: _commitStoreLogName,
        );
        return false;
      }
      if (currentMeal.remainingPortions < consumedPortions) {
        log(
          'Prepared meal $preparedMealId has only '
          '${currentMeal.remainingPortions} remaining portions, '
          'requested $consumedPortions.',
          name: _commitStoreLogName,
        );
        return false;
      }

      final normalizedEntry = entry.copyWith(
        userId: dataCipher.uid,
        imageUrl: normalizeCalorieProductImageUrl(entry.imageUrl),
      );
      final committedAt = normalizedEntry.updatedAt;
      final nextRemainingPortions =
          currentMeal.remainingPortions - consumedPortions;
      final nextMeal = currentMeal.copyWith(
        remainingPortions: nextRemainingPortions,
      );

      final mealUpdates = <String, dynamic>{
        'remaining_portions': nextRemainingPortions,
        'updated_at': committedAt.toIso8601String(),
      };
      if (nextMeal.remainingNetWeight != null) {
        mealUpdates['remaining_net_weight'] = nextMeal.remainingNetWeight;
      }

      final entryRef = _calorieEntriesCollectionRef(dataCipher.uid)
          .doc(normalizedEntry.id);
      final entryDocument = await encodeCalorieEntryDocument(
        normalizedEntry,
        reference: entryRef,
        cipher: dataCipher.cipher,
      );
      // The meal is encrypted as a whole, so the batch writes the full
      // document instead of updating single fields.
      final mealDocument = await mealCollection.seal(mealRef.id, {
        ...storedMeal,
        ...mealUpdates,
      });
      final batch = _firestore.batch()
        ..set(entryRef, entryDocument)
        ..set(mealRef, mealDocument);
      commitBatchInBackground(
        batch,
        failureMessage:
            'Server rejected prepared meal calorie entry ${entry.id}.',
        logName: _commitStoreLogName,
      );
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to commit prepared meal calorie entry ${entry.id}.',
        name: _commitStoreLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  CollectionReference<Map<String, dynamic>> _calorieEntriesCollectionRef(
    String userId,
  ) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_calorieEntriesCollection);
  }

  SealedCollection _preparedMealCollection(HouseholdCipher household) {
    return SealedCollection(
      _firestore
          .collection(_usersCollection)
          .doc(household.ownerUid)
          .collection(_preparedMealsCollection),
      cipher: household.cipher,
    );
  }
}
