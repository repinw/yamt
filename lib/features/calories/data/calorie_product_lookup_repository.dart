import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log;

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_lookup_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_barcode_utils.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';

part 'calorie_product_lookup_repository.g.dart';

const _lookupLogName = 'CalorieProductLookupRepository';
const _offBaseUrl = 'world.openfoodfacts.org';
const _lookupErrorInvalidBarcode = 'invalid_barcode';
const _lookupErrorRequestFailed = 'off_request_failed';
const _offLookupTimeout = Duration(seconds: 10);

@riverpod
http.Client calorieLookupHttpClient(Ref ref) {
  return http.Client();
}

@riverpod
CalorieProductLookupRepositoryContract calorieProductLookupRepository(Ref ref) {
  return OffBackedCalorieProductLookupRepository(
    cacheRepository: ref.watch(calorieProductCacheRepositoryProvider),
    httpClient: ref.watch(calorieLookupHttpClientProvider),
  );
}

class OffBackedCalorieProductLookupRepository
    implements CalorieProductLookupRepositoryContract {
  OffBackedCalorieProductLookupRepository({
    required CalorieProductCacheRepositoryContract cacheRepository,
    required http.Client httpClient,
    Duration requestTimeout = _offLookupTimeout,
    DateTime Function()? now,
  }) : _cacheRepository = cacheRepository,
       _httpClient = httpClient,
       _requestTimeout = requestTimeout,
       _now = now ?? DateTime.now;

  final CalorieProductCacheRepositoryContract _cacheRepository;
  final http.Client _httpClient;
  final Duration _requestTimeout;
  final DateTime Function() _now;

  @override
  Future<CalorieLookupOutcome> lookupByBarcode(String rawBarcode) async {
    final barcode = normalizeBarcode(rawBarcode);
    if (!isSupportedBarcode(barcode)) {
      return const CalorieLookupOutcome.failed(
        errorCode: _lookupErrorInvalidBarcode,
      );
    }

    final override = await _cacheRepository.readUserOverride(barcode);
    if (override != null) {
      return CalorieLookupOutcome.foundSingle(
        override.copyWith(source: CalorieProductSource.userOverride),
      );
    }

    final global = await _cacheRepository.readGlobalProduct(barcode);
    if (global != null) {
      return CalorieLookupOutcome.foundSingle(
        global.copyWith(source: CalorieProductSource.globalCatalog),
      );
    }

    try {
      final exactMatch = await _fetchByBarcode(barcode);
      if (exactMatch != null) {
        await persistGlobalProduct(exactMatch);
        return CalorieLookupOutcome.foundSingle(exactMatch);
      }

      final candidates = await _searchCandidates(barcode);
      if (candidates.isEmpty) {
        return const CalorieLookupOutcome.notFound();
      }

      if (candidates.length == 1) {
        final profile = candidates.single.profile;
        await persistGlobalProduct(profile);
        return CalorieLookupOutcome.foundSingle(profile);
      }

      return CalorieLookupOutcome.foundMultiple(candidates);
    } catch (error, stackTrace) {
      final isTimeout = error is TimeoutException;
      final message = isTimeout
          ? 'OFF lookup timed out for barcode $barcode.'
          : 'OFF lookup failed for barcode $barcode.';
      log(message, name: _lookupLogName, error: error, stackTrace: stackTrace);
      return const CalorieLookupOutcome.failed(
        errorCode: _lookupErrorRequestFailed,
      );
    }
  }

  @override
  Future<bool> persistGlobalProduct(CalorieProductProfile profile) {
    return _cacheRepository.saveGlobalProduct(
      profile.copyWith(updatedAt: _now()),
    );
  }

  Future<CalorieProductProfile?> _fetchByBarcode(String barcode) async {
    final uri = Uri.https(
      _offBaseUrl,
      '/api/v2/product/$barcode.json',
      const <String, String>{
        'fields': '_id,code,product_name,brands,nutriments,status',
      },
    );
    final response = await _httpClient.get(uri).timeout(_requestTimeout);
    if (response.statusCode != 200) {
      return null;
    }

    final payload = _decodeJsonObject(response.body);
    if (payload == null) {
      return null;
    }

    final status = payload['status'];
    if (status is num && status.toInt() == 0) {
      return null;
    }

    final product = payload['product'];
    if (product is! Map<String, dynamic>) {
      return null;
    }

    return _profileFromOffProduct(
      barcode: barcode,
      product: product,
      source: CalorieProductSource.offBarcode,
    );
  }

  Future<List<CalorieProductCandidate>> _searchCandidates(
    String barcode,
  ) async {
    final uri = Uri.https(_offBaseUrl, '/cgi/search.pl', <String, String>{
      'search_terms': barcode,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page_size': '20',
      'fields': '_id,code,product_name,brands,nutriments',
    });
    final response = await _httpClient.get(uri).timeout(_requestTimeout);
    if (response.statusCode != 200) {
      return const <CalorieProductCandidate>[];
    }

    final payload = _decodeJsonObject(response.body);
    final rawProducts = payload?['products'];
    if (rawProducts is! List) {
      return const <CalorieProductCandidate>[];
    }

    final profiles = <CalorieProductProfile>[];
    for (final rawProduct in rawProducts) {
      if (rawProduct is! Map<String, dynamic>) {
        continue;
      }
      final code = _readString(rawProduct['code']) ?? barcode;
      final profile = _profileFromOffProduct(
        barcode: code,
        product: rawProduct,
        source: CalorieProductSource.offSearch,
      );
      if (profile != null) {
        profiles.add(profile);
      }
    }

    if (profiles.isEmpty) {
      return const <CalorieProductCandidate>[];
    }

    final uniqueByKey = <String, CalorieProductProfile>{};
    for (final profile in profiles) {
      final key =
          '${profile.name.toLowerCase()}::'
          '${profile.brand?.toLowerCase() ?? ''}';
      uniqueByKey.putIfAbsent(key, () => profile);
    }
    return rankCalorieCandidates(uniqueByKey.values);
  }

  CalorieProductProfile? _profileFromOffProduct({
    required String barcode,
    required Map<String, dynamic> product,
    required CalorieProductSource source,
  }) {
    final name = _readString(product['product_name'])?.trim() ?? '';
    final brand = _readString(product['brands'])?.trim();
    final offProductId = _readString(product['_id']);

    final nutriments = product['nutriments'] is Map<String, dynamic>
        ? product['nutriments'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final per100Kcal = _readDouble(
      nutriments['energy-kcal_100g'] ?? nutriments['energy-kcal_100ml'],
    );
    final per100Protein = _readDouble(
      nutriments['proteins_100g'] ?? nutriments['proteins_100ml'],
    );
    final per100Carbs = _readDouble(
      nutriments['carbohydrates_100g'] ?? nutriments['carbohydrates_100ml'],
    );
    final per100Fat = _readDouble(
      nutriments['fat_100g'] ?? nutriments['fat_100ml'],
    );

    if (name.isEmpty && per100Kcal <= 0) {
      return null;
    }

    final now = _now();
    return CalorieProductProfile(
      barcode: barcode,
      name: name.isEmpty ? barcode : name,
      brand: brand?.isEmpty == true ? null : brand,
      per100Kcal: per100Kcal,
      per100Protein: per100Protein,
      per100Carbs: per100Carbs,
      per100Fat: per100Fat,
      source: source,
      offProductId: offProductId,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic>? _decodeJsonObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return null;
  }

  String? _readString(Object? value) {
    if (value is String) {
      return value;
    }
    return null;
  }

  double _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.').trim()) ?? 0;
    }
    return 0;
  }
}
