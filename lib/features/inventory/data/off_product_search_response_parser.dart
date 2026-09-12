import 'dart:convert';

import 'package:yamt/features/inventory/data/off_product_search_package_weight_resolver.dart';
import 'package:yamt/features/inventory/data/off_product_search_result.dart';
import 'package:yamt/features/inventory/data/off_product_search_text_payload_parser.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

/// Parses OFF search responses from JSON or legacy text payloads.
class OffProductSearchResponseParser {
  /// Creates an OFF product search response parser.
  const OffProductSearchResponseParser({
    this.textPayloadParser = const OffProductSearchTextPayloadParser(),
    this.packageWeightResolver = const OffProductSearchPackageWeightResolver(),
  });

  /// The text payload parser.
  final OffProductSearchTextPayloadParser textPayloadParser;

  /// The package weight resolver.
  final OffProductSearchPackageWeightResolver packageWeightResolver;

  /// Parses an OFF search response body into product search results.
  List<OffProductSearchResult> parse(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return const <OffProductSearchResult>[];
    }

    final decoded = _tryDecodeJson(trimmed);
    if (decoded != null) {
      return _parseJsonPayload(decoded);
    }

    return textPayloadParser.parse(trimmed);
  }

  Object? _tryDecodeJson(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  List<OffProductSearchResult> _parseJsonPayload(Object decoded) {
    final items = _extractJsonItems(decoded);
    return items
        .whereType<Object?>()
        .map(_parseJsonResult)
        .whereType<OffProductSearchResult>()
        .toList(growable: false);
  }

  List<dynamic> _extractJsonItems(Object decoded) {
    return switch (decoded) {
      final List<dynamic> list => list,
      final Map<String, dynamic> map when map['results'] is List<dynamic> =>
        map['results'] as List<dynamic>,
      final Map<String, dynamic> map when map['products'] is List<dynamic> =>
        map['products'] as List<dynamic>,
      final Map<String, dynamic> map when map['items'] is List<dynamic> =>
        map['items'] as List<dynamic>,
      final Map<String, dynamic> map when map['product'] is Map => <dynamic>[
        map['product'],
      ],
      final Map<String, dynamic> map
          when map['code'] != null &&
              (map['name'] != null ||
                  map['product_name'] != null ||
                  map['product_name_de'] != null) =>
        <dynamic>[map],
      _ => const <dynamic>[],
    };
  }

  OffProductSearchResult? _parseJsonResult(Object? rawItem) {
    if (rawItem is! Map) {
      return null;
    }

    final item = Map<String, dynamic>.from(rawItem);
    final code = _readText(item['code'] ?? item['barcode']);
    final name = _readName(item);
    if (code == null || name == null) {
      return null;
    }

    final serving = packageWeightResolver.resolveFromItem(item);

    return OffProductSearchResult(
      code: code,
      name: name,
      brand: _readText(item['brands'] ?? item['brand']),
      imageUrl: _readImageUrl(item),
      packageWeight: serving.packageWeight,
      servingSize: serving.servingSize,
      servingQuantity: serving.servingQuantity,
      servingQuantityUnit: serving.servingQuantityUnit,
      nutrition: _readNutrition(item),
      score: _readScore(item['score'] ?? item['totalScore']) ?? 0,
    );
  }

  String? _readName(Map<String, dynamic> item) {
    return _readText(
      item['product_name'] ??
          item['name'] ??
          item['product_name_de'] ??
          item['generic_name'] ??
          item['generic_name_de'],
    );
  }

  String? _readImageUrl(Map<String, dynamic> item) {
    return _readText(
      item['image_url'] ??
          item['imageUrl'] ??
          item['image_front_url'] ??
          item['image_front_small_url'],
    );
  }

  GlobalFoodNutrition? _readNutrition(Map<String, dynamic> item) {
    final rawNutrition = item['nutrition'] ?? item['nutriments'];
    final nutritionMap = rawNutrition is Map
        ? Map<String, dynamic>.from(rawNutrition)
        : null;

    final qualityStatus = GlobalFoodNutritionQualityStatus.fromJson(
      item['nutrition_quality_status'] ??
          item['quality_status'] ??
          nutritionMap?['quality_status'],
    );

    final nutrition = GlobalFoodNutrition.fromJson(
      nutritionMap ?? item,
      fallback: nutritionMap == null ? null : item,
      qualityStatusOverride:
          qualityStatus == GlobalFoodNutritionQualityStatus.missing
          ? null
          : qualityStatus,
    );

    return nutrition.hasAnyNutritionValue ? nutrition : null;
  }

  String? _readText(Object? value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
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
