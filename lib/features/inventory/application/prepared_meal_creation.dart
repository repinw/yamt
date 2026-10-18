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
    final currentItems = await inventoryRepository.readAllForChange();

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
  }) async {
    if (totalPortions < 1 || template.name.trim().isEmpty) {
      return const PreparedMealCreationResult.failure(
        PreparedMealCreationFailureReason.invalidInput,
      );
    }

    final currentMeals = await _writer.loadMeals();
    final currentItems = await inventoryRepository.readAllForChange();

    try {
      return await _persistCreatedMeal(
        inventoryRepository: inventoryRepository,
        currentMeals: currentMeals,
        currentItems: currentItems,
        creationResult: buildPreparedMealCreationFromTemplateResult(
          currentItems: currentItems,
          preparedMealId: _writer.buildId(),
          now: _writer.buildNow(),
          template: template,
          totalPortions: totalPortions,
          recipeIngredientAssignments: recipeIngredientAssignments,
          recipeIngredientAmountConversions: recipeIngredientAmountConversions,
          ingredientParser: ingredientParser,
        ),
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
    final nextItems = creationResult.nextItems;
    final preparedMeal = creationResult.preparedMeal;
    final inventorySaved = await inventoryRepository.saveChanges(
      previous: currentItems,
      next: nextItems,
    );
    if (!inventorySaved) {
      return const PreparedMealCreationResult.failure(
        PreparedMealCreationFailureReason.inventorySaveFailed,
      );
    }

    final nextMeals = [...currentMeals, preparedMeal];
    final mealsSaved = await _writer.saveMeals(
      previousMeals: currentMeals,
      nextMeals: nextMeals,
    );
    if (mealsSaved) {
      return PreparedMealCreationResult.success(preparedMeal.id);
    }

    await _writer.restoreInventory(
      inventoryRepository: inventoryRepository,
      writtenItems: nextItems,
      previousItems: currentItems,
    );
    return const PreparedMealCreationResult.failure(
      PreparedMealCreationFailureReason.mealSaveFailed,
    );
  }
}
