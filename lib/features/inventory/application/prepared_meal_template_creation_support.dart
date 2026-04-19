import 'package:yamt/features/inventory/application/'
    'ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'recipe_ingredient_assignment_support.dart';
import 'package:yamt/features/inventory/application/'
    'template_ingredient_parser.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Builds a prepared meal from a template and ingredient assignments.
PreparedMealBuildResult buildPreparedMealCreationFromTemplateResult({
  required List<InventoryItem> currentItems,
  required String preparedMealId,
  required DateTime now,
  required PreparedMeal template,
  required int totalPortions,
  required Map<String, List<String>> recipeIngredientAssignments,
  required Map<String, RecipeIngredientAmountConversion>
  recipeIngredientAmountConversions,
  required TemplateIngredientParser ingredientParser,
}) {
  final activeIngredients = template.recipeIngredients
      .where(
        (ingredient) => !template.ignoredRecipeIngredients.contains(ingredient),
      )
      .toList(growable: false);
  if (activeIngredients.isEmpty) {
    throw const PreparedMealBuildException(
      PreparedMealCreationFailureReason.invalidInput,
    );
  }

  final nextItems = List<InventoryItem>.from(currentItems);
  final components = <PreparedMealComponent>[];
  final pendingIngredients = <String>[];

  for (final ingredient in activeIngredients) {
    final assignedItemIds =
        recipeIngredientAssignments[ingredient] ?? const <String>[];
    if (assignedItemIds.isEmpty) {
      pendingIngredients.add(
        ingredientParser.pendingIngredientLabel(
          originalIngredient: ingredient,
          requirement: ingredientParser.parseRequirement(
            ingredient: ingredient,
            selectedPortions: totalPortions,
            basePortions: template.totalPortions,
          ),
        ),
      );
      continue;
    }

    final requirement = ingredientParser.parseRequirement(
      ingredient: ingredient,
      selectedPortions: totalPortions,
      basePortions: template.totalPortions,
    );
    if (requirement == null) {
      pendingIngredients.add(ingredient.trim());
      continue;
    }

    final assignedItems = resolveInventoryItemsById(
      inventoryItemIds: assignedItemIds,
      inventoryItems: nextItems,
    );
    final effectiveRequirement = resolveEffectiveRequirementForItems(
      requirement: requirement,
      assignedItems: assignedItems,
      amountConversion: _assignmentAmountConversionForIngredient(
        recipeIngredientAmountConversions,
        ingredient,
      ),
    );
    if (effectiveRequirement == null) {
      pendingIngredients.add(
        ingredientParser.pendingIngredientLabel(
          originalIngredient: ingredient,
          requirement: requirement,
        ),
      );
      continue;
    }

    var remainingAmount = effectiveRequirement.amount;
    var consumedAnyAmount = false;
    for (final itemId in assignedItemIds) {
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
        requiredUnit: effectiveRequirement.unit,
      )) {
        continue;
      }

      final resolvedNutrition =
          currentItem.nutrition ??
          const GlobalFoodNutrition(
            qualityStatus: GlobalFoodNutritionQualityStatus.missing,
          );
      final consumableAmount = consumableAmountForRequirement(
        item: currentItem,
        requiredUnit: effectiveRequirement.unit,
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

      nextItems[itemIndex] = nextItem;
      components.add(
        buildPreparedMealComponent(
          item: currentItem,
          usedAmount: consumableAmount,
          usedUnit: resolveTemplateUsedUnit(
            item: currentItem,
            requiredUnit: effectiveRequirement.unit,
          ),
          nutrition: resolvedNutrition,
        ),
      );
      remainingAmount = remainingRequirementAfterConsumption(
        item: currentItem,
        requiredUnit: effectiveRequirement.unit,
        remainingAmount: remainingAmount,
        consumedAmount: consumableAmount,
      );
      consumedAnyAmount = true;
    }

    if (!consumedAnyAmount) {
      pendingIngredients.add(
        ingredientParser.pendingIngredientLabel(
          originalIngredient: ingredient,
          requirement: requirement,
        ),
      );
      continue;
    }

    if (remainingAmount > 0) {
      pendingIngredients.add(
        ingredientParser.formatPendingIngredient(
          amount: remainingAmount,
          unit: effectiveRequirement.unit,
          name: effectiveRequirement.name,
        ),
      );
    }
  }

  final nutritionTotals = components.nutritionTotals;
  return PreparedMealBuildResult(
    nextItems: nextItems,
    preparedMeal: PreparedMeal(
      id: preparedMealId,
      name: template.name,
      imageAssetId: normalizeOptionalImageAssetId(template.imageAssetId),
      imageUrl: template.imageUrl,
      recipeUrl: template.recipeUrl,
      recipeIngredients: template.recipeIngredients,
      ignoredRecipeIngredients: template.ignoredRecipeIngredients,
      recipeIngredientAssignments: recipeIngredientAssignments,
      recipeIngredientAmountConversions: recipeIngredientAmountConversions,
      pendingRecipeIngredients: pendingIngredients,
      totalPortions: totalPortions,
      remainingPortions: totalPortions,
      totalKcal: nutritionTotals.totalKcal,
      totalProtein: nutritionTotals.totalProtein,
      totalCarbs: nutritionTotals.totalCarbs,
      totalFat: nutritionTotals.totalFat,
      createdAt: now,
      updatedAt: now,
      components: components,
    ),
  );
}

RecipeIngredientAmountConversion? _assignmentAmountConversionForIngredient(
  Map<String, RecipeIngredientAmountConversion> conversions,
  String ingredient,
) {
  final normalizedIngredient = ingredient.trim();
  if (normalizedIngredient.isEmpty) {
    return null;
  }
  return conversions[normalizedIngredient];
}
