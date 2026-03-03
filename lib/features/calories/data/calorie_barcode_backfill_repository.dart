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
const _functionsRegion = 'europe-west1';
const _useFunctionsEmulator = bool.fromEnvironment(
  'USE_FUNCTIONS_EMULATOR',
  defaultValue: false,
);
const _functionsEmulatorHostFromDefine = String.fromEnvironment(
  'FUNCTIONS_EMULATOR_HOST',
  defaultValue: '',
);
const _functionsEmulatorPort = int.fromEnvironment(
  'FUNCTIONS_EMULATOR_PORT',
  defaultValue: 5001,
);

typedef ResolveInventoryItemCallable =
    Future<Map<String, dynamic>?> Function(Map<String, dynamic> payload);

abstract interface class CalorieBarcodeBackfillUserSession {
  String? get currentUserId;
}

class FirestoreCalorieBarcodeBackfillRepository
    implements CalorieBarcodeBackfillRepositoryContract {
  FirestoreCalorieBarcodeBackfillRepository({
    required CalorieBarcodeBackfillUserSession session,
    FirebaseFunctions? functions,
    ResolveInventoryItemCallable? resolveInventoryItemCallable,
  }) : _session = session,
       _functions = functions,
       _resolveInventoryItemCallable = resolveInventoryItemCallable;

  final CalorieBarcodeBackfillUserSession _session;
  final FirebaseFunctions? _functions;
  final ResolveInventoryItemCallable? _resolveInventoryItemCallable;

  @override
  Future<bool> enqueueFingerprintLookup({
    String? itemId,
    required String fingerprint,
    required String itemName,
    String? brand,
    required String trigger,
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
    } catch (error, stackTrace) {
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
    final result = await callable.call(payload);
    final data = result.data;
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    return null;
  }
}

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
  } catch (error, stackTrace) {
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
    String? itemId,
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
