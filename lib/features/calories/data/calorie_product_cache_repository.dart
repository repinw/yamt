import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/plaintext_document_encryption.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_document_codec.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
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
///
/// The user's own product corrections are stored encrypted with the data key
/// of the user. The global catalog stays readable.
class FirestoreCalorieProductCacheRepository
    implements CalorieProductCacheRepositoryContract {
  /// Creates an instance.
  new({required this._dataCipher, required this._firestore});

  final UserDataCipher? _dataCipher;
  final FirebaseFirestore _firestore;

  @override
  Future<CalorieProductProfile?> readUserOverride(String barcode) async {
    final dataCipher = _dataCipher;
    if (dataCipher == null) {
      return null;
    }

    try {
      final snapshot = await _userOverrideDoc(dataCipher.uid, barcode).get();
      final payload = snapshot.data()?[encryptedPayloadField];
      if (payload is! String) {
        return null;
      }
      return decodeCalorieProductJson(
        await dataCipher.cipher.decryptJson(
          payload,
          aad: snapshot.reference.path,
        ),
        fallbackBarcode: barcode,
        documentId: snapshot.id,
      );
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
    final dataCipher = _dataCipher;
    if (dataCipher == null) {
      return false;
    }

    try {
      final override = prepareUserOverridePayload(
        profile: profile,
        userId: dataCipher.uid,
        reason: reason,
        now: DateTime.now(),
      );
      final reference = _userOverrideDoc(dataCipher.uid, profile.barcode);
      await reference.set(<String, dynamic>{
        encryptedPayloadField: await dataCipher.cipher.encryptJson(
          override,
          aad: reference.path,
        ),
      });
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
  final dataCipher = ref.watch(userDataCipherProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    return const UnavailableCalorieProductCacheRepository();
  }
  return FirestoreCalorieProductCacheRepository(
    dataCipher: dataCipher,
    firestore: firestore,
  );
}
