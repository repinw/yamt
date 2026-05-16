import 'package:yamt/core/domain/eat_selection.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/application/'
    'product_ai_nutrition_selection.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_search_value_utils.dart';
import 'package:yamt/features/product_search/domain/product_ai_search_models.dart';

/// Builds the default kcal density for an AI draft.
double baseProductAiPer100Kcal(ProductAiSearchDraft draft) {
  return _roundToWholeNumber(
    draft.defaultKcal * 100 / draft.totalWeightGrams,
  );
}

/// Builds nutrition data for the selected AI portion and kcal density.
ProductAiNutritionSelection buildProductAiNutritionSelection({
  required ProductAiSearchDraft draft,
  required double weightGrams,
  required double selectedPer100Kcal,
}) {
  final basePer100Kcal = baseProductAiPer100Kcal(draft);
  final minPer100Kcal = _roundToWholeNumber(
    draft.totalKcalMin * 100 / draft.totalWeightGrams,
  );
  final maxPer100Kcal = _roundToWholeNumber(
    draft.totalKcalMax * 100 / draft.totalWeightGrams,
  );
  final resolvedPer100Kcal = _roundToWholeNumber(
    selectedPer100Kcal.clamp(
      minPer100Kcal,
      maxPer100Kcal,
    ),
  );
  final selectedTotalKcal = _roundToWholeNumber(
    resolvedPer100Kcal * draft.totalWeightGrams / 100,
  );
  final fullPortionNutrition = draft.nutritionForKcal(selectedTotalKcal);
  final portionNutrition = fullPortionNutrition.scaleBy(
    weightGrams / draft.totalWeightGrams,
  );
  final per100Nutrition = fullPortionNutrition.toPer100Nutrition(
    grams: draft.totalWeightGrams,
    qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
  );

  return ProductAiNutritionSelection(
    draft: draft,
    weightGrams: weightGrams,
    weightLabel: '${formatManualProductDouble(weightGrams)} g',
    minPer100Kcal: minPer100Kcal,
    maxPer100Kcal: maxPer100Kcal,
    basePer100Kcal: basePer100Kcal,
    per100Kcal: resolvedPer100Kcal,
    per100Nutrition: per100Nutrition,
    portionNutrition: portionNutrition,
  );
}

/// Builds the inventory item returned from AI search.
InventoryItem buildProductAiResultItem({
  required InventoryItem baseItem,
  required ProductAiNutritionSelection selection,
}) {
  final parsedAmount = InventoryAmountParseResult(
    amount: selection.weightGrams.round(),
    unit: InventoryAmountUnit.gram,
  );

  return baseItem
      .copyWith(
        name: selection.draft.name,
        brand: selection.draft.brand,
        barcode: '',
        weight: selection.weightLabel,
        servingSize: selection.weightLabel,
        servingQuantity: selection.weightGrams,
        servingQuantityUnit: InventoryAmountUnit.gram.code,
        nutrition: selection.per100Nutrition,
        imageUrl: null,
      )
      .withResolvedAmount(
        weight: selection.weightLabel,
        parsedAmount: parsedAmount,
        quantity: baseItem.quantity,
      );
}

/// Builds inline eat selection for AI search result.
EatSelection? buildProductAiEatSelection({
  required bool eatNow,
  required ProductAiNutritionSelection selection,
  required DateTime loggedAt,
  required MealType mealType,
}) {
  if (!eatNow) {
    return null;
  }

  return EatSelection(
    inventoryAmount: selection.weightGrams.round(),
    loggedAt: loggedAt,
    mealType: mealType,
  );
}

double _roundToWholeNumber(double value) {
  return value.roundToDouble();
}
