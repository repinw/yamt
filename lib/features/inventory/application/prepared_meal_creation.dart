import 'package:yamt/features/inventory/application/'
    'prepared_meal_containers.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_from_items.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_from_template.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_writer.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

/// Handles prepared meal creation workflows.
class PreparedMealCreation {
  /// Creates creation workflows.
  const new({required this._writer});

  final PreparedMealWriter _writer;

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

    final currentMeals = await _writer.loadMeals();
    final currentItems = await inventoryRepository.readAll();

    try {
      final creationResult = buildPreparedMealCreationResult(
        currentItems: currentItems,
        preparedMealId: _writer.buildId(),
        now: _writer.buildNow(),
        name: trimmedName,
        imageAssetId: imageAssetId,
        totalPortions: totalPortions,
        inputs: items,
      );
      return await _persistCreatedMeal(
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

    final currentMeals = await _writer.loadMeals();
    final currentItems = await inventoryRepository.readAll();

    try {
      final creationResult = _templateMeal(
        currentItems: currentItems,
        template: template,
        totalPortions: totalPortions,
        recipeIngredientAssignments: recipeIngredientAssignments,
        recipeIngredientAmountConversions: recipeIngredientAmountConversions,
        ingredientParser: ingredientParser,
        sourceKeysByIngredient: sourceKeysByIngredient,
        additionalItems: additionalItems,
      );
      final preparedMeal = finalNetWeight == null || finalNetWeight < 1
          ? creationResult.preparedMeal
          : creationResult.preparedMeal.copyWith(
              finalNetWeight: finalNetWeight,
            );
      return await _persistCreatedMeal(
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
    if (containers.any(hasInvalidContainerInput)) {
      return const PreparedMealCreationResult.failure(
        PreparedMealCreationFailureReason.invalidInput,
      );
    }

    final currentMeals = await _writer.loadMeals();
    final currentItems = await inventoryRepository.readAll();

    try {
      final creationResult = _templateMeal(
        currentItems: currentItems,
        template: template,
        totalPortions: totalPortions,
        recipeIngredientAssignments: recipeIngredientAssignments,
        recipeIngredientAmountConversions: recipeIngredientAmountConversions,
        ingredientParser: ingredientParser,
        sourceKeysByIngredient: sourceKeysByIngredient,
        additionalItems: additionalItems,
      );

      final preparedMeals = splitTemplateMealIntoContainers(
        buildId: _writer.buildId,
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

      return await _persistCreatedMeals(
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
    return await _persistCreatedMeals(
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

    final inventorySaved = await inventoryRepository.saveAll(nextItems);
    if (!inventorySaved) {
      return const PreparedMealCreationResult.failure(
        PreparedMealCreationFailureReason.inventorySaveFailed,
      );
    }

    final nextMeals = List<PreparedMeal>.from(currentMeals)
      ..addAll(preparedMeals);
    final mealsSaved = await _writer.saveMeals(
      previousMeals: currentMeals,
      nextMeals: nextMeals,
    );
    if (mealsSaved) {
      return PreparedMealCreationResult.successMany(
        preparedMeals.map((meal) => meal.id).toList(growable: false),
      );
    }

    await _writer.restoreInventory(
      inventoryRepository: inventoryRepository,
      previousItems: currentItems,
    );
    return const PreparedMealCreationResult.failure(
      PreparedMealCreationFailureReason.mealSaveFailed,
    );
  }

  /// Builds the meal of [template] from the Vorrat, with [additionalItems]
  /// added on top.
  PreparedMealBuildResult _templateMeal({
    required List<InventoryItem> currentItems,
    required PreparedMeal template,
    required int totalPortions,
    required Map<String, List<String>> recipeIngredientAssignments,
    required Map<String, RecipeIngredientAmountConversion>
    recipeIngredientAmountConversions,
    required TemplateIngredientParser ingredientParser,
    required Map<String, String> sourceKeysByIngredient,
    required List<PreparedMealItemInput> additionalItems,
  }) {
    final creationResult = buildPreparedMealCreationFromTemplateResult(
      currentItems: currentItems,
      preparedMealId: _writer.buildId(),
      now: _writer.buildNow(),
      template: template,
      totalPortions: totalPortions,
      recipeIngredientAssignments: recipeIngredientAssignments,
      recipeIngredientAmountConversions: recipeIngredientAmountConversions,
      ingredientParser: ingredientParser,
      sourceKeysByIngredient: sourceKeysByIngredient,
    );
    if (additionalItems.isEmpty) {
      return creationResult;
    }
    return appendItemsToTemplateMeal(
      creationResult: creationResult,
      additionalItems: additionalItems,
      now: _writer.buildNow(),
      buildId: _writer.buildId,
      template: template,
      totalPortions: totalPortions,
    );
  }
}
