import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/data/'
    'calorie_barcode_backfill_repository_contract.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
import 'package:yamt/features/calories/data/calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

part 'calorie_barcode_backfill_repository.g.dart';

const _backfillLogName = 'CalorieBarcodeBackfillRepository';
const _usersCollection = 'users';
const _requestsCollection = 'barcode_enrichment_requests';
const _fingerprintCatalogCollection = 'food_fingerprint_catalog';

abstract interface class CalorieBarcodeBackfillUserSession {
  String? get currentUserId;
}

class FirestoreCalorieBarcodeBackfillRepository
    implements CalorieBarcodeBackfillRepositoryContract {
  FirestoreCalorieBarcodeBackfillRepository({
    required CalorieBarcodeBackfillUserSession session,
    required FirebaseFirestore firestore,
    required CalorieProductCacheRepositoryContract cacheRepository,
    DateTime Function()? now,
  }) : _session = session,
       _firestore = firestore,
       _cacheRepository = cacheRepository,
       _now = now ?? DateTime.now;

  final CalorieBarcodeBackfillUserSession _session;
  final FirebaseFirestore _firestore;
  final CalorieProductCacheRepositoryContract _cacheRepository;
  final DateTime Function() _now;

  @override
  Future<bool> enqueueFingerprintLookup({
    required String fingerprint,
    required String itemName,
    String? brand,
    required String trigger,
    bool forceRetry = false,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return false;
    }

    final normalizedFingerprint = fingerprint.trim();
    if (normalizedFingerprint.isEmpty) {
      return false;
    }

    final now = _now();
    final payload = _buildLookupPayload(
      userId: userId,
      fingerprint: normalizedFingerprint,
      itemName: itemName,
      brand: brand,
      trigger: trigger,
      now: now,
    );

    try {
      final requestDoc = _requestDoc(userId, normalizedFingerprint);
      if (!forceRetry) {
        await requestDoc.set(payload, SetOptions(merge: true));
        return true;
      }
      await requestDoc.set(<String, dynamic>{
        ...payload,
        'force_retry': false,
      }, SetOptions(merge: true));
      await requestDoc.set(<String, dynamic>{
        ...payload,
        'force_retry': true,
      }, SetOptions(merge: true));
      return true;
    } catch (error, stackTrace) {
      log(
        'Failed to enqueue fingerprint lookup for $normalizedFingerprint.',
        name: _backfillLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Map<String, dynamic> _buildLookupPayload({
    required String userId,
    required String fingerprint,
    required String itemName,
    required String trigger,
    required DateTime now,
    String? brand,
  }) {
    return <String, dynamic>{
      'user_id': userId,
      'fingerprint': fingerprint,
      'item_name': itemName.trim(),
      'brand': _normalizeOptionalString(brand),
      'trigger': trigger,
      'status': 'queued',
      'requested_at': now,
      'updated_at': now,
    };
  }

  @override
  Future<CalorieProductProfile?> getResolvedProfileByFingerprint(
    String fingerprint,
  ) async {
    final normalizedFingerprint = fingerprint.trim();
    if (normalizedFingerprint.isEmpty) {
      return null;
    }

    try {
      final snapshot = await _fingerprintDoc(normalizedFingerprint).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      final barcode = _readString(data['barcode']);
      if (barcode == null || barcode.isEmpty) {
        return null;
      }
      return _cacheRepository.readGlobalProduct(barcode);
    } catch (error, stackTrace) {
      log(
        'Failed to resolve fingerprint $normalizedFingerprint.',
        name: _backfillLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<bool> submitUserProvidedBarcode({
    required String fingerprint,
    required String barcode,
    required String itemName,
    String? brand,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return false;
    }

    final normalizedFingerprint = fingerprint.trim();
    final normalizedBarcode = barcode.trim();
    if (normalizedFingerprint.isEmpty || normalizedBarcode.isEmpty) {
      return false;
    }

    final now = _now();
    final payload = <String, dynamic>{
      'user_id': userId,
      'fingerprint': normalizedFingerprint,
      'item_name': itemName.trim(),
      'brand': _normalizeOptionalString(brand),
      'trigger': 'user_provided_barcode',
      'status': 'queued',
      'provided_barcode': normalizedBarcode,
      'priority': 'high',
      'requested_at': now,
      'updated_at': now,
    };

    try {
      await _requestDoc(
        userId,
        normalizedFingerprint,
      ).set(payload, SetOptions(merge: true));
      return true;
    } catch (error, stackTrace) {
      log(
        'Failed to submit user barcode for $normalizedFingerprint.',
        name: _backfillLogName,
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

  DocumentReference<Map<String, dynamic>> _requestDoc(
    String userId,
    String fingerprint,
  ) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_requestsCollection)
        .doc(fingerprint);
  }

  DocumentReference<Map<String, dynamic>> _fingerprintDoc(String fingerprint) {
    return _firestore
        .collection(_fingerprintCatalogCollection)
        .doc(fingerprint);
  }

  String? _readString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  String? _normalizeOptionalString(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}

@riverpod
CalorieBarcodeBackfillRepositoryContract calorieBarcodeBackfillRepository(
  Ref ref,
) {
  final authState = ref.watch(authStateChangesProvider);
  final currentUserId = authState.asData?.value?.uid;
  final firestore = _resolveFirestore();
  if (firestore == null) {
    return const _UnavailableCalorieBarcodeBackfillRepository();
  }
  return FirestoreCalorieBarcodeBackfillRepository(
    session: _CurrentCalorieBarcodeBackfillUserSession(
      currentUserId: currentUserId,
    ),
    firestore: firestore,
    cacheRepository: ref.watch(calorieProductCacheRepositoryProvider),
  );
}

class _CurrentCalorieBarcodeBackfillUserSession
    implements CalorieBarcodeBackfillUserSession {
  const _CurrentCalorieBarcodeBackfillUserSession({
    required String? currentUserId,
  }) : _currentUserId = currentUserId;

  final String? _currentUserId;

  @override
  String? get currentUserId => _currentUserId;
}

FirebaseFirestore? _resolveFirestore() {
  try {
    return FirebaseFirestore.instance;
  } catch (error, stackTrace) {
    log(
      'Falling back to unavailable barcode backfill repository.',
      name: _backfillLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

class _UnavailableCalorieBarcodeBackfillRepository
    implements CalorieBarcodeBackfillRepositoryContract {
  const _UnavailableCalorieBarcodeBackfillRepository();

  @override
  Future<bool> enqueueFingerprintLookup({
    required String fingerprint,
    required String itemName,
    String? brand,
    required String trigger,
    bool forceRetry = false,
  }) async {
    return false;
  }

  @override
  Future<CalorieProductProfile?> getResolvedProfileByFingerprint(
    String fingerprint,
  ) async {
    return null;
  }

  @override
  Future<bool> submitUserProvidedBarcode({
    required String fingerprint,
    required String barcode,
    required String itemName,
    String? brand,
  }) async {
    return false;
  }
}
