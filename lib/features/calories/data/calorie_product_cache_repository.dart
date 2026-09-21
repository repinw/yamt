import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_document_codec.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_user_session.dart';
import 'package:yamt/features/calories/data/'
    'unavailable_calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

part 'calorie_product_cache_repository.g.dart';

const _cacheLogName = 'FirestoreCalorieProductCacheRepository';
const _usersCollection = 'users';
const _globalCatalogCollection = 'calorie_product_catalog';
const _userOverridesCollection = 'calorie_product_overrides';
const _offProductsCollection = 'off_products';

/// Defines firestore calorie product cache repository.
class FirestoreCalorieProductCacheRepository
    implements CalorieProductCacheRepositoryContract {
  /// Creates an instance.
  new({required this._session, required this._firestore});

  final CalorieProductCacheUserSession _session;
  final FirebaseFirestore _firestore;

  @override
  Future<CalorieProductProfile?> readUserOverride(String barcode) async {
    final userId = _currentUserId();
    if (userId == null) {
      return null;
    }

    try {
      final snapshot = await _userOverrideDoc(userId, barcode).get();
      if (!snapshot.exists) {
        return null;
      }
      return decodeCalorieProductDocument(snapshot, fallbackBarcode: barcode);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read calorie override for $barcode.',
        name: _cacheLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<CalorieProductProfile?> readGlobalProduct(String barcode) async {
    try {
      final snapshot = await _globalDoc(barcode).get();
      if (snapshot.exists) {
        return decodeCalorieProductDocument(snapshot, fallbackBarcode: barcode);
      }

      final offSnapshot = await _offProductsDoc(barcode).get();
      if (!offSnapshot.exists) {
        return null;
      }
      return decodeOffCacheProductDocument(
        offSnapshot,
        fallbackBarcode: barcode,
      );
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read global calorie product for $barcode.',
        name: _cacheLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<bool> saveGlobalProduct(CalorieProductProfile profile) async {
    try {
      final payload = prepareGlobalProductPayload(
        profile,
        updatedAt: DateTime.now(),
      );
      await _globalDoc(profile.barcode).set(payload);
      return true;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        log(
          'Skipping global calorie product write for ${profile.barcode}: '
          'permission denied by Firestore rules.',
          name: _cacheLogName,
        );
        return false;
      }
      log(
        'Failed to save global calorie product ${profile.barcode}.',
        name: _cacheLogName,
        error: error,
      );
      return false;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to save global calorie product ${profile.barcode}.',
        name: _cacheLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> saveUserOverride({
    required CalorieProductProfile profile,
    required String reason,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return false;
    }

    try {
      final payload = prepareUserOverridePayload(
        profile: profile,
        userId: userId,
        reason: reason,
        now: DateTime.now(),
      );
      await _userOverrideDoc(userId, profile.barcode).set(payload);
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to save user calorie override ${profile.barcode}.',
        name: _cacheLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  String? _currentUserId() {
    final userId = _session.currentUserId;
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return userId;
  }

  DocumentReference<Map<String, dynamic>> _globalDoc(String barcode) {
    return _firestore.collection(_globalCatalogCollection).doc(barcode);
  }

  DocumentReference<Map<String, dynamic>> _userOverrideDoc(
    String userId,
    String barcode,
  ) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_userOverridesCollection)
        .doc(barcode);
  }

  DocumentReference<Map<String, dynamic>> _offProductsDoc(String barcode) {
    return _firestore.collection(_offProductsCollection).doc(barcode);
  }
}

/// Calorie product cache repository.
@riverpod
CalorieProductCacheRepositoryContract calorieProductCacheRepository(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  final currentUserId = authState.asData?.value?.uid;
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    return const UnavailableCalorieProductCacheRepository();
  }
  return FirestoreCalorieProductCacheRepository(
    session: CurrentCalorieProductCacheUserSession(
      currentUserId: currentUserId,
    ),
    firestore: firestore,
  );
}
