import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_parsing_utils.dart';

const String globalServingItemKeyPrefix = 'global';
const String fingerprintServingItemKeyPrefix = 'fingerprint';

class ServingSizeSuggestion {
  const ServingSizeSuggestion({required this.amount, required this.unit});

  final double amount;
  final ConsumedUnit unit;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ServingSizeSuggestion &&
            other.amount == amount &&
            other.unit == unit;
  }

  @override
  int get hashCode => Object.hash(amount, unit);
}

class GlobalFoodServingSuggestion extends ServingSizeSuggestion {
  const GlobalFoodServingSuggestion({
    required this.id,
    required this.itemKey,
    required this.selectionCount,
    required this.uniqueUserCount,
    required this.createdAt,
    required this.updatedAt,
    required super.amount,
    required super.unit,
    this.globalFoodItemId,
  });

  factory GlobalFoodServingSuggestion.fromJson(Map<String, dynamic> json) {
    final amount = _readPositiveDouble(json['amount']) ?? 0;
    final unit = ConsumedUnit.fromJsonValue(json['unit'] as String?);
    final updatedAt = _readDateTime(json['updated_at']) ?? DateTime.now();
    return GlobalFoodServingSuggestion(
      id: (json['id'] as String? ?? '').trim(),
      itemKey: (json['item_key'] as String? ?? '').trim(),
      globalFoodItemId: _readOptionalString(json['global_food_item_id']),
      amount: amount,
      unit: unit,
      selectionCount: _readPositiveInt(json['selection_count']) ?? 1,
      uniqueUserCount: _readPositiveInt(json['unique_user_count']) ?? 1,
      createdAt: _readDateTime(json['created_at']) ?? updatedAt,
      updatedAt: updatedAt,
    );
  }

  final String id;
  final String itemKey;
  final String? globalFoodItemId;
  final int selectionCount;
  final int uniqueUserCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'item_key': itemKey,
      'global_food_item_id': globalFoodItemId,
      'amount': amount,
      'unit': unit.jsonValue,
      'selection_count': selectionCount,
      'unique_user_count': uniqueUserCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GlobalFoodServingSuggestion copyWith({
    String? id,
    String? itemKey,
    Object? globalFoodItemId = _keepValue,
    double? amount,
    ConsumedUnit? unit,
    int? selectionCount,
    int? uniqueUserCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GlobalFoodServingSuggestion(
      id: id ?? this.id,
      itemKey: itemKey ?? this.itemKey,
      globalFoodItemId: globalFoodItemId == _keepValue
          ? this.globalFoodItemId
          : globalFoodItemId as String?,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      selectionCount: selectionCount ?? this.selectionCount,
      uniqueUserCount: uniqueUserCount ?? this.uniqueUserCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GlobalFoodServingSuggestion &&
            other.id == id &&
            other.itemKey == itemKey &&
            other.globalFoodItemId == globalFoodItemId &&
            other.amount == amount &&
            other.unit == unit &&
            other.selectionCount == selectionCount &&
            other.uniqueUserCount == uniqueUserCount &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      itemKey,
      globalFoodItemId,
      amount,
      unit,
      selectionCount,
      uniqueUserCount,
      createdAt,
      updatedAt,
    );
  }
}

class GlobalFoodServingSuggestionSet {
  const GlobalFoodServingSuggestionSet({
    this.personalSuggestion,
    this.globalSuggestions = const <GlobalFoodServingSuggestion>[],
  });

  const GlobalFoodServingSuggestionSet.empty()
    : personalSuggestion = null,
      globalSuggestions = const <GlobalFoodServingSuggestion>[];

  final ServingSizeSuggestion? personalSuggestion;
  final List<GlobalFoodServingSuggestion> globalSuggestions;

  ServingSizeSuggestion? get defaultSuggestion {
    return personalSuggestion ??
        (globalSuggestions.isEmpty ? null : globalSuggestions.first);
  }
}

String? buildGlobalServingItemKey(String? globalFoodItemId) {
  final normalizedId = _readOptionalString(globalFoodItemId);
  if (normalizedId == null || isPendingGlobalFoodItemId(normalizedId)) {
    return null;
  }
  return '${globalServingItemKeyPrefix}_$normalizedId';
}

String? buildFingerprintServingItemKey(String? foodFingerprint) {
  final normalized = _readOptionalString(foodFingerprint);
  if (normalized == null) {
    return null;
  }
  return '${fingerprintServingItemKeyPrefix}_$normalized';
}

String buildServingSuggestionDocumentId({
  required String itemKey,
  required double amount,
  required ConsumedUnit unit,
}) {
  return '${itemKey}_${unit.jsonValue}_${buildServingSuggestionAmountKey(amount)}';
}

int buildServingSuggestionAmountKey(double amount) {
  return (normalizeServingSuggestionAmount(amount) * 1000).round();
}

double normalizeServingSuggestionAmount(double amount) {
  return ((amount * 1000).roundToDouble()) / 1000;
}

int compareServingSuggestions(
  GlobalFoodServingSuggestion left,
  GlobalFoodServingSuggestion right,
) {
  final byUsers = right.uniqueUserCount.compareTo(left.uniqueUserCount);
  if (byUsers != 0) {
    return byUsers;
  }
  final byCount = right.selectionCount.compareTo(left.selectionCount);
  if (byCount != 0) {
    return byCount;
  }
  return right.updatedAt.compareTo(left.updatedAt);
}

String? _readOptionalString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

double? _readPositiveDouble(Object? value) {
  final parsed = readPositiveDouble(value);
  if (parsed == null) {
    return null;
  }
  return normalizeServingSuggestionAmount(parsed);
}

int? _readPositiveInt(Object? value) {
  return readPositiveInt(value);
}

DateTime? _readDateTime(Object? value) {
  return readDateTime(value);
}

const Object _keepValue = Object();
