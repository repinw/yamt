import 'dart:async';
import 'dart:developer' show log;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/data/calorie_product_image_url.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_lookup_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_barcode_utils.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';

part 'calorie_product_lookup_repository.g.dart';

const _lookupLogName = 'CalorieProductLookupRepository';
const _lookupErrorInvalidBarcode = 'invalid_barcode';
const _lookupErrorRequestFailed = 'off_request_failed';
const _lookupErrorUnavailable = 'off_lookup_unavailable';
const _lookupErrorUnauthenticated = 'unauthenticated';
const _functionsRegion = 'europe-west1';
const _lookupCallableName = 'resolveOffProductByBarcode';
const _lookupCallableTimeout = Duration(seconds: 60);
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

@riverpod
FirebaseFunctions? calorieLookupFunctions(Ref ref) {
  try {
    final functions = FirebaseFunctions.instanceFor(region: _functionsRegion);
    if (_useFunctionsEmulator) {
      final host = _resolveFunctionsEmulatorHost();
      functions.useFunctionsEmulator(host, _functionsEmulatorPort);
      log(
        'Functions emulator enabled for calorie lookup: '
        '$host:$_functionsEmulatorPort (region=$_functionsRegion).',
        name: _lookupLogName,
      );
    }
    return functions;
  } catch (error, stackTrace) {
    log(
      'FirebaseFunctions not available for calorie lookup.',
      name: _lookupLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

@riverpod
CalorieOffLookupClient calorieOffLookupClient(Ref ref) {
  final functions = ref.watch(calorieLookupFunctionsProvider);
  if (functions == null) {
    return const UnavailableCalorieOffLookupClient();
  }
  return FirebaseCallableCalorieOffLookupClient(functions: functions);
}

@riverpod
CalorieProductLookupRepositoryContract calorieProductLookupRepository(Ref ref) {
  return OffBackedCalorieProductLookupRepository(
    cacheRepository: ref.watch(calorieProductCacheRepositoryProvider),
    offLookupClient: ref.watch(calorieOffLookupClientProvider),
  );
}

abstract interface class CalorieOffLookupClient {
  Future<CalorieOffLookupResult> lookupByBarcode(String barcode);
}

enum CalorieOffLookupStatus { found, notFound, failed }

class CalorieOffLookupResult {
  const CalorieOffLookupResult._({
    required this.status,
    this.product,
    this.errorCode,
  });

  final CalorieOffLookupStatus status;
  final CalorieProductProfile? product;
  final String? errorCode;

  const CalorieOffLookupResult.found(CalorieProductProfile product)
    : this._(status: CalorieOffLookupStatus.found, product: product);

  const CalorieOffLookupResult.notFound()
    : this._(status: CalorieOffLookupStatus.notFound);

  const CalorieOffLookupResult.failed({required String errorCode})
    : this._(status: CalorieOffLookupStatus.failed, errorCode: errorCode);
}

class FirebaseCallableCalorieOffLookupClient implements CalorieOffLookupClient {
  const FirebaseCallableCalorieOffLookupClient({
    required FirebaseFunctions functions,
  }) : _functions = functions;

  final FirebaseFunctions _functions;

  @override
  Future<CalorieOffLookupResult> lookupByBarcode(String barcode) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      log(
        'Skipping callable OFF lookup without authenticated Firebase user.',
        name: _lookupLogName,
      );
      return const CalorieOffLookupResult.failed(
        errorCode: _lookupErrorUnauthenticated,
      );
    }

    try {
      final callable = _functions.httpsCallable(
        _lookupCallableName,
        options: HttpsCallableOptions(timeout: _lookupCallableTimeout),
      );
      final result = await callable.call(<String, Object?>{'barcode': barcode});
      final payload = _normalizeStringMap(result.data);
      if (payload == null) {
        return const CalorieOffLookupResult.failed(
          errorCode: _lookupErrorRequestFailed,
        );
      }

      final success = payload['success'] == true;
      final found = payload['found'] == true;
      if (!success) {
        return CalorieOffLookupResult.failed(
          errorCode: _readString(payload['error']) ?? _lookupErrorRequestFailed,
        );
      }

      if (!found) {
        return const CalorieOffLookupResult.notFound();
      }

      final productMap = _normalizeStringMap(payload['product']);
      if (productMap == null) {
        return const CalorieOffLookupResult.failed(
          errorCode: _lookupErrorRequestFailed,
        );
      }

      final normalizedProduct = <String, dynamic>{...productMap};
      normalizedProduct.putIfAbsent(
        'source',
        () => CalorieProductSource.offBarcode.jsonValue,
      );
      final nowIso = DateTime.now().toIso8601String();
      normalizedProduct.putIfAbsent('created_at', () => nowIso);
      normalizedProduct.putIfAbsent('updated_at', () => nowIso);

      final profile = CalorieProductProfile.fromJson(normalizedProduct);
      return CalorieOffLookupResult.found(profile);
    } on FirebaseFunctionsException catch (error, stackTrace) {
      log(
        'Callable OFF lookup failed for barcode $barcode.',
        name: _lookupLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return CalorieOffLookupResult.failed(
        errorCode: error.code.isEmpty ? _lookupErrorRequestFailed : error.code,
      );
    } catch (error, stackTrace) {
      log(
        'Unexpected callable OFF lookup failure for barcode $barcode.',
        name: _lookupLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const CalorieOffLookupResult.failed(
        errorCode: _lookupErrorRequestFailed,
      );
    }
  }

  String? _readString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  Map<String, dynamic>? _normalizeStringMap(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    return raw.map<String, dynamic>(
      (key, value) => MapEntry<String, dynamic>(key.toString(), value),
    );
  }
}

class UnavailableCalorieOffLookupClient implements CalorieOffLookupClient {
  const UnavailableCalorieOffLookupClient();

  @override
  Future<CalorieOffLookupResult> lookupByBarcode(String barcode) async {
    return const CalorieOffLookupResult.failed(
      errorCode: _lookupErrorUnavailable,
    );
  }
}

class OffBackedCalorieProductLookupRepository
    implements CalorieProductLookupRepositoryContract {
  OffBackedCalorieProductLookupRepository({
    required CalorieProductCacheRepositoryContract cacheRepository,
    required CalorieOffLookupClient offLookupClient,
    DateTime Function()? now,
  }) : _cacheRepository = cacheRepository,
       _offLookupClient = offLookupClient,
       _now = now ?? DateTime.now;

  final CalorieProductCacheRepositoryContract _cacheRepository;
  final CalorieOffLookupClient _offLookupClient;
  final DateTime Function() _now;

  @override
  Future<CalorieLookupOutcome> lookupByBarcode(String rawBarcode) async {
    final barcode = normalizeBarcode(rawBarcode);
    if (!isSupportedBarcode(barcode)) {
      return const CalorieLookupOutcome.failed(
        errorCode: _lookupErrorInvalidBarcode,
      );
    }

    CalorieProductProfile? cachedFallback;
    final override = await _cacheRepository.readUserOverride(barcode);
    if (override != null) {
      final normalizedOverride = _normalizeCachedProfile(
        override,
        source: CalorieProductSource.userOverride,
      );
      cachedFallback = normalizedOverride;
      if (_hasUsableImageUrl(normalizedOverride.imageUrl)) {
        return CalorieLookupOutcome.foundSingle(normalizedOverride);
      }
    }

    final global = await _cacheRepository.readGlobalProduct(barcode);
    if (global != null) {
      final normalizedGlobal = _normalizeCachedProfile(
        global,
        source: CalorieProductSource.globalCatalog,
      );
      cachedFallback ??= normalizedGlobal;
      if (_hasUsableImageUrl(normalizedGlobal.imageUrl)) {
        return CalorieLookupOutcome.foundSingle(normalizedGlobal);
      }
    }

    final remote = await _offLookupClient.lookupByBarcode(barcode);
    switch (remote.status) {
      case CalorieOffLookupStatus.found:
        final remoteProfile = remote.product;
        if (remoteProfile == null) {
          if (cachedFallback != null) {
            return CalorieLookupOutcome.foundSingle(cachedFallback);
          }
          return const CalorieLookupOutcome.failed(
            errorCode: _lookupErrorRequestFailed,
          );
        }
        final normalizedRemote = _normalizeCachedProfile(
          remoteProfile,
          source: remoteProfile.source,
        );
        return CalorieLookupOutcome.foundSingle(normalizedRemote);
      case CalorieOffLookupStatus.notFound:
        if (cachedFallback != null) {
          return CalorieLookupOutcome.foundSingle(cachedFallback);
        }
        return const CalorieLookupOutcome.notFound();
      case CalorieOffLookupStatus.failed:
        if (cachedFallback != null) {
          return CalorieLookupOutcome.foundSingle(cachedFallback);
        }
        return CalorieLookupOutcome.failed(
          errorCode: remote.errorCode ?? _lookupErrorRequestFailed,
        );
    }
  }

  @override
  Future<bool> persistGlobalProduct(CalorieProductProfile profile) {
    final globalProfile = profile.copyWith(
      source: CalorieProductSource.globalCatalog,
      updatedAt: _now(),
    );
    return _cacheRepository.saveGlobalProduct(globalProfile);
  }

  bool _hasUsableImageUrl(String? value) {
    return normalizeCalorieProductImageUrl(value) != null;
  }

  CalorieProductProfile _normalizeCachedProfile(
    CalorieProductProfile profile, {
    required CalorieProductSource source,
  }) {
    return profile.copyWith(
      source: source,
      imageUrl: normalizeCalorieProductImageUrl(profile.imageUrl),
    );
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
