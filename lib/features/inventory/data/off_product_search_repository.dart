import 'dart:convert';
import 'dart:developer' show log;

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/config/off_product_search_config.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

part 'off_product_search_repository.g.dart';

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
       _searchUri = searchUri;

  final http.Client _client;
  final Uri _searchUri;

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

      return _parseBody(response.body);
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

  List<OffProductSearchResult> _parseBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return const <OffProductSearchResult>[];
    }

    final decoded = _tryDecodeJson(trimmed);
    if (decoded != null) {
      return _parseJsonPayload(decoded);
    }

    return _parseTextPayload(trimmed);
  }

  Object? _tryDecodeJson(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  List<OffProductSearchResult> _parseJsonPayload(Object decoded) {
    final items = switch (decoded) {
      List<dynamic> list => list,
      Map<String, dynamic> map when map['results'] is List<dynamic> =>
        map['results'] as List<dynamic>,
      Map<String, dynamic> map when map['items'] is List<dynamic> =>
        map['items'] as List<dynamic>,
      _ => const <dynamic>[],
    };

    return items
        .whereType<Object?>()
        .map(_parseJsonResult)
        .whereType<OffProductSearchResult>()
        .toList(growable: false);
  }

  OffProductSearchResult? _parseJsonResult(Object? rawItem) {
    if (rawItem is! Map) {
      return null;
    }

    final item = Map<String, dynamic>.from(rawItem);
    final code = _readText(item['code'] ?? item['barcode']);
    final name = _readText(item['product_name'] ?? item['name']);
    if (code == null || name == null) {
      return null;
    }

    return OffProductSearchResult(
      code: code,
      name: name,
      brand: _readText(item['brands'] ?? item['brand']),
      imageUrl: _readText(item['image_url'] ?? item['imageUrl']),
      packageWeight: _readText(
        item['weight'] ?? item['package_weight'] ?? item['quantity'],
      ),
      nutrition: _readNutrition(item['nutrition']),
      score: _readScore(item['score'] ?? item['totalScore']) ?? 0,
    );
  }

  List<OffProductSearchResult> _parseTextPayload(String body) {
    final results = <OffProductSearchResult>[];
    for (final rawLine in const LineSplitter().convert(body)) {
      final line = rawLine.trim();
      if (line.isEmpty || !line.startsWith('Score:')) {
        continue;
      }

      final parts = line.split('|').map((part) => part.trim()).toList();
      if (parts.length < 3) {
        continue;
      }

      final score = _readScore(parts.first.replaceFirst('Score:', '').trim());
      final imageUrl = _parseTextImageUrl(parts.isEmpty ? null : parts.last);
      final codeIndex = imageUrl == null ? parts.length - 2 : parts.length - 3;
      final nameIndex = imageUrl == null ? parts.length - 1 : parts.length - 2;
      if (codeIndex < 1 || nameIndex < 2) {
        continue;
      }

      final code = parts[codeIndex].trim();
      final brandedName = parts[nameIndex].trim();
      final brandedNameMatch = RegExp(
        r'^\[(.*?)\]\s*(.+)$',
      ).firstMatch(brandedName);
      final brand = brandedNameMatch?.group(1)?.trim();
      final name = brandedNameMatch?.group(2)?.trim();
      if (score == null || code.isEmpty || name == null || name.isEmpty) {
        continue;
      }

      results.add(
        OffProductSearchResult(
          code: code,
          name: name,
          brand: brand == null || brand == '?' || brand.isEmpty ? null : brand,
          imageUrl: imageUrl,
          score: score,
        ),
      );
    }

    return results;
  }

  String? _parseTextImageUrl(String? rawValue) {
    final value = rawValue?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    if (_looksLikeImageUrl(value)) {
      return value;
    }

    const imagePrefix = 'image=';
    if (value.startsWith(imagePrefix)) {
      final imageValue = value.substring(imagePrefix.length).trim();
      if (_looksLikeImageUrl(imageValue)) {
        return imageValue;
      }
    }

    return null;
  }

  bool _looksLikeImageUrl(String value) {
    return value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('//') ||
        value.startsWith('/');
  }

  String? _readText(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  GlobalFoodNutrition? _readNutrition(Object? value) {
    if (value is! Map) {
      return null;
    }

    final nutrition = GlobalFoodNutrition.fromJson(
      Map<String, dynamic>.from(value),
    );
    return nutrition.hasAnyNutritionValue ? nutrition : null;
  }

  double? _readScore(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return double.tryParse(raw);
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
