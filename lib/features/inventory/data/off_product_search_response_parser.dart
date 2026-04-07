part of 'off_product_search_repository.dart';

class _OffProductSearchResponseParser {
  const _OffProductSearchResponseParser();

  List<OffProductSearchResult> parse(String body) {
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
      Map<String, dynamic> map when map['product'] is Map => <dynamic>[
        map['product'],
      ],
      Map<String, dynamic> map
          when map['code'] != null &&
              (map['name'] != null || map['product_name'] != null) =>
        <dynamic>[map],
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
      nutrition: _readNutrition(item),
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

  GlobalFoodNutrition? _readNutrition(Map<String, dynamic> item) {
    final rawNutrition = item['nutrition'];
    final nutritionJson = <String, dynamic>{};

    if (rawNutrition is Map) {
      nutritionJson.addAll(Map<String, dynamic>.from(rawNutrition));
    }

    for (final key in const <String>[
      'energy_kcal_100g',
      'energy-kcal_100g',
      'proteins_100g',
      'carbohydrates_100g',
      'fat_100g',
      'salt_100g',
    ]) {
      final value = item[key];
      if (value != null && !nutritionJson.containsKey(key)) {
        nutritionJson[key] = value;
      }
    }

    final qualityStatus = _readText(
      item['nutrition_quality_status'] ?? item['quality_status'],
    );
    if (qualityStatus != null &&
        !nutritionJson.containsKey('quality_status')) {
      nutritionJson['quality_status'] = qualityStatus;
    }

    if (nutritionJson.isEmpty) {
      return null;
    }

    final nutrition = GlobalFoodNutrition.fromJson(
      nutritionJson,
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
