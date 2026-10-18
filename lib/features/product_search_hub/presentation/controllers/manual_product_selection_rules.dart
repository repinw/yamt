import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_item_edit_policy.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';

// Pure rules of the manual product editor that need no controller state.

const _tolerance = 0.000001;

/// Whether saving [selection] writes to the shared catalog.
bool manualProductRequiresGlobalPersistence({
  required InventoryReceiptManualProductSelection? selection,
  required GlobalFoodItemEditKind editKind,
  required bool aiEstimated,
}) {
  // An AI estimate stays the user's own, also after an edit (#701).
  if (aiEstimated) {
    return false;
  }
  if (selection == null) {
    return true;
  }
  if (selection.externalProduct != null) {
    return true;
  }
  return editKind == GlobalFoodItemEditKind.patchExisting;
}

/// Whether [left] and [right] hold the same values per 100 g.
bool manualProductHasSameNutrition(
  GlobalFoodNutrition left,
  GlobalFoodNutrition right,
) {
  return _sameAmount(left.per100Kcal, right.per100Kcal) &&
      _sameAmount(left.per100Protein, right.per100Protein) &&
      _sameAmount(left.per100Carbs, right.per100Carbs) &&
      _sameAmount(left.per100Fat, right.per100Fat) &&
      _sameAmount(left.per100Salt, right.per100Salt) &&
      _sameAmount(left.per100SaturatedFat, right.per100SaturatedFat) &&
      _sameAmount(
        left.per100PolyunsaturatedFat,
        right.per100PolyunsaturatedFat,
      ) &&
      _sameAmount(left.per100Sugar, right.per100Sugar) &&
      _sameAmount(left.per100Fiber, right.per100Fiber);
}

bool _sameAmount(double? left, double? right) {
  if (left == null || right == null) {
    return left == right;
  }
  return (left - right).abs() <= _tolerance;
}

/// The catalog item that [selection] stands for.
GlobalFoodItem manualProductGlobalFoodItem(
  InventoryReceiptManualProductSelection selection,
) {
  return GlobalFoodItem.create(
    id: selection.globalFoodItemId ?? '',
    name: selection.name,
    now: DateTime.fromMillisecondsSinceEpoch(0),
    brand: selection.brand,
    barcode: selection.barcode,
    imageUrl: normalizeProductImageUrl(selection.imageUrl),
    packageWeight: selection.packageWeight,
    servingSize: selection.servingSize,
    servingQuantity: selection.servingQuantity,
    servingQuantityUnit: selection.servingQuantityUnit,
    nutrition: selection.nutrition,
  );
}
