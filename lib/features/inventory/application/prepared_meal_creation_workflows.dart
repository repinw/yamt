import 'package:yamt/features/inventory/application/'
    'prepared_meal_creation_support.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_template_creation_support.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_workflow_context.dart';
import 'package:yamt/features/inventory/application/'
    'template_ingredient_parser.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Handles prepared meal creation workflows.
class PreparedMealCreationWorkflows {
  /// Creates creation workflows.
  const PreparedMealCreationWorkflows({
    required PreparedMealWorkflowContext context,
  }) : _context = context;

  final PreparedMealWorkflowContext _context;

  /// Creates a prepared meal from explicit inventory selections.
  Future<PreparedMealCreationResult> createPreparedMeal({
    required String name,
    required int totalPortions,
    required List<PreparedMealItemInput> items,
    required String? imageAssetId,
    required InventoryItemRepository inventoryRepository,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || totalPortions < 1 || items.isEmpty) {
      return const PreparedMealCreationResult.failure(
        PreparedMealCreationFailureReason.invalidInput,
      );
    }

    final currentMeals = await _context.loadMeals();
    final currentItems = await inventoryRepository.readAll();

    try {
      final creationResult = buildPreparedMealCreationResult(
        currentItems: currentItems,
        preparedMealId: _context.buildId(),
        now: _context.buildNow(),
        name: trimmedName,
        imageAssetId: imageAssetId,
        totalPortions: totalPortions,
        inputs: items,
      );
      return _persistCreatedMeal(
        inventoryRepository: inventoryRepository,
        currentMeals: currentMeals,
        currentItems: currentItems,
        creationResult: creationResult,
      );
    } on PreparedMealBuildException catch (error) {
      return PreparedMealCreationResult.failure(error.reason);
    }
  }

  /// Creates a prepared meal from a saved recipe template.
  Future<PreparedMealCreationResult> createPreparedMealFromTemplate({
    required PreparedMeal template,
    required int totalPortions,
    required Map<String, List<String>> recipeIngredientAssignments,
    required Map<String, RecipeIngredientAmountConversion>
    recipeIngredientAmountConversions,
    required InventoryItemRepository inventoryRepository,
    required TemplateIngredientParser ingredientParser,
    List<PreparedMealItemInput> additionalItems =
        const <PreparedMealItemInput>[],
    int? finalNetWeight,
    Map<String, String> sourceKeysByIngredient = const <String, String>{},
  }) async {
    if (totalPortions < 1 || template.name.trim().isEmpty) {
      return const PreparedMealCreationResult.failure(
        PreparedMealCreationFailureReason.invalidInput,
      );
    }

    final currentMeals = await _context.loadMeals();
    final currentItems = await inventoryRepository.readAll();

    try {
      var creationResult = buildPreparedMealCreationFromTemplateResult(
        currentItems: currentItems,
        preparedMealId: _context.buildId(),
        now: _context.buildNow(),
        template: template,
        totalPortions: totalPortions,
        recipeIngredientAssignments: recipeIngredientAssignments,
        recipeIngredientAmountConversions: recipeIngredientAmountConversions,
        ingredientParser: ingredientParser,
        sourceKeysByIngredient: sourceKeysByIngredient,
      );
      if (additionalItems.isNotEmpty) {
        creationResult = _appendAdditionalItemsToTemplateMeal(
          creationResult: creationResult,
          additionalItems: additionalItems,
          now: _context.buildNow(),
          buildId: _context.buildId,
          template: template,
          totalPortions: totalPortions,
        );
      }
      final preparedMeal = finalNetWeight == null || finalNetWeight < 1
          ? creationResult.preparedMeal
          : creationResult.preparedMeal.copyWith(
              finalNetWeight: finalNetWeight,
              remainingNetWeight: finalNetWeight,
            );
      return _persistCreatedMeal(
        inventoryRepository: inventoryRepository,
        currentMeals: currentMeals,
        currentItems: currentItems,
        creationResult: PreparedMealBuildResult(
          nextItems: creationResult.nextItems,
          preparedMeal: preparedMeal,
        ),
      );
    } on PreparedMealBuildException catch (error) {
      return PreparedMealCreationResult.failure(error.reason);
    }
  }

  /// Creates multiple prepared meals from one saved recipe template.
  Future<PreparedMealCreationResult> createPreparedMealsFromTemplateContainers({
    required PreparedMeal template,
    required int totalPortions,
    required Map<String, List<String>> recipeIngredientAssignments,
    required Map<String, RecipeIngredientAmountConversion>
    recipeIngredientAmountConversions,
    required InventoryItemRepository inventoryRepository,
    required TemplateIngredientParser ingredientParser,
    required List<PreparedMealContainerInput> containers,
    required Map<String, String> sourceKeysByIngredient,
    List<PreparedMealItemInput> additionalItems =
        const <PreparedMealItemInput>[],
  }) async {
    if (totalPortions < 1 ||
        template.name.trim().isEmpty ||
        containers.isEmpty) {
      return const PreparedMealCreationResult.failure(
        PreparedMealCreationFailureReason.invalidInput,
      );
    }
    if (containers.any(_hasInvalidContainerInput)) {
      return const PreparedMealCreationResult.failure(
        PreparedMealCreationFailureReason.invalidInput,
      );
    }

    final currentMeals = await _context.loadMeals();
    final currentItems = await inventoryRepository.readAll();

    try {
      var creationResult = buildPreparedMealCreationFromTemplateResult(
        currentItems: currentItems,
        preparedMealId: _context.buildId(),
        now: _context.buildNow(),
        template: template,
        totalPortions: totalPortions,
        recipeIngredientAssignments: recipeIngredientAssignments,
        recipeIngredientAmountConversions: recipeIngredientAmountConversions,
        ingredientParser: ingredientParser,
        sourceKeysByIngredient: sourceKeysByIngredient,
      );
      if (additionalItems.isNotEmpty) {
        creationResult = _appendAdditionalItemsToTemplateMeal(
          creationResult: creationResult,
          additionalItems: additionalItems,
          now: _context.buildNow(),
          buildId: _context.buildId,
          template: template,
          totalPortions: totalPortions,
        );
      }

      final preparedMeals = _splitTemplateMealIntoContainers(
        creationResult: creationResult,
        template: template,
        recipeIngredientAssignments: recipeIngredientAssignments,
        recipeIngredientAmountConversions: recipeIngredientAmountConversions,
        sourceKeysByIngredient: sourceKeysByIngredient,
        containers: containers,
      );
      if (preparedMeals.isEmpty) {
        return const PreparedMealCreationResult.failure(
          PreparedMealCreationFailureReason.invalidInput,
        );
      }

      return _persistCreatedMeals(
        inventoryRepository: inventoryRepository,
        currentMeals: currentMeals,
        currentItems: currentItems,
        nextItems: creationResult.nextItems,
        preparedMeals: preparedMeals,
      );
    } on PreparedMealBuildException catch (error) {
      return PreparedMealCreationResult.failure(error.reason);
    }
  }

  Future<PreparedMealCreationResult> _persistCreatedMeal({
    required InventoryItemRepository inventoryRepository,
    required List<PreparedMeal> currentMeals,
    required List<InventoryItem> currentItems,
    required PreparedMealBuildResult creationResult,
  }) async {
    return _persistCreatedMeals(
      inventoryRepository: inventoryRepository,
      currentMeals: currentMeals,
      currentItems: currentItems,
      nextItems: creationResult.nextItems,
      preparedMeals: <PreparedMeal>[creationResult.preparedMeal],
    );
  }

  Future<PreparedMealCreationResult> _persistCreatedMeals({
    required InventoryItemRepository inventoryRepository,
    required List<PreparedMeal> currentMeals,
    required List<InventoryItem> currentItems,
    required List<InventoryItem> nextItems,
    required List<PreparedMeal> preparedMeals,
  }) async {
    if (preparedMeals.isEmpty) {
      return const PreparedMealCreationResult.failure(
        PreparedMealCreationFailureReason.invalidInput,
      );
    }

    final inventorySaved = await inventoryRepository.saveAll(
      nextItems,
    );
    if (!inventorySaved) {
      return const PreparedMealCreationResult.failure(
        PreparedMealCreationFailureReason.inventorySaveFailed,
      );
    }

    final nextMeals = List<PreparedMeal>.from(currentMeals)
      ..addAll(preparedMeals);
    final mealsSaved = await _context.saveMeals(
      previousMeals: currentMeals,
      nextMeals: nextMeals,
    );
    if (mealsSaved) {
      return PreparedMealCreationResult.successMany(
        preparedMeals.map((meal) => meal.id).toList(growable: false),
      );
    }

    await _context.restoreInventory(
      inventoryRepository: inventoryRepository,
      previousItems: currentItems,
    );
    return const PreparedMealCreationResult.failure(
      PreparedMealCreationFailureReason.mealSaveFailed,
    );
  }

  PreparedMealBuildResult _appendAdditionalItemsToTemplateMeal({
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

  bool _hasInvalidContainerInput(PreparedMealContainerInput container) {
    return container.id.trim().isEmpty ||
        container.totalPortions < 1 ||
        container.finalNetWeight < 1 ||
        container.sourceKeys.isEmpty;
  }

  List<PreparedMeal> _splitTemplateMealIntoContainers({
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
    if (sourceKeys.length != baseMeal.components.length) {
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
      if (components.isEmpty) {
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
          id: _context.buildId(),
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
          pendingRecipeIngredients: const <String>[],
          totalPortions: container.totalPortions,
          remainingPortions: container.totalPortions,
          finalNetWeight: container.finalNetWeight,
          remainingNetWeight: container.finalNetWeight,
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
}
