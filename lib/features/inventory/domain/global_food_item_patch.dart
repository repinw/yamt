import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

/// Merge global food item patch.
GlobalFoodItem mergeGlobalFoodItemPatch({
  required GlobalFoodItem currentItem,
  required GlobalFoodItem patchItem,
  required DateTime updatedAt,
}) {
  return currentItem.copyWith(
    brand: currentItem.brand ?? patchItem.brand,
    category: currentItem.category ?? patchItem.category,
    storeName: currentItem.storeName ?? patchItem.storeName,
    barcode: currentItem.barcode ?? patchItem.barcode,
    imageUrl: currentItem.imageUrl ?? patchItem.imageUrl,
    packageWeight: currentItem.packageWeight ?? patchItem.packageWeight,
    servingSize: currentItem.servingSize ?? patchItem.servingSize,
    servingQuantity: currentItem.servingQuantity ?? patchItem.servingQuantity,
    servingQuantityUnit:
        currentItem.servingQuantityUnit ?? patchItem.servingQuantityUnit,
    nutrition: mergeGlobalFoodNutritionPatch(
      currentItem.nutrition,
      patchItem.nutrition,
    ),
    normalizedBrand: _preferMissingString(
      currentItem.normalizedBrand,
      patchItem.normalizedBrand,
    ),
    normalizedStoreName: _preferMissingString(
      currentItem.normalizedStoreName,
      patchItem.normalizedStoreName,
    ),
    updatedAt: updatedAt,
  );
}

/// Merge global food nutrition patch.
GlobalFoodNutrition? mergeGlobalFoodNutritionPatch(
  GlobalFoodNutrition? currentNutrition,
  GlobalFoodNutrition? patchNutrition,
) {
  if (currentNutrition == null) {
    return patchNutrition;
  }
  if (patchNutrition == null) {
    return currentNutrition;
  }

  return currentNutrition.copyWith(
    qualityStatus: _maxNutritionQualityStatus(
      currentNutrition.qualityStatus,
      patchNutrition.qualityStatus,
    ),
    per100Kcal: currentNutrition.per100Kcal ?? patchNutrition.per100Kcal,
    per100Protein:
        currentNutrition.per100Protein ?? patchNutrition.per100Protein,
    per100Carbs: currentNutrition.per100Carbs ?? patchNutrition.per100Carbs,
    per100Fat: currentNutrition.per100Fat ?? patchNutrition.per100Fat,
    per100Salt: currentNutrition.per100Salt ?? patchNutrition.per100Salt,
    per100SaturatedFat:
        currentNutrition.per100SaturatedFat ??
        patchNutrition.per100SaturatedFat,
    per100PolyunsaturatedFat:
        currentNutrition.per100PolyunsaturatedFat ??
        patchNutrition.per100PolyunsaturatedFat,
    per100Sugar: currentNutrition.per100Sugar ?? patchNutrition.per100Sugar,
    per100Fiber: currentNutrition.per100Fiber ?? patchNutrition.per100Fiber,
  );
}

GlobalFoodNutritionQualityStatus _maxNutritionQualityStatus(
  GlobalFoodNutritionQualityStatus left,
  GlobalFoodNutritionQualityStatus right,
) {
  if (left.index >= right.index) {
    return left;
  }
  return right;
}

String? _preferMissingString(String? currentValue, String? patchValue) {
  final normalizedCurrent = _normalizeOptional(currentValue);
  if (normalizedCurrent != null) {
    return normalizedCurrent;
  }
  return _normalizeOptional(patchValue);
}

String? _normalizeOptional(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
