import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_support.dart';
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
  }) async {
    if (totalPortions < 1 || template.name.trim().isEmpty) {
      return const PreparedMealCreationResult.failure(
        PreparedMealCreationFailureReason.invalidInput,
      );
    }

    final currentMeals = await _context.loadMeals();
    final currentItems = await inventoryRepository.readAll();

    try {
      final creationResult = buildPreparedMealCreationFromTemplateResult(
        currentItems: currentItems,
        preparedMealId: _context.buildId(),
        now: _context.buildNow(),
        template: template,
        totalPortions: totalPortions,
        recipeIngredientAssignments: recipeIngredientAssignments,
        recipeIngredientAmountConversions: recipeIngredientAmountConversions,
        ingredientParser: ingredientParser,
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

  Future<PreparedMealCreationResult> _persistCreatedMeal({
    required InventoryItemRepository inventoryRepository,
    required List<PreparedMeal> currentMeals,
    required List<InventoryItem> currentItems,
    required PreparedMealBuildResult creationResult,
  }) async {
    final inventorySaved = await inventoryRepository.saveAll(
      creationResult.nextItems,
    );
    if (!inventorySaved) {
      return const PreparedMealCreationResult.failure(
        PreparedMealCreationFailureReason.inventorySaveFailed,
      );
    }

    final nextMeals = List<PreparedMeal>.from(currentMeals)
      ..add(creationResult.preparedMeal);
    final mealsSaved = await _context.saveMeals(
      previousMeals: currentMeals,
      nextMeals: nextMeals,
    );
    if (mealsSaved) {
      return PreparedMealCreationResult.success(creationResult.preparedMeal.id);
    }

    await _context.restoreInventory(
      inventoryRepository: inventoryRepository,
      previousItems: currentItems,
    );
    return const PreparedMealCreationResult.failure(
      PreparedMealCreationFailureReason.mealSaveFailed,
    );
  }
}
