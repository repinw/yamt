import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_pending_ingredient_support.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_workflow_context.dart';
import 'package:yamt/features/inventory/application/'
    'template_ingredient_parser.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Handles prepared meal editing and inventory reconciliation workflows.
class PreparedMealEditingWorkflows {
  /// Creates editing workflows.
  const PreparedMealEditingWorkflows({
    required PreparedMealWorkflowContext context,
  }) : _context = context;

  final PreparedMealWorkflowContext _context;

  /// Updates a prepared meal's editable details.
  Future<bool> updatePreparedMealDetails({
    required String mealId,
    required String name,
    required bool imageChanged,
    required String? imageAssetId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return false;
    }

    final currentMeals = await _context.loadMeals();
    final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
    if (mealIndex < 0) {
      return false;
    }

    final currentMeal = currentMeals[mealIndex];
    final normalizedImageAssetId = imageChanged
        ? normalizeOptionalImageAssetId(imageAssetId)
        : currentMeal.imageAssetId;
    final isUnchanged =
        currentMeal.name == trimmedName &&
        (!imageChanged || currentMeal.imageAssetId == normalizedImageAssetId);
    if (isUnchanged) {
      return true;
    }

    final nextMeals = List<PreparedMeal>.from(currentMeals);
    final updatedAt = _context.buildNow();
    nextMeals[mealIndex] = imageChanged
        ? currentMeal.copyWith(
            name: trimmedName,
            imageAssetId: normalizedImageAssetId,
            updatedAt: updatedAt,
          )
        : currentMeal.copyWith(name: trimmedName, updatedAt: updatedAt);
    return _context.saveMeals(
      previousMeals: currentMeals,
      nextMeals: nextMeals,
    );
  }

  /// Fills one pending template ingredient with inventory.
  Future<bool> fillPreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
    required List<String> inventoryItemIds,
    required InventoryItemRepository inventoryRepository,
    required TemplateIngredientParser ingredientParser,
  }) async {
    final trimmedIngredient = ingredient.trim();
    final normalizedItemIds = inventoryItemIds
        .map((itemId) => itemId.trim())
        .where((itemId) => itemId.isNotEmpty)
        .toList(growable: false);
    if (trimmedIngredient.isEmpty || normalizedItemIds.isEmpty) {
      return false;
    }

    final currentMeals = await _context.loadMeals();
    final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
    if (mealIndex < 0) {
      return false;
    }

    final currentMeal = currentMeals[mealIndex];
    final pendingIndex = currentMeal.pendingRecipeIngredients.indexWhere(
      (entry) => entry.trim() == trimmedIngredient,
    );
    if (pendingIndex < 0) {
      return false;
    }

    final currentItems = await inventoryRepository.readAll();
    final fillResult = buildPreparedMealPendingIngredientFillResult(
      currentItems: currentItems,
      ingredient: trimmedIngredient,
      inventoryItemIds: normalizedItemIds,
      ingredientParser: ingredientParser,
    );
    if (fillResult == null) {
      return false;
    }

    final inventorySaved = await inventoryRepository.saveAll(
      fillResult.nextItems,
    );
    if (!inventorySaved) {
      return false;
    }

    final nextPendingIngredients = List<String>.from(
      currentMeal.pendingRecipeIngredients,
    )..removeAt(pendingIndex);
    if (fillResult.remainingIngredient != null) {
      nextPendingIngredients.insert(
        pendingIndex,
        fillResult.remainingIngredient!,
      );
    }

    final nextComponents = <PreparedMealComponent>[
      ...currentMeal.components,
      ...fillResult.components,
    ];
    final nutritionTotals = nextComponents.nutritionTotals;
    final nextMeals = List<PreparedMeal>.from(currentMeals);
    nextMeals[mealIndex] = currentMeal.copyWith(
      components: nextComponents,
      pendingRecipeIngredients: nextPendingIngredients,
      totalKcal: nutritionTotals.totalKcal,
      totalProtein: nutritionTotals.totalProtein,
      totalCarbs: nutritionTotals.totalCarbs,
      totalFat: nutritionTotals.totalFat,
      updatedAt: _context.buildNow(),
    );

    final mealsSaved = await _context.saveMeals(
      previousMeals: currentMeals,
      nextMeals: nextMeals,
    );
    if (mealsSaved) {
      return true;
    }

    await _context.restoreInventory(
      inventoryRepository: inventoryRepository,
      previousItems: currentItems,
    );
    return false;
  }

  /// Marks one pending ingredient as intentionally ignored.
  Future<bool> ignorePreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
  }) async {
    final trimmedIngredient = ingredient.trim();
    if (trimmedIngredient.isEmpty) {
      return false;
    }

    final currentMeals = await _context.loadMeals();
    final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
    if (mealIndex < 0) {
      return false;
    }

    final currentMeal = currentMeals[mealIndex];
    final nextPendingIngredients = currentMeal.pendingRecipeIngredients
        .where((entry) => entry.trim() != trimmedIngredient)
        .toList(growable: false);
    if (nextPendingIngredients.length ==
        currentMeal.pendingRecipeIngredients.length) {
      return false;
    }

    final nextMeals = List<PreparedMeal>.from(currentMeals);
    nextMeals[mealIndex] = currentMeal.copyWith(
      pendingRecipeIngredients: nextPendingIngredients,
      updatedAt: _context.buildNow(),
    );
    return _context.saveMeals(
      previousMeals: currentMeals,
      nextMeals: nextMeals,
    );
  }

  /// Restores previously removed prepared meal portions.
  Future<bool> restorePreparedMealPortions({
    required String mealId,
    required int portions,
  }) async {
    if (portions < 1) {
      _context.logMessage(
        'restorePreparedMealPortions(): invalid portions=$portions '
        '(mealId=$mealId)',
      );
      return false;
    }

    _context.logMessage(
      'restorePreparedMealPortions(): starting '
      '(mealId=$mealId, portions=$portions)',
    );
    final currentMeals = await _context.loadMeals();
    final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
    if (mealIndex < 0) {
      _context.logMessage(
        'restorePreparedMealPortions(): meal not found '
        '(mealId=$mealId, portions=$portions, '
        'knownMeals=${currentMeals.length})',
      );
      return false;
    }

    final meal = currentMeals[mealIndex];
    final nextRemainingPortions = meal.remainingPortions + portions;
    if (nextRemainingPortions > meal.totalPortions) {
      _context.logMessage(
        'restorePreparedMealPortions(): restore exceeds total portions '
        '(mealId=$mealId, nextRemaining=$nextRemainingPortions, '
        'totalPortions=${meal.totalPortions})',
      );
      return false;
    }

    final nextMeals = List<PreparedMeal>.from(currentMeals);
    nextMeals[mealIndex] = meal.copyWith(
      remainingPortions: nextRemainingPortions,
      updatedAt: _context.buildNow(),
    );
    final saved = await _context.saveMeals(
      previousMeals: currentMeals,
      nextMeals: nextMeals,
    );
    if (!saved) {
      _context.logMessage(
        'restorePreparedMealPortions(): failed to save restored portions '
        '(mealId=$mealId)',
      );
      return false;
    }

    _context.logMessage(
      'restorePreparedMealPortions(): succeeded '
      '(mealId=$mealId, remainingPortions=${meal.remainingPortions}, '
      'nextRemainingPortions=$nextRemainingPortions)',
    );
    return true;
  }

  /// Restores all remaining ingredients from a prepared meal back to inventory.
  Future<bool> unbundlePreparedMeal({
    required String mealId,
    required InventoryItemRepository inventoryRepository,
  }) async {
    final currentMeals = await _context.loadMeals();
    final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
    if (mealIndex < 0) {
      return false;
    }

    final meal = currentMeals[mealIndex];
    final currentItems = await inventoryRepository.readAll();
    final restoredItems = restoreItemsFromPreparedMeal(
      currentItems: currentItems,
      meal: meal,
    );

    final inventorySaved = await inventoryRepository.saveAll(restoredItems);
    if (!inventorySaved) {
      return false;
    }

    final nextMeals = List<PreparedMeal>.from(currentMeals)
      ..removeAt(mealIndex);
    final mealsSaved = await _context.saveMeals(
      previousMeals: currentMeals,
      nextMeals: nextMeals,
    );
    if (mealsSaved) {
      return true;
    }

    await _context.restoreInventory(
      inventoryRepository: inventoryRepository,
      previousItems: currentItems,
    );
    return false;
  }
}
