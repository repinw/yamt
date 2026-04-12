import 'dart:convert';

import 'package:yamt/core/utils/store_name_normalizer.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';

/// Learns how a store-specific OCR receipt name maps to a global food item.
class GlobalFoodReceiptAlias {
  const GlobalFoodReceiptAlias({
    required this.id,
    required this.globalFoodItemId,
    required this.storeName,
    required this.normalizedStoreName,
    required this.receiptName,
    required this.normalizedReceiptName,
    required this.compactReceiptName,
    required this.receiptSearchTokens,
    required this.lookupKey,
    required this.selectionCount,
    required this.globalFoodItem,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Builds a persistable alias or returns `null` when the lookup key would
  /// be too weak, for example without a usable store or OCR name.
  static GlobalFoodReceiptAlias? tryCreate({
    required String storeName,
    required String receiptName,
    required GlobalFoodItem globalFoodItem,
    required DateTime now,
  }) {
    final normalizedStoreName = normalizeGlobalFoodReceiptAliasStoreName(
      storeName,
    );
    final normalizedReceiptName = normalizeGlobalFoodReceiptObservedName(
      receiptName,
    );
    final safeStoreName = normalizeStoreName(storeName);
    final safeReceiptName = receiptName.trim();
    final safeGlobalFoodItemId = globalFoodItem.id.trim();
    if (normalizedStoreName == null ||
        normalizedReceiptName == null ||
        safeStoreName == null ||
        safeReceiptName.isEmpty ||
        safeGlobalFoodItemId.isEmpty) {
      return null;
    }

    return GlobalFoodReceiptAlias(
      id: buildGlobalFoodReceiptAliasId(
        normalizedStoreName: normalizedStoreName,
        normalizedReceiptName: normalizedReceiptName,
        globalFoodItemId: safeGlobalFoodItemId,
      ),
      globalFoodItemId: safeGlobalFoodItemId,
      storeName: safeStoreName,
      normalizedStoreName: normalizedStoreName,
      receiptName: safeReceiptName,
      normalizedReceiptName: normalizedReceiptName,
      compactReceiptName: compactGlobalFoodReceiptAliasText(
        normalizedReceiptName,
      ),
      receiptSearchTokens: buildGlobalFoodReceiptAliasSearchTokens(
        safeReceiptName,
      ),
      lookupKey: buildGlobalFoodReceiptAliasLookupKey(
        normalizedStoreName: normalizedStoreName,
        normalizedReceiptName: normalizedReceiptName,
      ),
      selectionCount: 1,
      globalFoodItem: globalFoodItem,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory GlobalFoodReceiptAlias.fromJson(Map<String, dynamic> json) {
    final globalFoodItemId = (json['global_food_item_id'] as String? ?? '')
        .trim();
    final globalFoodItemJson = _readMap(json['global_food_item']);
    if (globalFoodItemJson == null) {
      throw const FormatException('Missing alias global food item payload.');
    }

    if ((globalFoodItemJson['id'] as String?)?.trim().isEmpty ?? true) {
      globalFoodItemJson['id'] = globalFoodItemId;
    }

    final globalFoodItem = GlobalFoodItem.fromJson(
      globalFoodItemJson,
    ).copyWith(id: globalFoodItemId);
    final storeName = normalizeStoreName(json['store_name'] as String?);
    final receiptName = (json['receipt_name'] as String? ?? '').trim();
    final normalizedStoreName =
        (json['normalized_store_name'] as String?)?.trim() ??
        normalizeGlobalFoodReceiptAliasStoreName(storeName);
    final normalizedReceiptName =
        (json['normalized_receipt_name'] as String?)?.trim() ??
        normalizeGlobalFoodReceiptObservedName(receiptName);
    if (normalizedStoreName == null || normalizedReceiptName == null) {
      throw const FormatException('Missing alias lookup fields.');
    }

    return GlobalFoodReceiptAlias(
      id: (json['id'] as String? ?? '').trim(),
      globalFoodItemId: globalFoodItemId,
      storeName: storeName ?? '',
      normalizedStoreName: normalizedStoreName,
      receiptName: receiptName,
      normalizedReceiptName: normalizedReceiptName,
      compactReceiptName:
          (json['compact_receipt_name'] as String?)?.trim() ??
          compactGlobalFoodReceiptAliasText(normalizedReceiptName),
      receiptSearchTokens:
          _readStringList(json['receipt_search_tokens']) ??
          buildGlobalFoodReceiptAliasSearchTokens(receiptName),
      lookupKey:
          (json['lookup_key'] as String?)?.trim() ??
          buildGlobalFoodReceiptAliasLookupKey(
            normalizedStoreName: normalizedStoreName,
            normalizedReceiptName: normalizedReceiptName,
          ),
      selectionCount: _readSelectionCount(json['selection_count']),
      globalFoodItem: globalFoodItem,
      createdAt: _readDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt:
          _readDateTime(json['updated_at']) ??
          _readDateTime(json['created_at']) ??
          DateTime.now(),
    );
  }

  final String id;
  final String globalFoodItemId;
  final String storeName;
  final String normalizedStoreName;
  final String receiptName;
  final String normalizedReceiptName;
  final String compactReceiptName;
  final List<String> receiptSearchTokens;
  final String lookupKey;
  final int selectionCount;
  final GlobalFoodItem globalFoodItem;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'global_food_item_id': globalFoodItemId,
      'store_name': storeName,
      'normalized_store_name': normalizedStoreName,
      'receipt_name': receiptName,
      'normalized_receipt_name': normalizedReceiptName,
      'compact_receipt_name': compactReceiptName,
      'receipt_search_tokens': receiptSearchTokens,
      'lookup_key': lookupKey,
      'selection_count': selectionCount,
      'global_food_item': globalFoodItem.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GlobalFoodReceiptAlias copyWith({
    String? id,
    String? globalFoodItemId,
    String? storeName,
    String? normalizedStoreName,
    String? receiptName,
    String? normalizedReceiptName,
    String? compactReceiptName,
    List<String>? receiptSearchTokens,
    String? lookupKey,
    int? selectionCount,
    GlobalFoodItem? globalFoodItem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GlobalFoodReceiptAlias(
      id: id ?? this.id,
      globalFoodItemId: globalFoodItemId ?? this.globalFoodItemId,
      storeName: storeName ?? this.storeName,
      normalizedStoreName: normalizedStoreName ?? this.normalizedStoreName,
      receiptName: receiptName ?? this.receiptName,
      normalizedReceiptName:
          normalizedReceiptName ?? this.normalizedReceiptName,
      compactReceiptName: compactReceiptName ?? this.compactReceiptName,
      receiptSearchTokens: receiptSearchTokens ?? this.receiptSearchTokens,
      lookupKey: lookupKey ?? this.lookupKey,
      selectionCount: selectionCount ?? this.selectionCount,
      globalFoodItem: globalFoodItem ?? this.globalFoodItem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GlobalFoodReceiptAlias &&
            other.id == id &&
            other.globalFoodItemId == globalFoodItemId &&
            other.storeName == storeName &&
            other.normalizedStoreName == normalizedStoreName &&
            other.receiptName == receiptName &&
            other.normalizedReceiptName == normalizedReceiptName &&
            other.compactReceiptName == compactReceiptName &&
            _stringListsEqual(other.receiptSearchTokens, receiptSearchTokens) &&
            other.lookupKey == lookupKey &&
            other.selectionCount == selectionCount &&
            other.globalFoodItem == globalFoodItem &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      globalFoodItemId,
      storeName,
      normalizedStoreName,
      receiptName,
      normalizedReceiptName,
      compactReceiptName,
      Object.hashAll(receiptSearchTokens),
      lookupKey,
      selectionCount,
      globalFoodItem,
      createdAt,
      updatedAt,
    );
  }
}

String? normalizeGlobalFoodReceiptAliasStoreName(String? rawValue) {
  final safeStoreName = normalizeStoreName(rawValue);
  if (safeStoreName == null || safeStoreName == 'Unknown') {
    return null;
  }
  final normalized = normalizeGlobalFoodReceiptAliasText(safeStoreName);
  if (normalized.isEmpty) {
    return null;
  }
  return normalized;
}

String? normalizeGlobalFoodReceiptObservedName(String? rawValue) {
  final trimmed = rawValue?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  final normalized = normalizeGlobalFoodReceiptAliasText(trimmed);
  if (normalized.isEmpty) {
    return null;
  }
  return normalized;
}

String normalizeGlobalFoodReceiptAliasText(String rawValue) {
  final lower = rawValue.trim().toLowerCase();
  if (lower.isEmpty) {
    return '';
  }

  return lower
      .replaceAll('ß', 'ss')
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String compactGlobalFoodReceiptAliasText(String rawValue) {
  return rawValue.replaceAll(' ', '');
}

List<String> buildGlobalFoodReceiptAliasSearchTokens(String rawValue) {
  final normalized = normalizeGlobalFoodReceiptAliasText(rawValue);
  if (normalized.isEmpty) {
    return const <String>[];
  }

  final tokens = <String>{
    normalized,
    compactGlobalFoodReceiptAliasText(normalized),
    ...normalized.split(' ').where((token) => token.isNotEmpty),
  };
  return tokens.toList(growable: false);
}

String buildGlobalFoodReceiptAliasLookupKey({
  required String normalizedStoreName,
  required String normalizedReceiptName,
}) {
  return '$normalizedStoreName|$normalizedReceiptName';
}

String buildGlobalFoodReceiptAliasId({
  required String normalizedStoreName,
  required String normalizedReceiptName,
  required String globalFoodItemId,
}) {
  final rawValue = [
    normalizedStoreName,
    normalizedReceiptName,
    globalFoodItemId.trim(),
  ].join('|');
  final encoded = base64Url.encode(utf8.encode(rawValue)).replaceAll('=', '');
  return 'receipt-alias-$encoded';
}

Map<String, dynamic>? _readMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }
  if (value is Map) {
    return Map<String, dynamic>.fromEntries(
      value.entries.map(
        (entry) => MapEntry<String, dynamic>(entry.key.toString(), entry.value),
      ),
    );
  }
  return null;
}

DateTime? _readDateTime(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value.trim());
  }
  return null;
}

int _readSelectionCount(Object? value) {
  if (value is int) {
    return value < 1 ? 1 : value;
  }
  if (value is num) {
    final safeValue = value.toInt();
    return safeValue < 1 ? 1 : safeValue;
  }
  return 1;
}

List<String>? _readStringList(Object? value) {
  if (value is! List) {
    return null;
  }
  return value
      .whereType<String>()
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

bool _stringListsEqual(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
