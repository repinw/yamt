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
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';

part 'prepared_meal_calorie_entry_commit_store.g.dart';

const _commitStoreLogName = 'PreparedMealCalorieEntryCommitStore';
const _usersCollection = 'users';
const _householdsCollection = 'households';
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

  /// Deletes [entry] and gives its portions back to its prepared meal in one
  /// write.
  Future<CalorieEntryDeleteResult> deleteEntryAndRestorePreparedMeal({
    required CalorieEntry entry,
  });
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
      final stored = await _openMeal(mealCollection, mealRef);
      if (stored == null) {
        return false;
      }
      final (:storedMeal, meal: currentMeal) = stored;
      if (!currentMeal.allowsPortions(
        PreparedMealAction.eat,
        consumedPortions,
      )) {
        log(
          'Prepared meal $preparedMealId cannot give $consumedPortions '
          'portions (inPot=${currentMeal.isInPot}, '
          'openRows=${currentMeal.pendingRecipeIngredients.length}, '
          'remaining=${currentMeal.remainingPortions}).',
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

  @override
  Future<CalorieEntryDeleteResult> deleteEntryAndRestorePreparedMeal({
    required CalorieEntry entry,
  }) async {
    const failed = CalorieEntryDeleteResult.failure(
      CalorieEntryDeleteFailureReason.restoreFailed,
    );
    final dataCipher = _dataCipher;
    final household = _householdCipher;
    final mealId = entry.bundleSourcePreparedMealId?.trim();
    final portions = entry.bundleConsumedPortions ?? 0;
    if (dataCipher == null ||
        household == null ||
        mealId == null ||
        mealId.isEmpty ||
        portions <= 0) {
      log(
        'Cannot delete entry ${entry.id} with its portions: no data key, '
        'no household key, no meal, or portions=$portions.',
        name: _commitStoreLogName,
      );
      return failed;
    }
    try {
      final mealCollection = _preparedMealCollection(household);
      final mealRef = mealCollection.reference.doc(mealId);
      final stored = await _openMeal(mealCollection, mealRef);
      if (stored == null) {
        return const CalorieEntryDeleteResult.failure(
          CalorieEntryDeleteFailureReason.sourceMissing,
        );
      }
      final nextRemaining = stored.meal.remainingPortions + portions;
      if (nextRemaining > stored.meal.totalPortions) {
        log(
          'Prepared meal $mealId cannot take back $portions portions '
          '(remaining=${stored.meal.remainingPortions}, '
          'total=${stored.meal.totalPortions}).',
          name: _commitStoreLogName,
        );
        return failed;
      }
      final nextWeight = stored.meal
          .copyWith(remainingPortions: nextRemaining)
          .remainingNetWeight;
      final mealDocument = await mealCollection.seal(mealRef.id, {
        ...stored.storedMeal,
        'remaining_portions': nextRemaining,
        'updated_at': DateTime.now().toIso8601String(),
        'remaining_net_weight': ?nextWeight,
      });
      final batch = _firestore.batch()
        ..delete(_calorieEntriesCollectionRef(dataCipher.uid).doc(entry.id))
        ..set(mealRef, mealDocument);
      commitBatchInBackground(
        batch,
        failureMessage: 'Server rejected deleting entry ${entry.id}.',
        logName: _commitStoreLogName,
      );
      return const CalorieEntryDeleteResult.success(restoredToInventory: true);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to delete entry ${entry.id} with its portions.',
        name: _commitStoreLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return failed;
    }
  }

  /// Reads the meal at [mealRef], or null when it no longer exists.
  Future<({Map<String, dynamic> storedMeal, PreparedMeal meal})?> _openMeal(
    SealedCollection mealCollection,
    DocumentReference<Map<String, dynamic>> mealRef,
  ) async {
    final snapshot = await readDocumentLocalFirst(mealRef);
    final storedMeal = await mealCollection.open(snapshot);
    if (storedMeal == null) {
      log('Prepared meal ${mealRef.id} is missing.', name: _commitStoreLogName);
      return null;
    }
    final meal = PreparedMeal.fromJson(
      Map<String, dynamic>.from(storedMeal)..['id'] = snapshot.id,
    );
    return (storedMeal: storedMeal, meal: meal);
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
          .collection(_householdsCollection)
          .doc(household.householdId)
          .collection(_preparedMealsCollection),
      cipher: household.cipher,
    );
  }
}
