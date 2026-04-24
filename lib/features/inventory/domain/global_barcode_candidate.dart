import 'package:meta/meta.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/core/utils/json_parsing_utils.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';

/// Defines global barcode candidate.
@immutable
class GlobalBarcodeCandidate {
  /// The global barcode candidate.
  const GlobalBarcodeCandidate({
    required this.id,
    required this.barcode,
    required this.globalFoodItemId,
    required this.selectionCount,
    required this.uniqueUserCount,
    required this.completenessScore,
    required this.globalFoodItem,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [GlobalBarcodeCandidate] for from json.
  factory GlobalBarcodeCandidate.fromJson(Map<String, dynamic> json) {
    final globalFoodItemId =
        _readOptionalString(json['global_food_item_id']) ??
        _readOptionalString(json['id']) ??
        '';
    final productJson = readJsonMap(json['global_food_item']);
    if (productJson == null) {
      throw const FormatException('Missing barcode candidate payload.');
    }
    if (_readOptionalString(productJson['id']) == null) {
      productJson['id'] = globalFoodItemId;
    }

    final globalFoodItem = GlobalFoodItem.fromJson(
      productJson,
    ).copyWith(id: globalFoodItemId);
    final updatedAt = readJsonDateTime(json['updated_at']) ?? DateTime.now();
    return GlobalBarcodeCandidate(
      id:
          _readOptionalString(json['id']) ??
          buildGlobalBarcodeCandidateId(
            barcode: json['barcode'] as String? ?? '',
            globalFoodItemId: globalFoodItemId,
          ),
      barcode: normalizeBarcode(json['barcode'] as String? ?? ''),
      globalFoodItemId: globalFoodItemId,
      selectionCount: readJsonPositiveInt(json['selection_count']) ?? 1,
      uniqueUserCount: readJsonPositiveInt(json['unique_user_count']) ?? 1,
      completenessScore:
          readJsonNonNegativeInt(json['completeness_score']) ??
          computeGlobalBarcodeCandidateCompletenessScore(globalFoodItem),
      globalFoodItem: globalFoodItem,
      createdAt: readJsonDateTime(json['created_at']) ?? updatedAt,
      updatedAt: updatedAt,
    );
  }

  /// The id.
  final String id;

  /// The barcode.
  final String barcode;

  /// The global food item id.
  final String globalFoodItemId;

  /// The selection count.
  final int selectionCount;

  /// The unique user count.
  final int uniqueUserCount;

  /// The completeness score.
  final int completenessScore;

  /// The global food item.
  final GlobalFoodItem globalFoodItem;

  /// The created at.
  final DateTime createdAt;

  /// The updated at.
  final DateTime updatedAt;

  /// To json.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'barcode': barcode,
      'global_food_item_id': globalFoodItemId,
      'selection_count': selectionCount,
      'unique_user_count': uniqueUserCount,
      'completeness_score': completenessScore,
      'global_food_item': globalFoodItem.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with.
  GlobalBarcodeCandidate copyWith({
    String? id,
    String? barcode,
    String? globalFoodItemId,
    int? selectionCount,
    int? uniqueUserCount,
    int? completenessScore,
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
      completenessScore: completenessScore ?? this.completenessScore,
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
            other.completenessScore == completenessScore &&
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
      completenessScore,
      globalFoodItem,
      createdAt,
      updatedAt,
    );
  }
}

/// Build global barcode candidate id.
String buildGlobalBarcodeCandidateId({
  required String barcode,
  required String globalFoodItemId,
}) {
  final normalizedBarcode = normalizeBarcode(barcode);
  final normalizedId = globalFoodItemId.trim();
  return 'barcode-$normalizedBarcode-$normalizedId';
}

/// Compare global barcode candidates.
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

/// Compute global barcode candidate completeness score.
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
