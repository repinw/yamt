import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';

class GlobalBarcodeCandidate {
  const GlobalBarcodeCandidate({
    required this.id,
    required this.barcode,
    required this.globalFoodItemId,
    required this.selectionCount,
    required this.uniqueUserCount,
    required this.globalFoodItem,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GlobalBarcodeCandidate.fromJson(Map<String, dynamic> json) {
    final globalFoodItemId =
        _readOptionalString(json['global_food_item_id']) ??
        _readOptionalString(json['id']) ??
        '';
    final productJson = _readMap(json['global_food_item']);
    if (productJson == null) {
      throw const FormatException('Missing barcode candidate payload.');
    }
    if (_readOptionalString(productJson['id']) == null) {
      productJson['id'] = globalFoodItemId;
    }

    final globalFoodItem = GlobalFoodItem.fromJson(
      productJson,
    ).copyWith(id: globalFoodItemId);
    final updatedAt = _readDateTime(json['updated_at']) ?? DateTime.now();
    return GlobalBarcodeCandidate(
      id:
          _readOptionalString(json['id']) ??
          buildGlobalBarcodeCandidateId(
            barcode: json['barcode'] as String? ?? '',
            globalFoodItemId: globalFoodItemId,
          ),
      barcode: normalizeBarcode(json['barcode'] as String? ?? ''),
      globalFoodItemId: globalFoodItemId,
      selectionCount: _readPositiveInt(json['selection_count']) ?? 1,
      uniqueUserCount: _readPositiveInt(json['unique_user_count']) ?? 1,
      globalFoodItem: globalFoodItem,
      createdAt: _readDateTime(json['created_at']) ?? updatedAt,
      updatedAt: updatedAt,
    );
  }

  final String id;
  final String barcode;
  final String globalFoodItemId;
  final int selectionCount;
  final int uniqueUserCount;
  final GlobalFoodItem globalFoodItem;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get completenessScore =>
      computeGlobalBarcodeCandidateCompletenessScore(globalFoodItem);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'barcode': barcode,
      'global_food_item_id': globalFoodItemId,
      'selection_count': selectionCount,
      'unique_user_count': uniqueUserCount,
      'global_food_item': globalFoodItem.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GlobalBarcodeCandidate copyWith({
    String? id,
    String? barcode,
    String? globalFoodItemId,
    int? selectionCount,
    int? uniqueUserCount,
    GlobalFoodItem? globalFoodItem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GlobalBarcodeCandidate(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      globalFoodItemId: globalFoodItemId ?? this.globalFoodItemId,
      selectionCount: selectionCount ?? this.selectionCount,
      uniqueUserCount: uniqueUserCount ?? this.uniqueUserCount,
      globalFoodItem: globalFoodItem ?? this.globalFoodItem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GlobalBarcodeCandidate &&
            other.id == id &&
            other.barcode == barcode &&
            other.globalFoodItemId == globalFoodItemId &&
            other.selectionCount == selectionCount &&
            other.uniqueUserCount == uniqueUserCount &&
            other.globalFoodItem == globalFoodItem &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      barcode,
      globalFoodItemId,
      selectionCount,
      uniqueUserCount,
      globalFoodItem,
      createdAt,
      updatedAt,
    );
  }
}

String buildGlobalBarcodeCandidateId({
  required String barcode,
  required String globalFoodItemId,
}) {
  final normalizedBarcode = normalizeBarcode(barcode);
  final normalizedId = globalFoodItemId.trim();
  return 'barcode-$normalizedBarcode-$normalizedId';
}

int compareGlobalBarcodeCandidates(
  GlobalBarcodeCandidate left,
  GlobalBarcodeCandidate right,
) {
  final byUsers = right.uniqueUserCount.compareTo(left.uniqueUserCount);
  if (byUsers != 0) {
    return byUsers;
  }
  final bySelections = right.selectionCount.compareTo(left.selectionCount);
  if (bySelections != 0) {
    return bySelections;
  }
  final byCompleteness = right.completenessScore.compareTo(
    left.completenessScore,
  );
  if (byCompleteness != 0) {
    return byCompleteness;
  }
  return right.updatedAt.compareTo(left.updatedAt);
}

int computeGlobalBarcodeCandidateCompletenessScore(GlobalFoodItem item) {
  var score = 0;
  if (item.name.trim().isNotEmpty) {
    score += 4;
  }
  if ((item.brand ?? '').trim().isNotEmpty) {
    score += 2;
  }
  if ((item.imageUrl ?? '').trim().isNotEmpty) {
    score += 2;
  }
  if ((item.packageWeight ?? '').trim().isNotEmpty) {
    score += 1;
  }
  if ((item.servingSize ?? '').trim().isNotEmpty) {
    score += 1;
  }
  if (item.servingQuantity != null) {
    score += 1;
  }
  if ((item.servingQuantityUnit ?? '').trim().isNotEmpty) {
    score += 1;
  }
  if (item.nutrition?.hasAnyNutritionValue == true) {
    score += 4;
  }
  return score;
}

Map<String, dynamic>? _readMap(Object? value) {
  if (value is! Map) {
    return null;
  }
  return value.map<String, dynamic>(
    (key, item) => MapEntry<String, dynamic>(key.toString(), item),
  );
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

DateTime? _readDateTime(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value.trim());
}

int? _readPositiveInt(Object? value) {
  if (value is int) {
    return value < 1 ? 1 : value;
  }
  if (value is num) {
    final normalized = value.toInt();
    return normalized < 1 ? 1 : normalized;
  }
  return null;
}
