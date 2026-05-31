import 'dart:math' as math;

import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/data/off_product_search_result.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';

const _nutritionConflictTolerance = 0.15;
const _nutritionSmallValueTolerance = 0.05;
const _weightParser = InventoryAmountParser();

/// Nutrition grade for external product search results.
enum OffProductNutritionGrade {
  /// No nutrition values are known.
  missing,

  /// Some nutrition exists, but kcal is missing.
  missingCalories,

  /// Kcal exists, but required EU declaration fields are missing.
  incomplete,

  /// Required EU declaration fields exist, but are not community verified.
  complete,

  /// Required EU declaration fields exist and source marks them verified.
  verified,
}

/// Grades nutrition by availability and trust level.
OffProductNutritionGrade gradeOffProductNutrition(
  GlobalFoodNutrition? nutrition,
) {
  if (nutrition?.hasAnyNutritionValue != true) {
    return OffProductNutritionGrade.missing;
  }
  if (nutrition?.per100Kcal == null) {
    return OffProductNutritionGrade.missingCalories;
  }
  if (nutrition?.hasEuMandatoryNutritionDeclaration != true) {
    return OffProductNutritionGrade.incomplete;
  }
  if (nutrition?.qualityStatus == GlobalFoodNutritionQualityStatus.verified) {
    return OffProductNutritionGrade.verified;
  }
  return OffProductNutritionGrade.complete;
}

/// Collapses duplicate OFF rows only when a better same-barcode row is safe.
///
/// A row can hide another row when they share a barcode, package sizes do not
/// conflict, overlapping nutrition values do not conflict, and the replacement
/// has either a better nutrition grade or more known fields in the same grade
/// without losing known nutrition fields.
List<OffProductSearchResult> collapseDominatedOffProductSearchResults(
  List<OffProductSearchResult> results,
) {
  final kept = <OffProductSearchResult>[];

  for (final result in results) {
    if (!_mergeIntoKeptResults(kept, result)) {
      kept.add(result);
    }
  }

  return kept.toList(growable: false);
}

bool _mergeIntoKeptResults(
  List<OffProductSearchResult> kept,
  OffProductSearchResult result,
) {
  final barcode = normalizeBarcode(result.code);
  if (barcode.isEmpty) {
    return false;
  }

  for (var index = 0; index < kept.length; index++) {
    final existing = kept[index];
    if (barcode != normalizeBarcode(existing.code)) {
      continue;
    }
    if (_canSafelyReplace(candidate: result, existing: existing)) {
      kept[index] = result;
      return true;
    }
    if (_canSafelyReplace(candidate: existing, existing: result)) {
      return true;
    }
  }

  return false;
}

bool _canSafelyReplace({
  required OffProductSearchResult candidate,
  required OffProductSearchResult existing,
}) {
  if (_hasPackageWeightConflict(candidate, existing)) {
    return false;
  }
  if (_hasNutritionConflict(candidate.nutrition, existing.nutrition)) {
    return false;
  }

  final candidateRank = _nutritionGradeRank(
    gradeOffProductNutrition(candidate.nutrition),
  );
  final existingRank = _nutritionGradeRank(
    gradeOffProductNutrition(existing.nutrition),
  );
  final candidateKnownValues = _knownNutritionValueCount(candidate.nutrition);
  final existingKnownValues = _knownNutritionValueCount(existing.nutrition);
  if (candidateRank < existingRank) {
    return false;
  }
  if (candidateRank == existingRank) {
    return candidateKnownValues > existingKnownValues;
  }
  return candidateKnownValues >= existingKnownValues;
}

bool _hasPackageWeightConflict(
  OffProductSearchResult left,
  OffProductSearchResult right,
) {
  final leftWeight = _normalizedPackageWeight(left.packageWeight);
  final rightWeight = _normalizedPackageWeight(right.packageWeight);
  return leftWeight != null && rightWeight != null && leftWeight != rightWeight;
}

String? _normalizedPackageWeight(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  final parsed = _weightParser.tryParse(rawWeight: trimmed, quantity: 1);
  if (parsed == null) {
    return trimmed.toLowerCase();
  }
  return '${parsed.amount}${parsed.unit.code}';
}

bool _hasNutritionConflict(
  GlobalFoodNutrition? left,
  GlobalFoodNutrition? right,
) {
  if (left == null || right == null) {
    return false;
  }

  return _hasValueConflict(left.per100Kcal, right.per100Kcal) ||
      _hasValueConflict(left.per100Fat, right.per100Fat) ||
      _hasValueConflict(
        left.per100SaturatedFat,
        right.per100SaturatedFat,
      ) ||
      _hasValueConflict(left.per100Carbs, right.per100Carbs) ||
      _hasValueConflict(left.per100Sugar, right.per100Sugar) ||
      _hasValueConflict(left.per100Protein, right.per100Protein) ||
      _hasValueConflict(left.per100Salt, right.per100Salt) ||
      _hasValueConflict(
        left.per100PolyunsaturatedFat,
        right.per100PolyunsaturatedFat,
      ) ||
      _hasValueConflict(left.per100Fiber, right.per100Fiber);
}

bool _hasValueConflict(double? left, double? right) {
  if (left == null || right == null) {
    return false;
  }

  final difference = (left - right).abs();
  if (difference <= _nutritionSmallValueTolerance) {
    return false;
  }

  final maxValue = math.max(left.abs(), right.abs());
  if (maxValue <= 1) {
    return difference > _nutritionConflictTolerance;
  }
  return difference / maxValue > _nutritionConflictTolerance;
}

int _nutritionGradeRank(OffProductNutritionGrade grade) {
  return switch (grade) {
    OffProductNutritionGrade.missing => 0,
    OffProductNutritionGrade.missingCalories => 1,
    OffProductNutritionGrade.incomplete => 2,
    OffProductNutritionGrade.complete => 3,
    OffProductNutritionGrade.verified => 4,
  };
}

int _knownNutritionValueCount(GlobalFoodNutrition? nutrition) {
  if (nutrition == null) {
    return 0;
  }

  return <double?>[
    nutrition.per100Kcal,
    nutrition.per100Fat,
    nutrition.per100SaturatedFat,
    nutrition.per100Carbs,
    nutrition.per100Sugar,
    nutrition.per100Protein,
    nutrition.per100Salt,
    nutrition.per100PolyunsaturatedFat,
    nutrition.per100Fiber,
  ].where((value) => value != null).length;
}
