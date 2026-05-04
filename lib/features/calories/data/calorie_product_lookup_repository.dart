// Lookup client stays class-based for provider overrides and test fakes.
// ignore_for_file: one_member_abstracts

import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log;

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
import 'package:yamt/features/calories/data/calorie_product_image_url.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_lookup_repository_contract.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';

part 'calorie_product_lookup_repository.g.dart';

const _lookupLogName = 'CalorieProductLookupRepository';
const _lookupErrorInvalidBarcode = 'invalid_barcode';
const _lookupErrorRequestFailed = 'off_request_failed';
const _offHost = 'world.openfoodfacts.org';
const _offUserAgent = 'YAMT/1.0 (repin@mailbox.org)';
const _offRequestTimeout = Duration(seconds: 12);
const _offFields =
    'code,product_name,brands,nutriments,status,'
    'image_front_small_url,image_front_url,image_url,selected_images';

/// Calorie off lookup client.
@riverpod
CalorieOffLookupClient calorieOffLookupClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return HttpCalorieOffLookupClient(client: client);
}

/// Calorie product lookup repository.
@riverpod
CalorieProductLookupRepositoryContract calorieProductLookupRepository(Ref ref) {
  return OffBackedCalorieProductLookupRepository(
    cacheRepository: ref.watch(calorieProductCacheRepositoryProvider),
    offLookupClient: ref.watch(calorieOffLookupClientProvider),
  );
}

/// Defines calorie off lookup client.
abstract interface class CalorieOffLookupClient {
  /// Lookup by barcode.
  Future<CalorieOffLookupResult> lookupByBarcode(String barcode);
}

/// Defines calorie off lookup status.
enum CalorieOffLookupStatus {
  /// Found.
  found,

  /// Not found.
  notFound,

  /// Failed.
  failed,
}

/// Defines calorie off lookup result.
class CalorieOffLookupResult {
  /// Creates a [CalorieOffLookupResult] for found.
  const CalorieOffLookupResult.found(CalorieProductProfile product)
    : this._(status: CalorieOffLookupStatus.found, product: product);

  /// Creates a [CalorieOffLookupResult] for not found.
  const CalorieOffLookupResult.notFound()
    : this._(status: CalorieOffLookupStatus.notFound);

  /// Creates a [CalorieOffLookupResult] for failed.
  const CalorieOffLookupResult.failed({required String errorCode})
    : this._(status: CalorieOffLookupStatus.failed, errorCode: errorCode);
  const CalorieOffLookupResult._({
    required this.status,
    this.product,
    this.errorCode,
  });

  /// The status.
  final CalorieOffLookupStatus status;

  /// The product.
  final CalorieProductProfile? product;

  /// The error code.
  final String? errorCode;
}

/// HTTP-backed Open Food Facts lookup client.
class HttpCalorieOffLookupClient implements CalorieOffLookupClient {
  /// Creates a client.
  const HttpCalorieOffLookupClient({required http.Client client})
    : _client = client;

  final http.Client _client;

  @override
  Future<CalorieOffLookupResult> lookupByBarcode(String barcode) async {
    final uri = Uri.https(
      _offHost,
      '/api/v2/product/$barcode.json',
      <String, String>{'fields': _offFields},
    );
    try {
      final response = await _client
          .get(
            uri,
            headers: const <String, String>{'User-Agent': _offUserAgent},
          )
          .timeout(_offRequestTimeout);
      if (response.statusCode == 404) {
        return const CalorieOffLookupResult.notFound();
      }
      if (response.statusCode != 200) {
        return const CalorieOffLookupResult.failed(
          errorCode: _lookupErrorRequestFailed,
        );
      }

      final payload = _normalizeStringMap(jsonDecode(response.body));
      if (payload == null) {
        return const CalorieOffLookupResult.failed(
          errorCode: _lookupErrorRequestFailed,
        );
      }

      if (payload['status'] != 1 && payload['status'] != true) {
        return const CalorieOffLookupResult.notFound();
      }
      final productMap = _normalizeStringMap(payload['product']);
      if (productMap == null) {
        return const CalorieOffLookupResult.failed(
          errorCode: _lookupErrorRequestFailed,
        );
      }

      final profile = _parseProduct(
        barcode: barcode,
        product: productMap,
        now: DateTime.now(),
      );
      if (profile == null) {
        return const CalorieOffLookupResult.failed(
          errorCode: _lookupErrorRequestFailed,
        );
      }
      return CalorieOffLookupResult.found(profile);
    } on Object catch (error, stackTrace) {
      log(
        'Open Food Facts lookup failed for barcode $barcode.',
        name: _lookupLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const CalorieOffLookupResult.failed(
        errorCode: _lookupErrorRequestFailed,
      );
    }
  }

  CalorieProductProfile? _parseProduct({
    required String barcode,
    required Map<String, dynamic> product,
    required DateTime now,
  }) {
    final nutriments = _normalizeStringMap(product['nutriments']);
    final name = _readString(product['product_name']) ?? barcode;
    final per100Kcal = _readDouble(
      _readNutritionValue(
        nutriments: nutriments,
        product: product,
        keys: const <String>[
          'energy-kcal_100g',
          'energy_kcal_100g',
          'energy-kcal_100ml',
          'energy_kcal_100ml',
        ],
      ),
    );
    if (per100Kcal == null) {
      return null;
    }

    return CalorieProductProfile(
      barcode: _readString(product['code']) ?? barcode,
      name: name,
      brand: _readString(product['brands']),
      per100Kcal: per100Kcal,
      per100Protein:
          _readDouble(
            _readNutritionValue(
              nutriments: nutriments,
              product: product,
              keys: const <String>['proteins_100g', 'proteins_100ml'],
            ),
          ) ??
          0,
      per100Carbs:
          _readDouble(
            _readNutritionValue(
              nutriments: nutriments,
              product: product,
              keys: const <String>[
                'carbohydrates_100g',
                'carbohydrates_100ml',
              ],
            ),
          ) ??
          0,
      per100Fat:
          _readDouble(
            _readNutritionValue(
              nutriments: nutriments,
              product: product,
              keys: const <String>['fat_100g', 'fat_100ml'],
            ),
          ) ??
          0,
      source: CalorieProductSource.offBarcode,
      offProductId: _readString(product['_id']) ?? _readString(product['code']),
      imageUrl: _readImageUrl(product),
      createdAt: now,
      updatedAt: now,
    );
  }

  Object? _readNutritionValue({
    required Map<String, dynamic>? nutriments,
    required Map<String, dynamic> product,
    required List<String> keys,
  }) {
    for (final key in keys) {
      final value = nutriments?[key] ?? product[key];
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  String? _readImageUrl(Map<String, dynamic> product) {
    return _readString(product['image_front_small_url']) ??
        _readString(product['image_front_url']) ??
        _readString(product['image_url']) ??
        _readSelectedImageUrl(product['selected_images']);
  }

  String? _readSelectedImageUrl(Object? rawValue) {
    final selectedImages = _normalizeStringMap(rawValue);
    final front = _normalizeStringMap(selectedImages?['front']);
    for (final size in const <String>['small', 'display', 'thumb']) {
      final localized = _normalizeStringMap(front?[size]);
      final imageUrl =
          _readString(localized?['de']) ??
          _readString(localized?['en']) ??
          _firstStringValue(localized);
      if (imageUrl != null) {
        return imageUrl;
      }
    }
    return null;
  }

  String? _firstStringValue(Map<String, dynamic>? value) {
    if (value == null) {
      return null;
    }
    for (final entry in value.values) {
      final text = _readString(entry);
      if (text != null) {
        return text;
      }
    }
    return null;
  }

  double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return double.tryParse(raw.replaceAll(',', '.'));
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

/// Defines off backed calorie product lookup repository.
class OffBackedCalorieProductLookupRepository
    implements CalorieProductLookupRepositoryContract {
  /// Creates an instance.
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
