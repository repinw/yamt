import 'package:yamt/features/inventory/application/'
    'ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/application/prepared_meal_from_items.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'recipe_ingredient_assignment_support.dart';
import 'package:yamt/features/inventory/application/'
    'template_ingredient_unit_mapper.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

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
  Map<String, String> sourceKeysByIngredient = const <String, String>{},
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
  final componentSourceKeys = <String>[];
  final pendingIngredients = <String>[];
  final pendingIngredientSourceKeys = <String>[];

  for (final ingredient in activeIngredients) {
    void addPending(String label) {
      pendingIngredients.add(label);
      pendingIngredientSourceKeys.add(sourceKeysByIngredient[ingredient] ?? '');
    }

    final assignedItemIds =
        recipeIngredientAssignments[ingredient] ?? const <String>[];
    if (assignedItemIds.isEmpty) {
      addPending(
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
      addPending(ingredient.trim());
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
      addPending(
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

      final nextItem = currentItem.reducedBy(consumableAmount);
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
      componentSourceKeys.add(sourceKeysByIngredient[ingredient] ?? '');
      remainingAmount = remainingRequirementAfterConsumption(
        item: currentItem,
        requiredUnit: effectiveRequirement.unit,
        remainingAmount: remainingAmount,
        consumedAmount: consumableAmount,
      );
      consumedAnyAmount = true;
    }

    if (!consumedAnyAmount) {
      addPending(
        ingredientParser.pendingIngredientLabel(
          originalIngredient: ingredient,
          requirement: requirement,
        ),
      );
      continue;
    }

    if (remainingAmount > 0) {
      addPending(
        ingredientParser.formatPendingIngredient(
          amount: remainingAmount,
          unit: effectiveRequirement.unit.toTemplateIngredientUnit(),
          name: effectiveRequirement.name,
        ),
      );
    }
  }

  final nutritionTotals = components.nutritionTotals;
  return PreparedMealBuildResult(
    nextItems: nextItems,
    componentSourceKeys: componentSourceKeys,
    pendingIngredientSourceKeys: pendingIngredientSourceKeys,
    preparedMeal: PreparedMeal(
      id: preparedMealId,
      name: template.name,
      imageAssetId: normalizeOptionalImageAssetId(template.imageAssetId),
      imageUrl: template.imageUrl,
      recipeUrl: template.recipeUrl,
      recipeIngredients: template.recipeIngredients,
      recipeInstructions: template.recipeInstructions,
      ignoredRecipeIngredients: template.ignoredRecipeIngredients,
      recipeIngredientAssignments: recipeIngredientAssignments,
      recipeIngredientAmountConversions: recipeIngredientAmountConversions,
      pendingRecipeIngredients: pendingIngredients,
      totalPortions: totalPortions,
      remainingPortions: totalPortions,
      servedInPieces: template.servedInPieces,
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

/// Adds the Vorrat [additionalItems] to the meal of [creationResult].
PreparedMealBuildResult appendItemsToTemplateMeal({
  required PreparedMealBuildResult creationResult,
  required List<PreparedMealItemInput> additionalItems,
  required DateTime now,
  required String Function() buildId,
  required PreparedMeal template,
  required int totalPortions,
}) {
  final extraItemsResult = buildPreparedMealCreationResult(
    currentItems: creationResult.nextItems,
    preparedMealId: buildId(),
    now: now,
    name: template.name,
    imageAssetId: template.imageAssetId,
    totalPortions: totalPortions,
    inputs: additionalItems,
  );
  final baseMeal = creationResult.preparedMeal;
  final extraMeal = extraItemsResult.preparedMeal;
  return PreparedMealBuildResult(
    nextItems: extraItemsResult.nextItems,
    componentSourceKeys: <String>[
      ...creationResult.componentSourceKeys,
      ...extraItemsResult.componentSourceKeys,
    ],
    pendingIngredientSourceKeys: creationResult.pendingIngredientSourceKeys,
    preparedMeal: baseMeal.copyWith(
      totalKcal: baseMeal.totalKcal + extraMeal.totalKcal,
      totalProtein: baseMeal.totalProtein + extraMeal.totalProtein,
      totalCarbs: baseMeal.totalCarbs + extraMeal.totalCarbs,
      totalFat: baseMeal.totalFat + extraMeal.totalFat,
      components: <PreparedMealComponent>[
        ...baseMeal.components,
        ...extraMeal.components,
      ],
    ),
  );
}
