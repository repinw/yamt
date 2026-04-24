import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_parsing_utils.dart';

/// The global serving item key prefix.
const String globalServingItemKeyPrefix = 'global';

/// The fingerprint serving item key prefix.
const String fingerprintServingItemKeyPrefix = 'fingerprint';

/// Defines serving size suggestion.
@immutable
class ServingSizeSuggestion {
  /// The serving size suggestion.
  const ServingSizeSuggestion({
    required this.amount,
    required this.unit,
    this.label,
  });

  /// The amount.
  final double amount;

  /// The unit.
  final ConsumedUnit unit;

  /// The user-facing portion label.
  final String? label;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ServingSizeSuggestion &&
            other.amount == amount &&
            other.unit == unit &&
            other.label == label;
  }

  @override
  int get hashCode => Object.hash(amount, unit, label);
}

/// Defines global food serving suggestion.
@immutable
class GlobalFoodServingSuggestion extends ServingSizeSuggestion {
  /// The global food serving suggestion.
  const GlobalFoodServingSuggestion({
    required this.id,
    required this.itemKey,
    required this.selectionCount,
    required this.uniqueUserCount,
    required this.createdAt,
    required this.updatedAt,
    required super.amount,
    required super.unit,
    super.label,
    this.globalFoodItemId,
  });

  /// Creates a [GlobalFoodServingSuggestion] for from json.
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
      label: _readOptionalString(json['label']),
      selectionCount: _readPositiveInt(json['selection_count']) ?? 1,
      uniqueUserCount: _readPositiveInt(json['unique_user_count']) ?? 1,
      createdAt: _readDateTime(json['created_at']) ?? updatedAt,
      updatedAt: updatedAt,
    );
  }

  /// The id.
  final String id;

  /// The item key.
  final String itemKey;

  /// The global food item id.
  final String? globalFoodItemId;

  /// The selection count.
  final int selectionCount;

  /// The unique user count.
  final int uniqueUserCount;

  /// The created at.
  final DateTime createdAt;

  /// The updated at.
  final DateTime updatedAt;

  /// To json.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'item_key': itemKey,
      'global_food_item_id': globalFoodItemId,
      'amount': amount,
      'unit': unit.jsonValue,
      'label': label,
      'selection_count': selectionCount,
      'unique_user_count': uniqueUserCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with.
  GlobalFoodServingSuggestion copyWith({
    String? id,
    String? itemKey,
    Object? globalFoodItemId = _keepValue,
    double? amount,
    ConsumedUnit? unit,
    Object? label = _keepValue,
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
      label: label == _keepValue ? this.label : label as String?,
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
            other.label == label &&
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
      label,
      selectionCount,
      uniqueUserCount,
      createdAt,
      updatedAt,
    );
  }
}

/// Defines global food serving suggestion set.
class GlobalFoodServingSuggestionSet {
  /// The global food serving suggestion set.
  const GlobalFoodServingSuggestionSet({
    this.personalSuggestion,
    this.globalSuggestions = const <GlobalFoodServingSuggestion>[],
  });

  /// Creates a [GlobalFoodServingSuggestionSet] for empty.
  const GlobalFoodServingSuggestionSet.empty()
    : personalSuggestion = null,
      globalSuggestions = const <GlobalFoodServingSuggestion>[];

  /// The personal suggestion.
  final ServingSizeSuggestion? personalSuggestion;

  /// The global suggestions.
  final List<GlobalFoodServingSuggestion> globalSuggestions;

  /// The default suggestion.
  ServingSizeSuggestion? get defaultSuggestion {
    return personalSuggestion ??
        (globalSuggestions.isEmpty ? null : globalSuggestions.first);
  }
}

/// Build global serving item key.
String? buildGlobalServingItemKey(String? globalFoodItemId) {
  final normalizedId = _readOptionalString(globalFoodItemId);
  if (normalizedId == null || isPendingGlobalFoodItemId(normalizedId)) {
    return null;
  }
  return '${globalServingItemKeyPrefix}_$normalizedId';
}

/// Build fingerprint serving item key.
String? buildFingerprintServingItemKey(String? foodFingerprint) {
  final normalized = _readOptionalString(foodFingerprint);
  if (normalized == null) {
    return null;
  }
  return '${fingerprintServingItemKeyPrefix}_$normalized';
}

/// Build serving suggestion document id.
String buildServingSuggestionDocumentId({
  required String itemKey,
  required double amount,
  required ConsumedUnit unit,
}) {
  final amountKey = buildServingSuggestionAmountKey(amount);
  return '${itemKey}_${unit.jsonValue}_$amountKey';
}

/// Build serving suggestion amount key.
int buildServingSuggestionAmountKey(double amount) {
  return (normalizeServingSuggestionAmount(amount) * 1000).round();
}

/// Normalize serving suggestion amount.
double normalizeServingSuggestionAmount(double amount) {
  return ((amount * 1000).roundToDouble()) / 1000;
}

/// Compare serving suggestions.
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
