import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

part 'calorie_product_cache_repository.g.dart';

const _cacheLogName = 'FirestoreCalorieProductCacheRepository';
const _usersCollection = 'users';
const _globalCatalogCollection = 'calorie_product_catalog';
const _userOverridesCollection = 'calorie_product_overrides';
const _offProductsCollection = 'off_products';
const _offCacheStatusFound = 'found';

abstract interface class CalorieProductCacheUserSession {
  String? get currentUserId;
}

class FirestoreCalorieProductCacheRepository
    implements CalorieProductCacheRepositoryContract {
  FirestoreCalorieProductCacheRepository({
    required CalorieProductCacheUserSession session,
    required FirebaseFirestore firestore,
  }) : _session = session,
       _firestore = firestore;

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
      return _decodeDocument(snapshot, fallbackBarcode: barcode);
    } catch (error, stackTrace) {
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
        return _decodeDocument(snapshot, fallbackBarcode: barcode);
      }

      final offSnapshot = await _offProductsDoc(barcode).get();
      if (!offSnapshot.exists) {
        return null;
      }
      return _decodeOffCacheDocument(offSnapshot, fallbackBarcode: barcode);
    } catch (error, stackTrace) {
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
      final normalized = profile.copyWith(updatedAt: DateTime.now());
      await _globalDoc(normalized.barcode).set(normalized.toJson());
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
    } catch (error, stackTrace) {
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
      final now = DateTime.now();
      final payload = profile
          .copyWith(
            source: CalorieProductSource.userOverride,
            updatedAt: now,
            createdAt: now,
          )
          .toJson();
      payload['user_id'] = userId;
      payload['reason'] = reason;
      await _userOverrideDoc(userId, profile.barcode).set(payload);
      return true;
    } catch (error, stackTrace) {
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

  CalorieProductProfile? _decodeDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    required String fallbackBarcode,
  }) {
    final raw = snapshot.data();
    if (raw == null) {
      return null;
    }

    final normalized = _normalizeFirestoreJson(raw);
    final barcode = normalized['barcode'];
    if (barcode is! String || barcode.isEmpty) {
      normalized['barcode'] = fallbackBarcode;
    }

    try {
      return CalorieProductProfile.fromJson(normalized);
    } catch (error, stackTrace) {
      log(
        'Malformed calorie product cache document ${snapshot.id}.',
        name: _cacheLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  CalorieProductProfile? _decodeOffCacheDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    required String fallbackBarcode,
  }) {
    final raw = snapshot.data();
    if (raw == null) {
      return null;
    }

    final status = raw['status'];
    if (status is! String || status != _offCacheStatusFound) {
      return null;
    }

    final product = raw['product'];
    if (product is! Map<String, dynamic>) {
      return null;
    }

    final normalized = _normalizeFirestoreJson(product);

    final barcode = normalized['barcode'];
    if (barcode is! String || barcode.isEmpty) {
      normalized['barcode'] = fallbackBarcode;
    }

    try {
      return CalorieProductProfile.fromJson(normalized);
    } catch (error, stackTrace) {
      log(
        'Malformed OFF product cache document ${snapshot.id}.',
        name: _cacheLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Map<String, dynamic> _normalizeFirestoreJson(Map<String, dynamic> rawData) {
    return rawData.map(
      (key, value) => MapEntry<String, dynamic>(key, _normalizeValue(value)),
    );
  }

  dynamic _normalizeValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry<String, dynamic>(
          key.toString(),
          _normalizeValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map<dynamic>(_normalizeValue).toList(growable: false);
    }
    return value;
  }
}

@riverpod
CalorieProductCacheRepositoryContract calorieProductCacheRepository(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  final currentUserId = authState.asData?.value?.uid;
  final firestore = _resolveFirestore();
  if (firestore == null) {
    return const _UnavailableCalorieProductCacheRepository();
  }
  return FirestoreCalorieProductCacheRepository(
    session: _CurrentCalorieProductCacheUserSession(
      currentUserId: currentUserId,
    ),
    firestore: firestore,
  );
}

class _CurrentCalorieProductCacheUserSession
    implements CalorieProductCacheUserSession {
  const _CurrentCalorieProductCacheUserSession({required String? currentUserId})
    : _currentUserId = currentUserId;

  final String? _currentUserId;

  @override
  String? get currentUserId => _currentUserId;
}

FirebaseFirestore? _resolveFirestore() {
  try {
    return FirebaseFirestore.instance;
  } catch (error, stackTrace) {
    log(
      'Falling back to unavailable calorie product cache repository.',
      name: _cacheLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

class _UnavailableCalorieProductCacheRepository
    implements CalorieProductCacheRepositoryContract {
  const _UnavailableCalorieProductCacheRepository();

  @override
  Future<CalorieProductProfile?> readUserOverride(String barcode) async {
    return null;
  }

  @override
  Future<CalorieProductProfile?> readGlobalProduct(String barcode) async {
    return null;
  }

  @override
  Future<bool> saveGlobalProduct(CalorieProductProfile profile) async {
    return false;
  }

  @override
  Future<bool> saveUserOverride({
    required CalorieProductProfile profile,
    required String reason,
  }) async {
    return false;
  }
}
