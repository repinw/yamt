import 'dart:developer' show log;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/data/'
    'calorie_barcode_backfill_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

part 'calorie_barcode_backfill_repository.g.dart';

const _backfillLogName = 'CalorieBarcodeBackfillRepository';
const _resolveCallableName = 'resolveInventoryItemBarcode';
const _enqueueJobsCallableName = 'enqueueInventoryBarcodeJobs';
const _functionsRegion = 'europe-west1';
const _useFunctionsEmulator = bool.fromEnvironment(
  'USE_FUNCTIONS_EMULATOR',
);
const _functionsEmulatorHostFromDefine = String.fromEnvironment(
  'FUNCTIONS_EMULATOR_HOST',
);
const _functionsEmulatorPort = int.fromEnvironment(
  'FUNCTIONS_EMULATOR_PORT',
  defaultValue: 5001,
);

/// Defines calorie barcode backfill user session.
abstract interface class CalorieBarcodeBackfillUserSession {
  /// The current user id.
  String? get currentUserId;
}

/// Defines firestore calorie barcode backfill repository.
class FirestoreCalorieBarcodeBackfillRepository
    implements CalorieBarcodeBackfillRepositoryContract {
  /// Creates an instance.
  FirestoreCalorieBarcodeBackfillRepository({
    required CalorieBarcodeBackfillUserSession session,
    FirebaseFunctions? functions,
    Future<Map<String, dynamic>?> Function(Map<String, dynamic> payload)?
    resolveInventoryItemCallable,
  }) : _session = session,
       _functions = functions,
       _resolveInventoryItemCallable = resolveInventoryItemCallable;

  final CalorieBarcodeBackfillUserSession _session;
  final FirebaseFunctions? _functions;
  final Future<Map<String, dynamic>?> Function(Map<String, dynamic> payload)?
  _resolveInventoryItemCallable;

  @override
  Future<bool> enqueueFingerprintLookup({
    required String fingerprint,
    required String itemName,
    required String trigger,
    String? itemId,
    String? brand,
    bool forceRetry = false,
  }) async {
    final userId = _currentUserId();
    final normalizedItemId = itemId?.trim();
    final normalizedFingerprint = fingerprint.trim();
    final normalizedName = itemName.trim();
    if (userId == null ||
        normalizedItemId == null ||
        normalizedItemId.isEmpty ||
        normalizedFingerprint.isEmpty ||
        normalizedName.isEmpty) {
      _trace(
        'Skip barcode lookup due to invalid payload: '
        'hasUser=${userId != null}, '
        'hasItemId=${normalizedItemId != null && normalizedItemId.isNotEmpty}, '
        'hasFingerprint=${normalizedFingerprint.isNotEmpty}, '
        'hasItemName=${normalizedName.isNotEmpty}.',
      );
      return false;
    }

    final payload = <String, dynamic>{
      'userId': userId,
      'itemId': normalizedItemId,
      'fingerprint': normalizedFingerprint,
      'itemName': normalizedName,
      'brand': _normalizeOptionalString(brand),
      'trigger': trigger.trim(),
    };
    try {
      final response = await _invokeResolveCallable(payload);
      final success = response?['success'];
      if (success is bool) {
        return success;
      }
      return true;
    } on Object catch (error, stackTrace) {
      if (_useFunctionsEmulator &&
          error is FirebaseFunctionsException &&
          error.code == 'unavailable') {
        _trace(
          'Functions emulator unreachable at '
          '${_resolveFunctionsEmulatorHost()}:$_functionsEmulatorPort. '
          'Android Emulator=10.0.2.2, '
          'physical device=<PC-LAN-IP>.',
        );
      }
      _trace(
        'Failed to resolve inventory item barcode for $normalizedItemId.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> enqueueBatchLookup({
    required List<BarcodeLookupBatchItem> items,
    required String trigger,
  }) async {
    final userId = _currentUserId();
    final normalizedTrigger = trigger.trim();
    if (userId == null || items.isEmpty || normalizedTrigger.isEmpty) {
      _trace(
        'Skip batch barcode lookup due to invalid payload: '
        'hasUser=${userId != null}, '
        'itemCount=${items.length}, '
        'hasTrigger=${normalizedTrigger.isNotEmpty}.',
      );
      return false;
    }

    final normalizedItems = items
        .map(_normalizeBatchItemPayload)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    if (normalizedItems.isEmpty) {
      _trace('Skip batch barcode lookup because all items were invalid.');
      return false;
    }

    final payload = <String, dynamic>{
      'userId': userId,
      'trigger': normalizedTrigger,
      'items': normalizedItems,
    };
    try {
      final response = await _invokeBatchResolveCallable(payload);
      final queuedCount = _readInt(response?['queuedCount']);
      final resolvedCount = _readInt(response?['resolvedCount']);
      if (queuedCount != null || resolvedCount != null) {
        _trace(
          'Batch barcode resolution result: '
          'resolved=${resolvedCount ?? 0}, queued=${queuedCount ?? 0}.',
        );
      }
      final success = response?['success'];
      if (success is bool) {
        return success;
      }
      return true;
    } on Object catch (error, stackTrace) {
      _trace(
        'Failed to resolve barcode batch for ${normalizedItems.length} items.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
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
    return true;
  }

  String? _currentUserId() {
    final userId = _session.currentUserId;
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return userId;
  }

  String? _normalizeOptionalString(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  Future<Map<String, dynamic>?> _invokeResolveCallable(
    Map<String, dynamic> payload,
  ) async {
    final localCallable = _resolveInventoryItemCallable;
    if (localCallable != null) {
      return localCallable(payload);
    }

    final functions = _functions;
    if (functions == null) {
      throw StateError('FirebaseFunctions instance is not configured.');
    }
    _trace(
      'Calling $_resolveCallableName for itemId=${payload['itemId']} '
      'in region=$_functionsRegion.',
    );
    final callable = functions.httpsCallable(_resolveCallableName);
    final result = await callable.call<Object?>(payload);
    return _castCallableResponse(result.data);
  }

  Future<Map<String, dynamic>?> _invokeBatchResolveCallable(
    Map<String, dynamic> payload,
  ) async {
    final functions = _functions;
    if (functions == null) {
      throw StateError('FirebaseFunctions instance is not configured.');
    }
    final itemCount = (payload['items'] as List<dynamic>).length;
    _trace(
      'Calling $_enqueueJobsCallableName for itemCount=$itemCount '
      'in region=$_functionsRegion.',
    );
    final callable = functions.httpsCallable(_enqueueJobsCallableName);
    final result = await callable.call<Object?>(payload);
    return _castCallableResponse(result.data);
  }

  Map<String, dynamic>? _castCallableResponse(Object? rawData) {
    if (rawData is! Map) {
      return null;
    }
    try {
      return Map<String, dynamic>.from(rawData);
    } on Object catch (error, stackTrace) {
      _trace(
        'Callable response map had invalid key/value types.',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Map<String, dynamic>? _normalizeBatchItemPayload(
    BarcodeLookupBatchItem item,
  ) {
    final itemId = item.itemId.trim();
    final fingerprint = item.fingerprint.trim();
    final itemName = item.itemName.trim();
    if (itemId.isEmpty || fingerprint.isEmpty || itemName.isEmpty) {
      return null;
    }
    return <String, dynamic>{
      'itemId': itemId,
      'fingerprint': fingerprint,
      'itemName': itemName,
      'brand': _normalizeOptionalString(item.brand),
      'storeName': _normalizeOptionalString(item.storeName),
      'weight': _normalizeOptionalString(item.weight),
    };
  }

  int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }
}

/// Calorie barcode backfill repository.
@riverpod
CalorieBarcodeBackfillRepositoryContract calorieBarcodeBackfillRepository(
  Ref ref,
) {
  final authState = ref.watch(authStateChangesProvider);
  final currentUserId = authState.asData?.value?.uid;
  final functions = _resolveFunctions();
  if (functions == null) {
    return const _UnavailableCalorieBarcodeBackfillRepository();
  }
  return FirestoreCalorieBarcodeBackfillRepository(
    session: _CurrentCalorieBarcodeBackfillUserSession(
      currentUserId: currentUserId,
    ),
    functions: functions,
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

FirebaseFunctions? _resolveFunctions() {
  try {
    final functions = FirebaseFunctions.instanceFor(region: _functionsRegion);
    if (_useFunctionsEmulator) {
      final host = _resolveFunctionsEmulatorHost();
      functions.useFunctionsEmulator(host, _functionsEmulatorPort);
      _trace(
        'Functions emulator enabled: '
        '$host:$_functionsEmulatorPort, '
        'region=$_functionsRegion.',
      );
    }
    return functions;
  } on Object catch (error, stackTrace) {
    _trace(
      'Falling back to unavailable barcode backfill repository.',
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

String _resolveFunctionsEmulatorHost() {
  final hostFromDefine = _functionsEmulatorHostFromDefine.trim();
  if (hostFromDefine.isNotEmpty) {
    return hostFromDefine;
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return '10.0.2.2';
  }
  return '127.0.0.1';
}

void _trace(String message, {Object? error, StackTrace? stackTrace}) {
  log(message, name: _backfillLogName, error: error, stackTrace: stackTrace);
  debugPrint('[$_backfillLogName] $message');
  if (error != null) {
    debugPrint('[$_backfillLogName] error=$error');
  }
}

class _UnavailableCalorieBarcodeBackfillRepository
    implements CalorieBarcodeBackfillRepositoryContract {
  const _UnavailableCalorieBarcodeBackfillRepository();

  @override
  Future<bool> enqueueFingerprintLookup({
    required String fingerprint,
    required String itemName,
    required String trigger,
    String? itemId,
    String? brand,
    bool forceRetry = false,
  }) async {
    return false;
  }

  @override
  Future<bool> enqueueBatchLookup({
    required List<BarcodeLookupBatchItem> items,
    required String trigger,
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
