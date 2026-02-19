import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/domain/receipt_analysis_models.dart';

part 'receipt_analysis_parser.g.dart';

@riverpod
ReceiptAnalysisParser receiptAnalysisParser(Ref ref) {
  return const JsonReceiptAnalysisParser();
}

abstract interface class ReceiptAnalysisParser {
  ReceiptAnalysisExtraction parse(String rawResponse);
}

class JsonReceiptAnalysisParser implements ReceiptAnalysisParser {
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

  List<Map<String, dynamic>> _extractItems(dynamic rawItems) {
    if (rawItems is! List<dynamic>) {
      return const <Map<String, dynamic>>[];
    }

    final items = <Map<String, dynamic>>[];
    for (final entry in rawItems) {
      if (entry is Map<String, dynamic>) {
        items.add(entry);
      }
    }

    return items;
  }
}

String _extractJsonPayload(String rawResponse) {
  final trimmed = rawResponse.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final fencedPattern = RegExp(r'```(?:json)?\s*(.*?)\s*```', dotAll: true);
  final fencedMatch = fencedPattern.firstMatch(trimmed);
  if (fencedMatch != null) {
    return fencedMatch.group(1)?.trim() ?? '';
  }

  return trimmed;
}
