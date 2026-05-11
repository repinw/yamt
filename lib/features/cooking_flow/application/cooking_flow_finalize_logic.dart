import 'dart:developer' as developer;

import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_builder.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_models.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_creation_support.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_template_creation_support.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

/// Resolves final user-facing portion count.
int resolveCookingFlowFinalPortions({
  required bool splitIntoPortions,
  required double portionCount,
}) {
  if (!splitIntoPortions) {
    return 1;
  }
  final roundedPortions = portionCount.round();
  return roundedPortions < 1 ? 1 : roundedPortions;
}

/// Returns summary rows that can be assigned to a container.
List<CookingFlowSummaryIngredientDraft> assignableCookingFlowFinalizeRows(
  List<CookingFlowSummaryIngredientDraft> summaryIngredients,
) {
  return summaryIngredients
      .where(
        (row) =>
            parseCookingFlowSummaryUsedAmount(row.amount) > 0 &&
            row.inventoryItemIds.isNotEmpty,
      )
      .toList(growable: false);
}

/// Normalizes row-to-container assignments.
Map<String, String> effectiveCookingFlowIngredientContainerAssignments({
  required List<CookingFlowFinalizeStorageContainerInput> containers,
  required List<CookingFlowSummaryIngredientDraft> summaryIngredients,
  required Map<String, String> assignments,
}) {
  if (containers.isEmpty) {
    return const <String, String>{};
  }
  final firstContainerId = containers.first.id;
  final containerIds = containers.map((container) => container.id).toSet();
  final nextAssignments = <String, String>{};
  for (final row in assignableCookingFlowFinalizeRows(summaryIngredients)) {
    final assignedContainerId = assignments[row.key];
    nextAssignments[row.key] =
        assignedContainerId != null &&
            containerIds.contains(assignedContainerId)
        ? assignedContainerId
        : firstContainerId;
  }
  return nextAssignments;
}

/// Validates final storage and assignment input.
CookingFlowFinalizeValidationFailure? validateCookingFlowFinalize({
  required List<CookingFlowFinalizeStorageContainerInput> containers,
  required List<CookingFlowSummaryIngredientDraft> summaryIngredients,
  required Map<String, String> assignments,
}) {
  if (containers.isEmpty) {
    return CookingFlowFinalizeValidationFailure.missingWeight;
  }
  for (final container in containers) {
    if (container.grossWeightText.trim().isEmpty) {
      return CookingFlowFinalizeValidationFailure.missingGrossWeight;
    }
    if (container.grossWeight < 1) {
      return CookingFlowFinalizeValidationFailure.invalidWeight;
    }
    if (container.grossWeight <= container.taraWeight) {
      return CookingFlowFinalizeValidationFailure.grossMustExceedTara;
    }
  }
  final effectiveAssignments =
      effectiveCookingFlowIngredientContainerAssignments(
        containers: containers,
        summaryIngredients: summaryIngredients,
        assignments: assignments,
      );
  for (final row in assignableCookingFlowFinalizeRows(summaryIngredients)) {
    if (!effectiveAssignments.containsKey(row.key)) {
      return CookingFlowFinalizeValidationFailure.ingredientContainerMissing;
    }
  }
  if (effectiveAssignments.isNotEmpty) {
    for (final container in containers) {
      final hasIngredient = effectiveAssignments.values.contains(container.id);
      if (!hasIngredient) {
        return CookingFlowFinalizeValidationFailure.containerMissingIngredients;
      }
    }
  }
  return null;
}

/// Builds final save plan from current cookflow data.
CookingFlowFinalizeMealSavePlan buildCookingFlowFinalizeSavePlan({
  required PreparedMeal template,
  required List<InventoryItem> inventoryItems,
  required List<CookingFlowSummaryIngredientDraft> summaryIngredients,
  required CookingFlowIntroDraft? introDraft,
  required int targetPortions,
  required int finalPortions,
}) {
  final summaryRows = summaryIngredients.isEmpty
      ? buildCookingFlowSummaryIngredientsFromIntro(
          template: template,
          inventoryItems: inventoryItems,
          introDraft: introDraft,
          targetPortions: targetPortions,
        )
      : summaryIngredients;
  final recipeIngredients = <String>[];
  final recipeIngredientAssignments = <String, List<String>>{};
  final recipeIngredientAmountConversions =
      <String, RecipeIngredientAmountConversion>{
        ...template.recipeIngredientAmountConversions,
      };
  final additionalItems = <PreparedMealItemInput>[];
  final sourceKeysByIngredient = <String, String>{};
  var totalInputCount = 0;

  for (final row in summaryRows) {
    final usedAmount = parseCookingFlowSummaryUsedAmount(row.amount);
    if (usedAmount < 1) {
      continue;
    }

    switch (row.kind) {
      case CookingFlowSummaryIngredientKind.template:
        final ingredient = formatCookingFlowSummaryIngredient(row);
        recipeIngredients.add(ingredient);
        sourceKeysByIngredient[ingredient] = row.key;
        if (row.sourceIngredient != null) {
          final amountConversion =
              template.recipeIngredientAmountConversions[row.sourceIngredient!];
          if (amountConversion != null) {
            recipeIngredientAmountConversions[ingredient] = amountConversion;
          }
        }
        if (row.inventoryItemIds.isEmpty) {
          continue;
        }
        recipeIngredientAssignments[ingredient] = row.inventoryItemIds;
        totalInputCount += row.inventoryItemIds.length;
      case CookingFlowSummaryIngredientKind.additional:
        if (row.inventoryItemIds.isEmpty) {
          continue;
        }
        additionalItems.add(
          PreparedMealItemInput(
            itemId: row.inventoryItemIds.first,
            usedAmount: usedAmount,
            sourceKey: row.key,
          ),
        );
        totalInputCount += 1;
    }
  }

  return CookingFlowFinalizeMealSavePlan(
    template: template.copyWith(
      recipeIngredients: recipeIngredients,
      ignoredRecipeIngredients: const <String>[],
      totalPortions: finalPortions,
      remainingPortions: finalPortions,
    ),
    recipeIngredientAssignments: recipeIngredientAssignments,
    recipeIngredientAmountConversions: recipeIngredientAmountConversions,
    additionalItems: additionalItems,
    sourceKeysByIngredient: sourceKeysByIngredient,
    totalInputCount: totalInputCount,
  );
}

/// Builds nutrition preview from current cookflow data.
CookingFlowNutritionPreview buildCookingFlowFinalizeNutritionPreview({
  required PreparedMeal template,
  required List<InventoryItem> inventoryItems,
  required List<CookingFlowSummaryIngredientDraft> summaryIngredients,
  required CookingFlowIntroDraft? introDraft,
  required int targetPortions,
  required int finalPortions,
  required bool splitIntoPortions,
  required double portionCount,
  required TemplateIngredientParser ingredientParser,
}) {
  final savePlan = buildCookingFlowFinalizeSavePlan(
    template: template,
    inventoryItems: inventoryItems,
    summaryIngredients: summaryIngredients,
    introDraft: introDraft,
    targetPortions: targetPortions,
    finalPortions: finalPortions,
  );
  if (savePlan.totalInputCount < 1) {
    return const CookingFlowNutritionPreview.zero();
  }

  final resolvedFinalPortions = resolveCookingFlowFinalPortions(
    splitIntoPortions: splitIntoPortions,
    portionCount: portionCount,
  );

  try {
    final baseResult = buildPreparedMealCreationFromTemplateResult(
      currentItems: inventoryItems,
      preparedMealId: '_cookflow_preview_base',
      now: DateTime.now(),
      template: savePlan.template,
      totalPortions: resolvedFinalPortions,
      recipeIngredientAssignments: savePlan.recipeIngredientAssignments,
      recipeIngredientAmountConversions:
          savePlan.recipeIngredientAmountConversions,
      ingredientParser: ingredientParser,
      sourceKeysByIngredient: savePlan.sourceKeysByIngredient,
    );
    var previewMeal = baseResult.preparedMeal;
    if (savePlan.additionalItems.isNotEmpty) {
      final extraResult = buildPreparedMealCreationResult(
        currentItems: baseResult.nextItems,
        preparedMealId: '_cookflow_preview_extra',
        now: DateTime.now(),
        name: savePlan.template.name,
        imageAssetId: savePlan.template.imageAssetId,
        totalPortions: resolvedFinalPortions,
        inputs: savePlan.additionalItems,
      );
      final extraMeal = extraResult.preparedMeal;
      previewMeal = previewMeal.copyWith(
        totalKcal: previewMeal.totalKcal + extraMeal.totalKcal,
        totalProtein: previewMeal.totalProtein + extraMeal.totalProtein,
        totalCarbs: previewMeal.totalCarbs + extraMeal.totalCarbs,
        totalFat: previewMeal.totalFat + extraMeal.totalFat,
        components: <PreparedMealComponent>[
          ...previewMeal.components,
          ...extraMeal.components,
        ],
      );
    }

    final divisor = splitIntoPortions ? resolvedFinalPortions.toDouble() : 1;
    return CookingFlowNutritionPreview(
      kcal: previewMeal.totalKcal / divisor,
      carbs: previewMeal.totalCarbs / divisor,
      protein: previewMeal.totalProtein / divisor,
      fat: previewMeal.totalFat / divisor,
    );
  } on PreparedMealBuildException catch (error, stackTrace) {
    developer.log(
      'Failed to build cookflow nutrition preview.',
      name: 'CookingFlowFinalizeLogic',
      error: error,
      stackTrace: stackTrace,
    );
    return const CookingFlowNutritionPreview.zero();
  } on Object catch (error, stackTrace) {
    developer.log(
      'Unexpected error while building cookflow nutrition preview.',
      name: 'CookingFlowFinalizeLogic',
      error: error,
      stackTrace: stackTrace,
    );
    return const CookingFlowNutritionPreview.zero();
  }
}

/// Builds prepared meal container inputs for save workflow.
List<PreparedMealContainerInput> buildCookingFlowPreparedMealContainers({
  required CookingFlowFinalizeMealSavePlan savePlan,
  required List<CookingFlowFinalizeStorageContainerInput> containers,
  required Map<String, String> ingredientContainerAssignments,
}) {
  final savePlanSourceKeys = <String>{
    ...savePlan.sourceKeysByIngredient.values,
    for (final item in savePlan.additionalItems)
      if (item.sourceKey case final String sourceKey) sourceKey,
  };
  final inputs = <PreparedMealContainerInput>[];
  for (final container in containers) {
    final sourceKeys =
        ingredientContainerAssignments.isEmpty && containers.length == 1
        ? savePlanSourceKeys.toList(growable: false)
        : ingredientContainerAssignments.entries
              .where(
                (entry) =>
                    entry.value == container.id &&
                    savePlanSourceKeys.contains(entry.key),
              )
              .map((entry) => entry.key)
              .toList(growable: false);
    if (sourceKeys.isEmpty) {
      return const <PreparedMealContainerInput>[];
    }
    inputs.add(
      PreparedMealContainerInput(
        id: container.id,
        label: container.label,
        totalPortions: container.totalPortions,
        finalNetWeight: container.finalNetWeight,
        sourceKeys: sourceKeys,
      ),
    );
  }
  return inputs;
}
