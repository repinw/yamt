import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_calorie_log_bridge.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_consumption_workflows.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_creation_workflows.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_editing_workflows.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_workflow_context.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

/// Runs prepared meal business workflows outside the controller.
class PreparedMealMutationWorkflows {
  /// Creates prepared meal mutation workflows.
  PreparedMealMutationWorkflows({
    required this.loadMeals,
    required this.saveMeals,
    required this.restoreInventory,
    required this.publishMeals,
    required this.buildId,
    required this.buildNow,
    required this.logName,
  }) : _context = PreparedMealWorkflowContext(
         loadMeals: loadMeals,
         saveMeals: saveMeals,
         restoreInventory: restoreInventory,
         publishMeals: publishMeals,
         buildId: buildId,
         buildNow: buildNow,
         logName: logName,
       );

  /// Reads the latest prepared meals.
  final LoadPreparedMeals loadMeals;

  /// Persists prepared meal list updates.
  final SavePreparedMeals saveMeals;

  /// Restores inventory after a failed mutation.
  final RestoreInventoryItems restoreInventory;

  /// Publishes in-memory prepared meals during async work.
  final PublishPreparedMeals publishMeals;

  /// Builds ids for saved entities.
  final BuildMutationId buildId;

  /// Supplies timestamps for meal updates.
  final BuildMutationTime buildNow;

  /// Log name used for workflow diagnostics.
  final String logName;
  final PreparedMealWorkflowContext _context;

  /// Creates a prepared meal from explicit inventory selections.
  Future<PreparedMealCreationResult> createPreparedMeal({
    required String name,
    required int totalPortions,
    required List<PreparedMealItemInput> items,
    required String? imageAssetId,
    required InventoryItemRepository inventoryRepository,
  }) {
    return PreparedMealCreationWorkflows(
      context: _context,
    ).createPreparedMeal(
      name: name,
      totalPortions: totalPortions,
      items: items,
      imageAssetId: imageAssetId,
      inventoryRepository: inventoryRepository,
    );
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
  }) {
    return PreparedMealCreationWorkflows(
      context: _context,
    ).createPreparedMealFromTemplate(
      template: template,
      totalPortions: totalPortions,
      recipeIngredientAssignments: recipeIngredientAssignments,
      recipeIngredientAmountConversions: recipeIngredientAmountConversions,
      inventoryRepository: inventoryRepository,
      ingredientParser: ingredientParser,
      additionalItems: additionalItems,
      finalNetWeight: finalNetWeight,
      sourceKeysByIngredient: sourceKeysByIngredient,
    );
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
  }) {
    return PreparedMealCreationWorkflows(
      context: _context,
    ).createPreparedMealsFromTemplateContainers(
      template: template,
      totalPortions: totalPortions,
      recipeIngredientAssignments: recipeIngredientAssignments,
      recipeIngredientAmountConversions: recipeIngredientAmountConversions,
      inventoryRepository: inventoryRepository,
      ingredientParser: ingredientParser,
      containers: containers,
      sourceKeysByIngredient: sourceKeysByIngredient,
      additionalItems: additionalItems,
    );
  }

  /// Updates a prepared meal's editable details.
  Future<bool> updatePreparedMealDetails({
    required String mealId,
    required String name,
    required bool imageChanged,
    required String? imageAssetId,
    int? totalPortions,
    List<PreparedMealItemInput>? items,
    InventoryItemRepository? inventoryRepository,
  }) {
    return PreparedMealEditingWorkflows(
      context: _context,
    ).updatePreparedMealDetails(
      mealId: mealId,
      name: name,
      imageChanged: imageChanged,
      imageAssetId: imageAssetId,
      totalPortions: totalPortions,
      items: items,
      inventoryRepository: inventoryRepository,
    );
  }

  /// Fills one pending template ingredient with inventory.
  Future<bool> fillPreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
    required List<String> inventoryItemIds,
    required InventoryItemRepository inventoryRepository,
    required TemplateIngredientParser ingredientParser,
  }) {
    return PreparedMealEditingWorkflows(
      context: _context,
    ).fillPreparedMealPendingIngredient(
      mealId: mealId,
      ingredient: ingredient,
      inventoryItemIds: inventoryItemIds,
      inventoryRepository: inventoryRepository,
      ingredientParser: ingredientParser,
    );
  }

  /// Marks one pending ingredient as intentionally ignored.
  Future<bool> ignorePreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
  }) {
    return PreparedMealEditingWorkflows(
      context: _context,
    ).ignorePreparedMealPendingIngredient(
      mealId: mealId,
      ingredient: ingredient,
    );
  }

  /// Consumes prepared meal portions and forwards calorie logging.
  Future<bool> consumePreparedMeal({
    required String mealId,
    required num consumedPortions,
    required MealType mealType,
    required DateTime? loggedDay,
    required PreparedMealCalorieLogBridge calorieLogBridge,
  }) {
    return PreparedMealConsumptionWorkflows(
      context: _context,
    ).consumePreparedMeal(
      mealId: mealId,
      consumedPortions: consumedPortions,
      mealType: mealType,
      loggedDay: loggedDay,
      calorieLogBridge: calorieLogBridge,
    );
  }

  /// Discards prepared meal portions and persists a discard event.
  Future<bool> throwAwayPreparedMeal({
    required String mealId,
    required num discardedPortions,
    required InventoryDiscardReason reason,
    required InventoryDiscardEventRepository discardEventRepository,
  }) {
    return PreparedMealConsumptionWorkflows(
      context: _context,
    ).throwAwayPreparedMeal(
      mealId: mealId,
      discardedPortions: discardedPortions,
      reason: reason,
      discardEventRepository: discardEventRepository,
    );
  }

  /// Restores previously removed prepared meal portions.
  Future<bool> restorePreparedMealPortions({
    required String mealId,
    required num portions,
  }) {
    return PreparedMealEditingWorkflows(
      context: _context,
    ).restorePreparedMealPortions(mealId: mealId, portions: portions);
  }

  /// Restores all remaining ingredients from a prepared meal back to inventory.
  Future<bool> unbundlePreparedMeal({
    required String mealId,
    required InventoryItemRepository inventoryRepository,
  }) {
    return PreparedMealEditingWorkflows(
      context: _context,
    ).unbundlePreparedMeal(
      mealId: mealId,
      inventoryRepository: inventoryRepository,
    );
  }
}
