import 'dart:convert';
import 'dart:developer' show log;

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/config/off_product_search_config.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

part 'off_product_search_repository.g.dart';
part 'off_product_search_response_parser.dart';

const _offProductSearchLogName = 'OffProductSearchRepository';

class OffProductSearchResult {
  const OffProductSearchResult({
    required this.code,
    required this.name,
    required this.score,
    this.brand,
    this.imageUrl,
    this.packageWeight,
    this.nutrition,
  });

  final String code;
  final String name;
  final double score;
  final String? brand;
  final String? imageUrl;
  final String? packageWeight;
  final GlobalFoodNutrition? nutrition;
}

abstract interface class OffProductSearchRepository {
  Future<List<OffProductSearchResult>> search({
    required String query,
    String? store,
    String? brand,
    String? weight,
    int limit = 15,
  });

  Future<List<OffProductSearchResult>> lookupCandidatesByBarcode({
    required String barcode,
  });
}

@Riverpod(keepAlive: true)
OffProductSearchRepository offProductSearchRepository(Ref ref) {
  final searchUri = resolveOffProductSearchUri();
  if (searchUri == null) {
    return const _UnavailableOffProductSearchRepository();
  }

  final client = http.Client();
  ref.onDispose(client.close);
  return HttpOffProductSearchRepository(client: client, searchUri: searchUri);
}

class HttpOffProductSearchRepository implements OffProductSearchRepository {
  const HttpOffProductSearchRepository({
    required http.Client client,
    required Uri searchUri,
  }) : _client = client,
       _searchUri = searchUri,
       _responseParser = const _OffProductSearchResponseParser();

  final http.Client _client;
  final Uri _searchUri;
  final _OffProductSearchResponseParser _responseParser;

  @override
  Future<List<OffProductSearchResult>> search({
    required String query,
    String? store,
    String? brand,
    String? weight,
    int limit = 15,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return const <OffProductSearchResult>[];
    }

    final uri = _buildSearchUri(
      query: normalizedQuery,
      store: store?.trim(),
      brand: brand?.trim(),
      weight: weight?.trim(),
      limit: limit,
    );
    _debugLogRequest(action: 'search', uri: uri);
    return _fetchResults(uri: uri, action: 'search');
  }

  @override
  Future<List<OffProductSearchResult>> lookupCandidatesByBarcode({
    required String barcode,
  }) async {
    final normalizedBarcode = barcode.trim();
    if (normalizedBarcode.isEmpty) {
      return const <OffProductSearchResult>[];
    }

    final uri = _buildBarcodeUri(barcode: normalizedBarcode);
    _debugLogRequest(action: 'barcode lookup', uri: uri);
    return _fetchResults(uri: uri, action: 'barcode lookup');
  }

  Uri _buildSearchUri({
    required String query,
    required String? store,
    required String? brand,
    required String? weight,
    required int limit,
  }) {
    final queryParameters = <String, String>{
      ..._searchUri.queryParameters,
      'q': query,
      'limit': '$limit',
    };
    if (store != null && store.isNotEmpty) {
      queryParameters['store'] = store;
    }
    if (brand != null && brand.isNotEmpty) {
      queryParameters['brand'] = brand;
    }
    if (weight != null && weight.isNotEmpty) {
      queryParameters['weight'] = weight;
    }

    return _searchUri.replace(queryParameters: queryParameters);
  }

  Uri _buildBarcodeUri({required String barcode}) {
    final pathSegments = _searchUri.pathSegments.toList(growable: true);
    if (pathSegments.isEmpty) {
      pathSegments.add('barcode');
    } else if (pathSegments.last == 'search') {
      pathSegments[pathSegments.length - 1] = 'barcode';
    } else {
      pathSegments.add('barcode');
    }

    return _searchUri.replace(
      pathSegments: pathSegments,
      queryParameters: <String, String>{
        ..._searchUri.queryParameters,
        'code': barcode,
      },
    );
  }

  void _debugLogRequest({required String action, required Uri uri}) {
    assert(() {
      log('OFF $action request: GET $uri', name: _offProductSearchLogName);
      return true;
    }());
  }

  Future<List<OffProductSearchResult>> _fetchResults({
    required Uri uri,
    required String action,
  }) async {
    try {
      final response = await _client
          .get(uri)
          .timeout(offProductSearchTimeout());
      if (response.statusCode != 200) {
        log(
          'OFF $action failed with status ${response.statusCode} for $uri.',
          name: _offProductSearchLogName,
        );
        return const <OffProductSearchResult>[];
      }

      return _responseParser.parse(response.body);
    } catch (error, stackTrace) {
      log(
        'OFF $action request failed for $uri.',
        name: _offProductSearchLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <OffProductSearchResult>[];
    }
  }
}

class _UnavailableOffProductSearchRepository
    implements OffProductSearchRepository {
  const _UnavailableOffProductSearchRepository();

  @override
  Future<List<OffProductSearchResult>> search({
    required String query,
    String? store,
    String? brand,
    String? weight,
    int limit = 15,
  }) async {
    return const <OffProductSearchResult>[];
  }

  @override
  Future<List<OffProductSearchResult>> lookupCandidatesByBarcode({
    required String barcode,
  }) async {
    return const <OffProductSearchResult>[];
  }
}
