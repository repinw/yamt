import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_creation.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_discard.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_editing.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/prepared_meal_open_rows.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_pending_item_fill.dart';
import 'package:yamt/features/inventory/application/prepared_meal_writer.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_pot_weighing.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

part 'prepared_meal_mutation_service.g.dart';

const _logName = 'PreparedMealMutationService';

/// The one queue of the meal mutations, so they run one after the other
/// also across rebuilds of [preparedMealMutationServiceProvider].
@Riverpod(keepAlive: true)
SerializedMutationQueue preparedMealMutationQueue(Ref ref) =>
    SerializedMutationQueue();

/// The prepared meal mutations provider.
@riverpod
PreparedMealMutationService preparedMealMutationService(Ref ref) {
  return PreparedMealMutationService(
    queue: ref.watch(preparedMealMutationQueueProvider),
    meals: ref.watch(preparedMealRepositoryProvider),
    inventory: ref.watch(inventoryItemRepositoryProvider),
    discardEvents: ref.watch(inventoryDiscardEventRepositoryProvider),
    activity: ref.watch(inventoryActivityEventRepositoryProvider),
    actor: ref.watch(inventoryActivityActorProvider),
    ingredientParser: ref.watch(templateIngredientParserProvider),
    clock: ref.watch(clockProvider),
  );
}

/// Creates and changes Vorrat meals.
///
/// A failed read or write throws; the callers decide what the user sees.
/// Each mutation reads the stored meals and the Vorrat, changes them, writes
/// only the meals it changed, and writes the Vorrat back when the meal write
/// fails. Mutations run one after the other, and the stock a mutation takes
/// or returns lands in the Vorrat history.
class PreparedMealMutationService {
  /// Creates the mutations.
  new({
    required this._queue,
    required PreparedMealRepository meals,
    required this._inventory,
    required this._discardEvents,
    required this._activity,
    required this._actor,
    required this._ingredientParser,
    required DateTime Function() clock,
    String Function()? newId,
  }) : _writer = PreparedMealWriter(
         meals: meals,
         clock: clock,
         logName: _logName,
         newId: newId,
       ),
       _potWriter = PreparedMealWriter(
         meals: meals,
         clock: clock,
         logName: _logName,
         newMealsInPot: true,
         newId: newId,
       );

  final InventoryItemRepository _inventory;
  final InventoryDiscardEventRepository _discardEvents;
  final InventoryActivityEventRepository _activity;
  final InventoryActivityActor? _actor;
  final TemplateIngredientParser _ingredientParser;
  final PreparedMealWriter _writer;

  /// Writes meals that start open, waiting for their "Gekocht" step.
  final PreparedMealWriter _potWriter;
  final SerializedMutationQueue _queue;

  /// Creates a meal from explicit Vorrat selections. With [startInPot] the
  /// meal stays open until its "Gekocht" step sets its portions.
  Future<PreparedMealCreationResult> createPreparedMeal({
    required String name,
    required int totalPortions,
    required List<PreparedMealItemInput> items,
    String? imageAssetId,
    bool startInPot = false,
  }) => _create(
    (inventory) =>
        PreparedMealCreation(writer: startInPot ? _potWriter : _writer)
            .createPreparedMeal(
              name: name,
              totalPortions: totalPortions,
              items: items,
              imageAssetId: imageAssetId,
              inventoryRepository: inventory,
            ),
  );

  /// Creates meals from one template, split into storage containers.
  Future<PreparedMealCreationResult> createPreparedMealsFromTemplateContainers({
    required PreparedMeal template,
    required int totalPortions,
    required Map<String, List<String>> recipeIngredientAssignments,
    required Map<String, RecipeIngredientAmountConversion>
    recipeIngredientAmountConversions,
    required List<PreparedMealContainerInput> containers,
    required Map<String, String> sourceKeysByIngredient,
    List<PreparedMealItemInput> additionalItems =
        const <PreparedMealItemInput>[],
  }) => _create(
    (inventory) => PreparedMealCreation(writer: _writer)
        .createPreparedMealsFromTemplateContainers(
          template: template,
          totalPortions: totalPortions,
          recipeIngredientAssignments: recipeIngredientAssignments,
          recipeIngredientAmountConversions: recipeIngredientAmountConversions,
          inventoryRepository: inventory,
          ingredientParser: _ingredientParser,
          containers: containers,
          sourceKeysByIngredient: sourceKeysByIngredient,
          additionalItems: additionalItems,
        ),
  );

  /// Changes a meal's name, image, portions or ingredients.
  Future<bool> updatePreparedMealDetails({
    required String mealId,
    required String name,
    bool imageChanged = false,
    String? imageAssetId,
    int? totalPortions,
    List<PreparedMealItemInput>? items,
  }) => _change(
    (inventory) =>
        PreparedMealEditing(writer: _writer).updatePreparedMealDetails(
          mealId: mealId,
          name: name,
          imageChanged: imageChanged,
          imageAssetId: imageAssetId,
          totalPortions: totalPortions,
          items: items,
          inventoryRepository: inventory,
        ),
  );

  /// Fills the open row [ingredient] with the Vorrat items [inventoryItemIds].
  Future<bool> fillPreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
    required List<String> inventoryItemIds,
  }) => _change(
    (inventory) =>
        PreparedMealOpenRows(writer: _writer).fillPreparedMealPendingIngredient(
          mealId: mealId,
          ingredient: ingredient,
          inventoryItemIds: inventoryItemIds,
          inventoryRepository: inventory,
          ingredientParser: _ingredientParser,
        ),
  );

  /// Fills the open row [ingredient] with [usedAmount] of the item [itemId].
  Future<bool> fillPreparedMealPendingIngredientWithItem({
    required String mealId,
    required String ingredient,
    required String itemId,
    required int usedAmount,
  }) => _change(
    (inventory) => PreparedMealPendingItemFill(writer: _writer).fill(
      mealId: mealId,
      ingredient: ingredient,
      itemId: itemId,
      usedAmount: usedAmount,
      inventoryRepository: inventory,
    ),
  );

  /// Marks the open row [ingredient] as left out on purpose.
  Future<bool> ignorePreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
  }) => _run(
    () => PreparedMealOpenRows(writer: _writer)
        .ignorePreparedMealPendingIngredient(
          mealId: mealId,
          ingredient: ingredient,
        ),
  );

  /// Throws away [discardedPortions] of a meal and records why.
  Future<bool> throwAwayPreparedMeal({
    required String mealId,
    required num discardedPortions,
    required InventoryDiscardReason reason,
  }) => _run(
    () => PreparedMealDiscard(writer: _writer).throwAwayPreparedMeal(
      mealId: mealId,
      discardedPortions: discardedPortions,
      reason: reason,
      discardEventRepository: _discardEvents,
    ),
  );

  /// Gives the remaining ingredients of a meal back to the Vorrat.
  Future<bool> unbundlePreparedMeal(String mealId) => _change(
    (inventory) => PreparedMealEditing(writer: _writer)
        .unbundlePreparedMeal(mealId: mealId, inventoryRepository: inventory),
  );

  /// Stores that the pot of the cooked meal [mealId] holds [netWeight] grams
  /// of food now, for everyone in the household who eats from it next.
  /// Returns the meal with the weighing. Throws when the meal is gone, was
  /// not weighed in its pot, or the write fails.
  Future<PreparedMeal> weighPot({
    required String mealId,
    required int netWeight,
  }) => _queue.enqueue(() async {
    final meals = await _writer.loadMeals();
    final index = meals.indexWhere((meal) => meal.id == mealId);
    if (index < 0) {
      throw StateError('Meal $mealId is gone.');
    }
    final meal = meals[index];
    if (meal.potTareWeight == null || netWeight < 1) {
      throw StateError('Meal $mealId was not weighed in its pot.');
    }
    final now = _writer.buildNow();
    final weighed = meal.copyWith(
      potWeighing: PreparedMealPotWeighing(
        netWeight: netWeight,
        weighedAt: now,
        remainingPortions: meal.remainingPortions,
      ),
      updatedAt: now,
    );
    final saved = await _writer.saveMeals(
      previousMeals: meals,
      nextMeals: [...meals]..[index] = weighed,
    );
    if (!saved) {
      throw StateError('Pot weighing of $mealId could not be saved.');
    }
    return weighed;
  });

  Future<PreparedMealCreationResult> _create(
    Future<PreparedMealCreationResult> Function(InventoryItemRepository)
    operation,
  ) => _queue.enqueue(() => _tracked(operation, (result) => result.isSuccess));

  Future<bool> _change(
    Future<bool> Function(InventoryItemRepository) operation,
  ) => _run(() => _tracked(operation, (saved) => saved));

  Future<bool> _run(Future<bool> Function() operation) =>
      _queue.enqueue(operation);

  Future<T> _tracked<T>(
    Future<T> Function(InventoryItemRepository) operation,
    bool Function(T) succeeded,
  ) => _writer.trackStock(
    inventory: _inventory,
    activity: _activity,
    actor: _actor,
    operation: operation,
    succeeded: succeeded,
  );
}
