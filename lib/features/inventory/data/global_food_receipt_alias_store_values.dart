import 'package:yamt/features/inventory/domain/global_food_receipt_alias.dart';

/// Aliases saved in one Firestore transaction. Each alias also writes the
/// user's vote: 2 reads and 2 writes per alias.
const int maxReceiptAliasesPerTransaction = 100;

/// Splits alias writes into transaction-sized chunks.
List<List<MapEntry<String, Map<String, dynamic>>>> chunkReceiptAliasEntries(
  List<MapEntry<String, Map<String, dynamic>>> entries,
) {
  final chunks = <List<MapEntry<String, Map<String, dynamic>>>>[];
  for (
    var start = 0;
    start < entries.length;
    start += maxReceiptAliasesPerTransaction
  ) {
    final end = start + maxReceiptAliasesPerTransaction;
    chunks.add(
      entries.sublist(start, end > entries.length ? entries.length : end),
    );
  }
  return chunks;
}

/// A stored counter; missing or invalid values count as 1.
int readReceiptAliasCount(Object? value) {
  if (value is int) {
    return value < 1 ? 1 : value;
  }
  if (value is num) {
    final safeValue = value.toInt();
    return safeValue < 1 ? 1 : safeValue;
  }
  return 1;
}

/// Up to 10 search tokens that are worth an array-contains-any query.
List<String> normalizeReceiptAliasQueryTokens(List<String> tokens) {
  final normalized = <String>{};
  for (final token in tokens) {
    final trimmed = token.trim();
    if (trimmed.length < 3 ||
        RegExp(r'^\d+$').hasMatch(trimmed) ||
        isReceiptAliasNoise(trimmed)) {
      continue;
    }
    normalized.add(trimmed);
    if (normalized.length == 10) {
      break;
    }
  }
  return normalized.toList(growable: false);
}
