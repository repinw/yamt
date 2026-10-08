import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';

/// Whether [container] misses an id, portions, weight or rows.
bool hasInvalidContainerInput(PreparedMealContainerInput container) {
  return container.id.trim().isEmpty ||
      container.totalPortions < 1 ||
      container.finalNetWeight < 1 ||
      container.sourceKeys.isEmpty;
}

/// Splits the meal of [creationResult] into one meal per container, each
/// with the rows assigned to it. Empty when the rows do not line up.
List<PreparedMeal> splitTemplateMealIntoContainers({
  required String Function() buildId,
  required PreparedMealBuildResult creationResult,
  required PreparedMeal template,
  required Map<String, List<String>> recipeIngredientAssignments,
  required Map<String, RecipeIngredientAmountConversion>
  recipeIngredientAmountConversions,
  required Map<String, String> sourceKeysByIngredient,
  required List<PreparedMealContainerInput> containers,
}) {
  final baseMeal = creationResult.preparedMeal;
  final sourceKeys = creationResult.componentSourceKeys;
  final pendingSourceKeys = creationResult.pendingIngredientSourceKeys;
  if (sourceKeys.length != baseMeal.components.length ||
      pendingSourceKeys.length != baseMeal.pendingRecipeIngredients.length) {
    return const <PreparedMeal>[];
  }

  final assignedContainerIdsBySourceKey = <String, String>{};
  for (final container in containers) {
    for (final sourceKey in container.sourceKeys) {
      final key = sourceKey.trim();
      if (key.isEmpty || assignedContainerIdsBySourceKey.containsKey(key)) {
        return const <PreparedMeal>[];
      }
      assignedContainerIdsBySourceKey[key] = container.id;
    }
  }

  final containerCount = containers.length;
  final meals = <PreparedMeal>[];
  for (final container in containers) {
    final containerSourceKeys = container.sourceKeys
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .toSet();
    final components = <PreparedMealComponent>[];
    for (var index = 0; index < baseMeal.components.length; index++) {
      final sourceKey = sourceKeys[index].trim();
      if (!assignedContainerIdsBySourceKey.containsKey(sourceKey)) {
        return const <PreparedMeal>[];
      }
      if (containerSourceKeys.contains(sourceKey)) {
        components.add(baseMeal.components[index]);
      }
    }
    // Rows the stock could not cover stay visible as pending ingredients
    // of their container instead of disappearing from the saved meal.
    final pendingIngredients = <String>[
      for (var index = 0; index < pendingSourceKeys.length; index++)
        if (containerSourceKeys.contains(pendingSourceKeys[index].trim()))
          baseMeal.pendingRecipeIngredients[index],
    ];
    if (components.isEmpty && pendingIngredients.isEmpty) {
      return const <PreparedMeal>[];
    }

    final nutritionTotals = components.nutritionTotals;
    final recipeIngredients = _recipeIngredientsForContainer(
      template: template,
      sourceKeysByIngredient: sourceKeysByIngredient,
      containerSourceKeys: containerSourceKeys,
    );
    final name = _containerMealName(
      templateName: template.name,
      containerLabel: container.label,
      containerCount: containerCount,
    );
    meals.add(
      baseMeal.copyWith(
        id: buildId(),
        name: name,
        recipeIngredients: recipeIngredients,
        recipeIngredientAssignments: _assignmentsForIngredients(
          recipeIngredientAssignments,
          recipeIngredients,
        ),
        recipeIngredientAmountConversions: _conversionsForIngredients(
          recipeIngredientAmountConversions,
          recipeIngredients,
        ),
        pendingRecipeIngredients: pendingIngredients,
        totalPortions: container.totalPortions,
        remainingPortions: container.totalPortions,
        finalNetWeight: container.finalNetWeight,
        totalKcal: nutritionTotals.totalKcal,
        totalProtein: nutritionTotals.totalProtein,
        totalCarbs: nutritionTotals.totalCarbs,
        totalFat: nutritionTotals.totalFat,
        components: components,
      ),
    );
  }
  return meals;
}

String _containerMealName({
  required String templateName,
  required String containerLabel,
  required int containerCount,
}) {
  final trimmedTemplateName = templateName.trim();
  if (containerCount <= 1) {
    return trimmedTemplateName;
  }
  final trimmedContainerLabel = containerLabel.trim();
  if (trimmedContainerLabel.isEmpty) {
    return trimmedTemplateName;
  }
  return '$trimmedTemplateName - $trimmedContainerLabel';
}

List<String> _recipeIngredientsForContainer({
  required PreparedMeal template,
  required Map<String, String> sourceKeysByIngredient,
  required Set<String> containerSourceKeys,
}) {
  return template.recipeIngredients
      .where(
        (ingredient) =>
            containerSourceKeys.contains(sourceKeysByIngredient[ingredient]),
      )
      .toList(growable: false);
}

Map<String, List<String>> _assignmentsForIngredients(
  Map<String, List<String>> assignments,
  List<String> ingredients,
) {
  final ingredientSet = ingredients.toSet();
  return Map<String, List<String>>.fromEntries(
    assignments.entries.where((entry) => ingredientSet.contains(entry.key)),
  );
}

Map<String, RecipeIngredientAmountConversion> _conversionsForIngredients(
  Map<String, RecipeIngredientAmountConversion> conversions,
  List<String> ingredients,
) {
  final ingredientSet = ingredients.toSet();
  return Map<String, RecipeIngredientAmountConversion>.fromEntries(
    conversions.entries.where((entry) => ingredientSet.contains(entry.key)),
  );
}
