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

/// Calculates a composite quality score for ranking/preferring product results.
int scoreSearchResultQuality(OffProductSearchResult result) {
  var score =
      _nutritionGradeRank(gradeOffProductNutrition(result.nutrition)) * 100;
  score += _knownNutritionValueCount(result.nutrition) * 10;
  if (result.imageUrl != null && result.imageUrl!.trim().isNotEmpty) {
    score += 15;
  }
  if (result.packageWeight != null && result.packageWeight!.trim().isNotEmpty) {
    score += 5;
  }
  if (result.servingSize != null || result.servingQuantity != null) {
    score += 5;
  }
  if (result.globalFoodItemId != null) {
    score += 20;
  }
  return score;
}

/// Merges secondary search result attributes into preferred result without
/// overwriting.
OffProductSearchResult mergeMatchingSearchResults({
  required OffProductSearchResult preferred,
  required OffProductSearchResult secondary,
}) {
  return OffProductSearchResult(
    code: preferred.code,
    name: preferred.name.trim().isNotEmpty ? preferred.name : secondary.name,
    score: math.max(preferred.score, secondary.score),
    brand: preferred.brand ?? secondary.brand,
    imageUrl: (preferred.imageUrl?.trim().isNotEmpty ?? false)
        ? preferred.imageUrl
        : secondary.imageUrl,
    packageWeight: preferred.packageWeight ?? secondary.packageWeight,
    servingSize: preferred.servingSize ?? secondary.servingSize,
    servingQuantity: preferred.servingQuantity ?? secondary.servingQuantity,
    servingQuantityUnit:
        preferred.servingQuantityUnit ?? secondary.servingQuantityUnit,
    nutrition: preferred.nutrition ?? secondary.nutrition,
    globalFoodItemId: preferred.globalFoodItemId ?? secondary.globalFoodItemId,
  );
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
    if (_hasPackageWeightConflict(result, existing)) {
      continue;
    }
    if (_hasNutritionConflict(result.nutrition, existing.nutrition)) {
      continue;
    }

    final candidateScore = scoreSearchResultQuality(result);
    final existingScore = scoreSearchResultQuality(existing);

    if (candidateScore >= existingScore) {
      kept[index] = mergeMatchingSearchResults(
        preferred: result,
        secondary: existing,
      );
      return true;
    } else {
      kept[index] = mergeMatchingSearchResults(
        preferred: existing,
        secondary: result,
      );
      return true;
    }
  }

  return false;
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

  var count = 0;
  if (nutrition.per100Kcal != null) {
    count++;
  }
  if (nutrition.per100Fat != null) {
    count++;
  }
  if (nutrition.per100SaturatedFat != null) {
    count++;
  }
  if (nutrition.per100Carbs != null) {
    count++;
  }
  if (nutrition.per100Sugar != null) {
    count++;
  }
  if (nutrition.per100Protein != null) {
    count++;
  }
  if (nutrition.per100Salt != null) {
    count++;
  }
  if (nutrition.per100PolyunsaturatedFat != null) {
    count++;
  }
  if (nutrition.per100Fiber != null) {
    count++;
  }
  return count;
}
