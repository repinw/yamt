import 'dart:developer' show log;

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_creation_workflows.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_stock_activity.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_workflow_context.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

part 'prepared_meal_cooking_service.g.dart';

const _logName = 'PreparedMealCookingService';

/// The service that turns cooked ingredient rows into a Vorrat meal.
@riverpod
PreparedMealCookingService preparedMealCookingService(Ref ref) {
  return PreparedMealCookingService(
    mealRepository: ref.watch(preparedMealRepositoryProvider),
    inventoryRepository: ref.watch(inventoryItemRepositoryProvider),
    activityRepository: ref.watch(inventoryActivityEventRepositoryProvider),
    actor: ref.watch(inventoryActivityActorProvider),
    ingredientParser: ref.watch(templateIngredientParserProvider),
    clock: ref.watch(clockProvider),
  );
}

/// Creates a Vorrat meal from ingredient rows without a saved recipe.
///
/// Rows with a Vorrat item take their amount from it; the other rows stay
/// open on the meal until the user fills them.
class PreparedMealCookingService {
  /// Creates the service.
  const new({
    required this._mealRepository,
    required this._inventoryRepository,
    required this._activityRepository,
    required this._actor,
    required this._ingredientParser,
    required this._clock,
  });

  final PreparedMealRepository _mealRepository;
  final InventoryItemRepository _inventoryRepository;
  final InventoryActivityEventRepository _activityRepository;
  final InventoryActivityActor? _actor;
  final TemplateIngredientParser _ingredientParser;
  final DateTime Function() _clock;

  /// Creates one meal named [name] from [ingredients] such as "500 g Reis".
  ///
  /// [assignments] maps an ingredient to the Vorrat item ids that supply it.
  /// A repository failure is rethrown after the Vorrat is restored.
  Future<PreparedMealCreationResult> cook({
    required String name,
    required List<String> ingredients,
    required Map<String, List<String>> assignments,
  }) async {
    final now = _clock();
    final recipe = PreparedMeal(
      id: '',
      name: name,
      totalPortions: 1,
      remainingPortions: 1,
      totalKcal: 0,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
      createdAt: now,
      updatedAt: now,
      components: const <PreparedMealComponent>[],
      recipeIngredients: ingredients,
    );
    final beforeItems = await _inventoryRepository.readAll();
    final trackingRepository = PreparedMealStockTrackingRepository(
      delegate: _inventoryRepository,
      initialItems: beforeItems,
    );
    final PreparedMealCreationResult result;
    try {
      result = await PreparedMealCreationWorkflows(context: _context)
          .createPreparedMealFromTemplate(
            template: recipe,
            totalPortions: 1,
            recipeIngredientAssignments: assignments,
            recipeIngredientAmountConversions:
                const <String, RecipeIngredientAmountConversion>{},
            inventoryRepository: trackingRepository,
            ingredientParser: _ingredientParser,
          );
    } on Object {
      // The Vorrat is already reduced when saving the meal throws.
      if (!const ListEquality<InventoryItem>().equals(
        trackingRepository.latestItems,
        beforeItems,
      )) {
        await _restoreInventory(
          inventoryRepository: _inventoryRepository,
          previousItems: beforeItems,
        );
      }
      rethrow;
    }
    if (result.isSuccess) {
      await recordPreparedMealStockActivity(
        actor: _actor,
        activityRepository: _activityRepository,
        beforeItems: beforeItems,
        afterItems: trackingRepository.latestItems,
        buildId: _newId,
        logName: _logName,
      );
    }
    return result;
  }

  PreparedMealWorkflowContext get _context {
    return PreparedMealWorkflowContext(
      loadMeals: _mealRepository.readAll,
      saveMeals: _saveMeals,
      restoreInventory: _restoreInventory,
      publishMeals: (_) {},
      buildId: _newId,
      buildNow: _clock,
      logName: _logName,
    );
  }

  Future<bool> _saveMeals({
    required List<PreparedMeal> previousMeals,
    required List<PreparedMeal> nextMeals,
  }) {
    return _mealRepository.saveAll(nextMeals);
  }

  Future<void> _restoreInventory({
    required InventoryItemRepository inventoryRepository,
    required List<InventoryItem> previousItems,
  }) async {
    try {
      await inventoryRepository.saveAll(previousItems);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to restore the Vorrat after a failed cook.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String _newId() => const Uuid().v4();
}
