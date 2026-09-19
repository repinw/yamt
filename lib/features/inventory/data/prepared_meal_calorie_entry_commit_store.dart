// Commit store stays class-based for provider overrides and test fakes.

import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/firestore_offline_writes.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_product_image_url.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
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
  final currentUserId = ref.watch(authStateChangesProvider).asData?.value?.uid;
  final preparedMealOwnerUserId = ref.watch(
    effectiveHouseholdDataOwnerUserIdProvider,
  );
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    return null;
  }

  return FirestorePreparedMealCalorieEntryCommitStore(
    firestore: firestore,
    currentUserId: currentUserId,
    preparedMealOwnerUserId: preparedMealOwnerUserId,
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
    required this._currentUserId,
    required this._preparedMealOwnerUserId,
  });

  final FirebaseFirestore _firestore;
  final String? _currentUserId;
  final String? _preparedMealOwnerUserId;

  @override
  Future<bool> commitEntryAndPreparedMeal({required CalorieEntry entry}) async {
    final entryUserId = _resolveEntryUserId(entry.userId);
    final preparedMealOwnerUserId = _resolvePreparedMealOwnerUserId();
    final preparedMealId = entry.bundleSourcePreparedMealId?.trim();
    final consumedPortions = entry.bundleConsumedPortions ?? 0;
    if (entryUserId == null ||
        preparedMealOwnerUserId == null ||
        preparedMealId == null ||
        preparedMealId.isEmpty) {
      log(
        'Cannot commit prepared meal calorie entry ${entry.id}: '
        'missing user or meal id.',
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
      final mealRef = _preparedMealCollection(
        preparedMealOwnerUserId,
      ).doc(preparedMealId);
      final mealSnapshot = await readDocumentLocalFirst(mealRef);
      if (!mealSnapshot.exists) {
        log(
          'Prepared meal $preparedMealId missing while committing '
          'calorie entry ${entry.id}.',
          name: _commitStoreLogName,
        );
        return false;
      }

      final rawMeal = Map<String, dynamic>.from(
        mealSnapshot.data() ?? const <String, dynamic>{},
      )..['id'] = mealSnapshot.id;
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
        userId: entryUserId,
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

      final batch = _firestore.batch()
        ..set(
          _calorieEntriesCollectionRef(entryUserId).doc(normalizedEntry.id),
          normalizedEntry.toJson(),
        )
        ..update(mealRef, mealUpdates);
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

  String? _resolveEntryUserId(String entryUserId) {
    final currentUserId = _currentUserId?.trim();
    if (currentUserId != null && currentUserId.isNotEmpty) {
      return currentUserId;
    }

    final normalizedEntryUserId = entryUserId.trim();
    if (normalizedEntryUserId.isNotEmpty) {
      return normalizedEntryUserId;
    }
    return null;
  }

  String? _resolvePreparedMealOwnerUserId() {
    final preparedMealOwnerUserId = _preparedMealOwnerUserId?.trim();
    if (preparedMealOwnerUserId != null && preparedMealOwnerUserId.isNotEmpty) {
      return preparedMealOwnerUserId;
    }

    final currentUserId = _currentUserId?.trim();
    if (currentUserId != null && currentUserId.isNotEmpty) {
      return currentUserId;
    }
    return null;
  }

  CollectionReference<Map<String, dynamic>> _calorieEntriesCollectionRef(
    String userId,
  ) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_calorieEntriesCollection);
  }

  CollectionReference<Map<String, dynamic>> _preparedMealCollection(
    String userId,
  ) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_preparedMealsCollection);
  }
}
