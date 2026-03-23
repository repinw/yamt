import 'dart:convert';
import 'dart:developer' show log;

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/config/off_product_search_config.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

part 'off_product_search_repository.g.dart';
part 'off_product_search_response_parser.dart';

const _offProductSearchLogName = 'OffProductSearchRepository';

/// A single external OFF search match returned by the search service.
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

/// Looks up candidate products from an external OFF-backed search service.
abstract interface class OffProductSearchRepository {
  Future<List<OffProductSearchResult>> search({
    required String query,
    String? store,
    String? brand,
    String? weight,
    int limit = 15,
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

/// HTTP implementation for the external OFF search service.
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

    try {
      final response = await _client
          .get(uri)
          .timeout(offProductSearchTimeout());
      if (response.statusCode != 200) {
        log(
          'OFF search failed with status ${response.statusCode} '
          'for $uri.',
          name: _offProductSearchLogName,
        );
        return const <OffProductSearchResult>[];
      }

      return _responseParser.parse(response.body);
    } catch (error, stackTrace) {
      log(
        'OFF search request failed for $uri.',
        name: _offProductSearchLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <OffProductSearchResult>[];
    }
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
}
