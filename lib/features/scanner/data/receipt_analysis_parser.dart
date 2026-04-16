import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';

part 'receipt_analysis_parser.g.dart';

/// Receipt analysis parser.
@riverpod
ReceiptAnalysisParser receiptAnalysisParser(Ref ref) {
  return const JsonReceiptAnalysisParser();
}

/// Defines receipt analysis parser.
abstract interface class ReceiptAnalysisParser {
  /// Parse.
  ReceiptAnalysisExtraction parse(String rawResponse);
}

/// Defines json receipt analysis parser.
class JsonReceiptAnalysisParser implements ReceiptAnalysisParser {
  /// The json receipt analysis parser.
  const JsonReceiptAnalysisParser();

  @override
  ReceiptAnalysisExtraction parse(String rawResponse) {
    final payload = _extractJsonPayload(rawResponse);
    if (payload.isEmpty) {
      throw const FormatException('EMPTY_JSON');
    }

    final decoded = jsonDecode(payload);
    return switch (decoded) {
      Map<String, dynamic>() => _parseRootMap(decoded),
      List<dynamic>() => _parseRootList(decoded),
      _ => throw const FormatException('INVALID_ROOT'),
    };
  }

  ReceiptAnalysisExtraction _parseRootMap(Map<String, dynamic> root) {
    final itemsCandidate = root['i'] ?? root['items'];
    final items = _extractItems(itemsCandidate);

    return ReceiptAnalysisExtraction(root: root, items: items);
  }

  ReceiptAnalysisExtraction _parseRootList(List<dynamic> rootList) {
    final items = _extractItems(rootList);
    return ReceiptAnalysisExtraction(
      root: const <String, dynamic>{},
      items: items,
    );
  }

  List<ReceiptAnalysisItem> _extractItems(dynamic rawItems) {
    if (rawItems == null) {
      return const <ReceiptAnalysisItem>[];
    }

    if (rawItems is! List<dynamic>) {
      throw const FormatException('INVALID_ITEMS_CONTAINER');
    }

    final items = <ReceiptAnalysisItem>[];
    for (var index = 0; index < rawItems.length; index++) {
      items.add(_parseItem(rawItems[index], index));
    }

    return items;
  }

  ReceiptAnalysisItem _parseItem(dynamic rawItem, int index) {
    if (rawItem is! Map<String, dynamic>) {
      throw FormatException('INVALID_ITEM_TYPE_AT_$index');
    }

    final itemName = _extractItemName(rawItem);
    if (itemName == null || itemName.isEmpty) {
      throw FormatException('INVALID_ITEM_NAME_AT_$index');
    }

    return ReceiptAnalysisItem(name: itemName, rawPayload: rawItem);
  }

  String? _extractItemName(Map<String, dynamic> rawItem) {
    final minified = rawItem['n'];
    if (minified is String && minified.trim().isNotEmpty) {
      return minified.trim();
    }

    final full = rawItem['name'];
    if (full is String && full.trim().isNotEmpty) {
      return full.trim();
    }

    return null;
  }
}

String _extractJsonPayload(String rawResponse) {
  final trimmed = rawResponse.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final fencedPattern = RegExp(
    r'```(?:json)?\s*(.*?)\s*```',
    dotAll: true,
    caseSensitive: false,
  );
  final fencedMatch = fencedPattern.firstMatch(trimmed);
  if (fencedMatch != null) {
    return fencedMatch.group(1)?.trim() ?? '';
  }

  return trimmed;
}
