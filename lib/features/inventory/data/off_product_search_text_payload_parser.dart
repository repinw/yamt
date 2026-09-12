import 'dart:convert';

import 'package:yamt/features/inventory/data/off_product_search_result.dart';

/// Parses legacy text payloads from OFF search responses.
class OffProductSearchTextPayloadParser {
  /// Creates an OFF text payload parser.
  const OffProductSearchTextPayloadParser();

  /// Parses text lines starting with "Score:" into search results.
  List<OffProductSearchResult> parse(String body) {
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
