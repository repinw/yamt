import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_creation_workflows.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_writer.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
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

/// Creates a Vorrat meal from ingredient rows without a saved recipe and
/// marks it as cooked later.
///
/// Rows with a Vorrat item take their amount from it; the other rows stay
/// open on the meal until the user fills them. The meal stays in the pot
/// until [PreparedMealCookingService.finishCooking].
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
    return await _writer.trackStock(
      inventory: _inventoryRepository,
      activity: _activityRepository,
      actor: _actor,
      operation: (inventory) =>
          PreparedMealCreationWorkflows(writer: _writer)
              .createPreparedMealFromTemplate(
                template: recipe,
                totalPortions: 1,
                recipeIngredientAssignments: assignments,
                recipeIngredientAmountConversions:
                    const <String, RecipeIngredientAmountConversion>{},
                inventoryRepository: inventory,
                ingredientParser: _ingredientParser,
              ),
      succeeded: (result) => result.isSuccess,
    );
  }

  /// Marks the meal [mealId] as cooked: it makes [totalPortions] portions,
  /// and [potTareWeight] and [finalNetWeight] are set when the cook weighed
  /// the pot. Portions eaten so far keep their share. Returns the cooked
  /// meal. Throws when the meal is gone or no longer in the pot.
  Future<PreparedMeal> finishCooking({
    required String mealId,
    required int totalPortions,
    required int? potTareWeight,
    required int? finalNetWeight,
  }) async {
    final meals = await _mealRepository.readAll();
    final meal = meals.firstWhere(
      (meal) => meal.id == mealId,
      orElse: () => throw StateError('Meal $mealId is gone.'),
    );
    if (!meal.isInPot) {
      // Another device already marked it as cooked.
      throw StateError('Meal $mealId is not in the pot.');
    }
    final cooked = meal.copyWith(
      totalPortions: totalPortions,
      remainingPortions: meal.remainingRatio * totalPortions,
      potTareWeight: potTareWeight,
      finalNetWeight: finalNetWeight,
      inPot: null,
      updatedAt: _clock(),
    );
    final saved = await _mealRepository.save(cooked);
    if (!saved) {
      throw StateError('Meal $mealId could not be saved.');
    }
    return cooked;
  }

  PreparedMealWriter get _writer => PreparedMealWriter(
    meals: _mealRepository,
    clock: _clock,
    logName: _logName,
    newMealsInPot: true,
  );
}
