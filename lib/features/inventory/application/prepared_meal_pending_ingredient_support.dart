import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'template_ingredient_parser.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Consumes inventory to fill one pending template ingredient entry.
PreparedMealPendingIngredientFillResult?
buildPreparedMealPendingIngredientFillResult({
  required List<InventoryItem> currentItems,
  required String ingredient,
  required List<String> inventoryItemIds,
  required TemplateIngredientParser ingredientParser,
}) {
  final requirement = ingredientParser.parseRequirement(
    ingredient: ingredient,
    selectedPortions: 1,
    basePortions: 1,
  );
  if (requirement == null) {
    return null;
  }

  final nextItems = List<InventoryItem>.from(currentItems);
  final components = <PreparedMealComponent>[];
  var remainingAmount = requirement.amount;
  var consumedAnyAmount = false;

  for (final itemId in inventoryItemIds) {
    if (remainingAmount <= 0) {
      break;
    }

    final itemIndex = nextItems.indexWhere((item) => item.id == itemId);
    if (itemIndex < 0) {
      continue;
    }

    final currentItem = nextItems[itemIndex];
    if (!hasCompatibleTemplateRequirement(
      item: currentItem,
      requiredUnit: requirement.unit,
    )) {
      continue;
    }

    final consumableAmount = consumableAmountForRequirement(
      item: currentItem,
      requiredUnit: requirement.unit,
      remainingAmount: remainingAmount,
    );
    if (consumableAmount < 1) {
      continue;
    }

    final nextItem = reduceInventoryItem(
      item: currentItem,
      amount: consumableAmount,
    );
    if (nextItem == null) {
      continue;
    }

    final resolvedNutrition =
        currentItem.nutrition ??
        const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.missing,
        );
    nextItems[itemIndex] = nextItem;
    components.add(
      buildPreparedMealComponent(
        item: currentItem,
        usedAmount: consumableAmount,
        usedUnit: resolveTemplateUsedUnit(
          item: currentItem,
          requiredUnit: requirement.unit,
        ),
        nutrition: resolvedNutrition,
      ),
    );
    remainingAmount = remainingRequirementAfterConsumption(
      item: currentItem,
      requiredUnit: requirement.unit,
      remainingAmount: remainingAmount,
      consumedAmount: consumableAmount,
    );
    consumedAnyAmount = true;
  }

  if (!consumedAnyAmount || components.isEmpty) {
    return null;
  }

  return PreparedMealPendingIngredientFillResult(
    nextItems: nextItems,
    components: components,
    remainingIngredient: remainingAmount > 0
        ? ingredientParser.formatPendingIngredient(
            amount: remainingAmount,
            unit: requirement.unit,
            name: requirement.name,
          )
        : null,
  );
}
