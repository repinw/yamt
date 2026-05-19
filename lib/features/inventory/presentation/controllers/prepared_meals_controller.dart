import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_calorie_log_bridge.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_household_recovery.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_workflows.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

export 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart'
    show
        PreparedMealContainerInput,
        PreparedMealCreationFailureReason,
        PreparedMealCreationResult,
        PreparedMealItemInput;

part 'prepared_meals_controller.g.dart';

const _preparedMealsControllerLogName = 'PreparedMealsController';

/// Defines prepared meals controller.
@Riverpod(
  dependencies: [
    inventoryActivityEventRepository,
    inventoryDiscardEventRepository,
    inventoryItemRepository,
    preparedMealCalorieLogBridge,
  ],
)
class PreparedMealsController extends _$PreparedMealsController {
  // Subscription is cancelled by `_disposeSubscription`.
  // ignore: cancel_subscriptions
  StreamSubscription<List<PreparedMeal>>? _mealsSubscription;
  int _subscriptionGeneration = 0;
  final _mutationQueue = SerializedMutationQueue();
  String? _currentDataOwnerUserId;
  bool _isRecoveringHouseholdAccess = false;

  PreparedMealMutationWorkflows get _mutationWorkflows {
    return PreparedMealMutationWorkflows(
      loadMeals: _currentMeals,
      saveMeals: _saveMeals,
      restoreInventory: _restoreInventory,
      publishMeals: (meals) {
        if (!ref.mounted) {
          return;
        }
        state = AsyncData(meals);
      },
      buildId: _newId,
      buildNow: DateTime.now,
      logName: _preparedMealsControllerLogName,
    );
  }

  @override
  FutureOr<List<PreparedMeal>> build() async {
    ref
      ..watch(householdDataOwnerUserIdProvider)
      ..watch(preparedMealRepositoryProvider)
      ..onDispose(() {
        unawaited(_disposeSubscription());
      });
    await waitForHouseholdDataOwnerProfile(ref);
    if (!ref.mounted) {
      return const <PreparedMeal>[];
    }
    _currentDataOwnerUserId = ref.watch(
      effectiveHouseholdDataOwnerUserIdProvider,
    );
    return _restartSubscription();
  }

  /// Refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(_restartSubscription);
    if (!ref.mounted) {
      return;
    }
    state = next;
  }

  /// Create prepared meal.
  Future<PreparedMealCreationResult> createPreparedMeal({
    required String name,
    required int totalPortions,
    required List<PreparedMealItemInput> items,
    String? imageAssetId,
  }) {
    return _runCreationMutation(
      operation: () => _runInventoryTrackedCreation(
        (inventoryRepository) => _mutationWorkflows.createPreparedMeal(
          name: name,
          totalPortions: totalPortions,
          items: items,
          imageAssetId: imageAssetId,
          inventoryRepository: inventoryRepository,
        ),
      ),
      unexpectedErrorMessage: 'Unexpected prepared meal creation error.',
    );
  }

  /// Create prepared meal from template.
  Future<PreparedMealCreationResult> createPreparedMealFromTemplate({
    required PreparedMeal template,
    required int totalPortions,
    required Map<String, List<String>> recipeIngredientAssignments,
    required Map<String, RecipeIngredientAmountConversion>
    recipeIngredientAmountConversions,
    List<PreparedMealItemInput> additionalItems =
        const <PreparedMealItemInput>[],
    int? finalNetWeight,
    Map<String, String> sourceKeysByIngredient = const <String, String>{},
  }) {
    return _runCreationMutation(
      operation: () => _runInventoryTrackedCreation(
        (inventoryRepository) =>
            _mutationWorkflows.createPreparedMealFromTemplate(
              template: template,
              totalPortions: totalPortions,
              recipeIngredientAssignments: recipeIngredientAssignments,
              recipeIngredientAmountConversions:
                  recipeIngredientAmountConversions,
              inventoryRepository: inventoryRepository,
              ingredientParser: ref.read(templateIngredientParserProvider),
              additionalItems: additionalItems,
              finalNetWeight: finalNetWeight,
              sourceKeysByIngredient: sourceKeysByIngredient,
            ),
      ),
      unexpectedErrorMessage: 'Unexpected template meal creation error.',
    );
  }

  /// Create prepared meals from a template split into storage containers.
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
  }) {
    return _runCreationMutation(
      operation: () => _runInventoryTrackedCreation(
        (inventoryRepository) =>
            _mutationWorkflows.createPreparedMealsFromTemplateContainers(
              template: template,
              totalPortions: totalPortions,
              recipeIngredientAssignments: recipeIngredientAssignments,
              recipeIngredientAmountConversions:
                  recipeIngredientAmountConversions,
              inventoryRepository: inventoryRepository,
              ingredientParser: ref.read(templateIngredientParserProvider),
              containers: containers,
              sourceKeysByIngredient: sourceKeysByIngredient,
              additionalItems: additionalItems,
            ),
      ),
      unexpectedErrorMessage: 'Unexpected split template meal creation error.',
    );
  }

  /// Update prepared meal details.
  Future<bool> updatePreparedMealDetails({
    required String mealId,
    required String name,
    bool imageChanged = false,
    String? imageAssetId,
    int? totalPortions,
    List<PreparedMealItemInput>? items,
  }) {
    final keepAliveLink = ref.keepAlive();
    return _runSerializedMutation(
      () => _runInventoryTrackedBool(
        (inventoryRepository) => _mutationWorkflows.updatePreparedMealDetails(
          mealId: mealId,
          name: name,
          imageChanged: imageChanged,
          imageAssetId: imageAssetId,
          totalPortions: totalPortions,
          items: items,
          inventoryRepository: inventoryRepository,
        ),
      ),
    ).whenComplete(keepAliveLink.close);
  }

  /// Fill prepared meal pending ingredient.
  Future<bool> fillPreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
    required List<String> inventoryItemIds,
  }) {
    final keepAliveLink = ref.keepAlive();
    return _runSerializedMutation(
      () => _runInventoryTrackedBool(
        (inventoryRepository) =>
            _mutationWorkflows.fillPreparedMealPendingIngredient(
              mealId: mealId,
              ingredient: ingredient,
              inventoryItemIds: inventoryItemIds,
              inventoryRepository: inventoryRepository,
              ingredientParser: ref.read(templateIngredientParserProvider),
            ),
      ),
    ).whenComplete(keepAliveLink.close);
  }

  /// Ignore prepared meal pending ingredient.
  Future<bool> ignorePreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
  }) {
    final keepAliveLink = ref.keepAlive();
    return _runSerializedMutation(
      () => _mutationWorkflows.ignorePreparedMealPendingIngredient(
        mealId: mealId,
        ingredient: ingredient,
      ),
    ).whenComplete(keepAliveLink.close);
  }

  /// Consume prepared meal.
  Future<bool> consumePreparedMeal({
    required String mealId,
    required num consumedPortions,
    required MealType mealType,
    DateTime? loggedDay,
  }) {
    final keepAliveLink = ref.keepAlive();
    final calorieEntriesSubscription = ref.listen(
      calorieEntriesControllerProvider,
      (_, _) {},
    );
    return _runSerializedMutation(
      () => _mutationWorkflows.consumePreparedMeal(
        mealId: mealId,
        consumedPortions: consumedPortions,
        mealType: mealType,
        loggedDay: loggedDay,
        calorieLogBridge: ref.read(preparedMealCalorieLogBridgeProvider),
      ),
    ).whenComplete(() {
      calorieEntriesSubscription.close();
      keepAliveLink.close();
    });
  }

  /// Throw away prepared meal.
  Future<bool> throwAwayPreparedMeal({
    required String mealId,
    required num discardedPortions,
    required InventoryDiscardReason reason,
  }) {
    final keepAliveLink = ref.keepAlive();
    return _runSerializedMutation(
      () => _mutationWorkflows.throwAwayPreparedMeal(
        mealId: mealId,
        discardedPortions: discardedPortions,
        reason: reason,
        discardEventRepository: ref.read(
          inventoryDiscardEventRepositoryProvider,
        ),
      ),
    ).whenComplete(keepAliveLink.close);
  }

  /// Restore prepared meal portions.
  Future<bool> restorePreparedMealPortions({
    required String mealId,
    required num portions,
  }) {
    final keepAliveLink = ref.keepAlive();
    return _runSerializedMutation(
      () => _mutationWorkflows.restorePreparedMealPortions(
        mealId: mealId,
        portions: portions,
      ),
    ).whenComplete(keepAliveLink.close);
  }

  /// Unbundle prepared meal.
  Future<bool> unbundlePreparedMeal(String mealId) {
    final keepAliveLink = ref.keepAlive();
    return _runSerializedMutation(
      () => _runInventoryTrackedBool(
        (inventoryRepository) => _mutationWorkflows.unbundlePreparedMeal(
          mealId: mealId,
          inventoryRepository: inventoryRepository,
        ),
      ),
    ).whenComplete(keepAliveLink.close);
  }

  Future<List<PreparedMeal>> _currentMeals() async {
    final currentData = state.asData?.value;
    if (currentData != null) {
      return currentData;
    }
    return future;
  }

  Future<List<PreparedMeal>> _restartSubscription() async {
    final initialMeals = Completer<List<PreparedMeal>>();
    _currentDataOwnerUserId = ref.read(
      effectiveHouseholdDataOwnerUserIdProvider,
    );
    final repository = ref.read(preparedMealRepositoryProvider);
    final generation = ++_subscriptionGeneration;
    await _disposeSubscription();

    _mealsSubscription = repository.watchAll().listen(
      (meals) {
        if (generation != _subscriptionGeneration) {
          return;
        }
        if (!initialMeals.isCompleted) {
          initialMeals.complete(meals);
          return;
        }
        _onRealtimeMeals(meals);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (generation != _subscriptionGeneration) {
          return;
        }
        if (!initialMeals.isCompleted) {
          if (_shouldRecoverFromRevokedHouseholdAccess(error)) {
            initialMeals.complete(const <PreparedMeal>[]);
            unawaited(_recoverFromRevokedHouseholdAccess(showLoading: false));
            return;
          }
          initialMeals.completeError(error, stackTrace);
          return;
        }
        _onRealtimeError(error, stackTrace);
      },
    );

    return initialMeals.future;
  }

  Future<void> _disposeSubscription() async {
    final currentSubscription = _mealsSubscription;
    _mealsSubscription = null;
    if (currentSubscription != null) {
      await currentSubscription.cancel();
    }
  }

  void _onRealtimeMeals(List<PreparedMeal> meals) {
    if (!ref.mounted) {
      return;
    }
    state = AsyncData(meals);
  }

  void _onRealtimeError(Object error, StackTrace stackTrace) {
    if (_shouldRecoverFromRevokedHouseholdAccess(error)) {
      unawaited(_recoverFromRevokedHouseholdAccess());
      return;
    }
    if (!ref.mounted) {
      return;
    }
    state = AsyncError(error, stackTrace);
  }

  bool _shouldRecoverFromRevokedHouseholdAccess(Object error) {
    return shouldRecoverPreparedMealHouseholdAccess(
      ref: ref,
      error: error,
      isRecoveringHouseholdAccess: _isRecoveringHouseholdAccess,
      currentHouseholdDataOwnerUserId: _currentDataOwnerUserId,
    );
  }

  Future<void> _recoverFromRevokedHouseholdAccess({bool showLoading = true}) {
    return recoverPreparedMealHouseholdAccess(
      ref: ref,
      isRecoveringHouseholdAccess: _isRecoveringHouseholdAccess,
      setIsRecoveringHouseholdAccess: ({required value}) {
        _isRecoveringHouseholdAccess = value;
      },
      setState: (nextState) {
        state = nextState;
      },
      restartSubscription: _restartSubscription,
      currentHouseholdDataOwnerUserId: _currentDataOwnerUserId,
      logName: _preparedMealsControllerLogName,
      showLoading: showLoading,
    );
  }

  Future<bool> _saveMeals({
    required List<PreparedMeal> previousMeals,
    required List<PreparedMeal> nextMeals,
  }) async {
    if (ref.mounted) {
      state = AsyncData(nextMeals);
    }

    try {
      final saved = await ref
          .read(preparedMealRepositoryProvider)
          .saveAll(nextMeals);
      if (!saved && ref.mounted) {
        state = AsyncData(previousMeals);
      }
      return saved;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to persist prepared meal mutation.',
        name: _preparedMealsControllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
      if (ref.mounted) {
        state = AsyncData(previousMeals);
      }
      return false;
    }
  }

  Future<void> _restoreInventory({
    required InventoryItemRepository inventoryRepository,
    required List<InventoryItem> previousItems,
  }) async {
    try {
      await inventoryRepository.saveAll(previousItems);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to restore inventory after prepared meal rollback.',
        name: _preparedMealsControllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> _runSerializedMutation(Future<bool> Function() mutation) {
    return _mutationQueue.run<bool>(
      operation: mutation,
      fallbackValue: false,
      onError: (error, stackTrace) {
        log(
          'Unexpected prepared meal mutation error.',
          name: _preparedMealsControllerLogName,
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  Future<PreparedMealCreationResult> _runInventoryTrackedCreation(
    Future<PreparedMealCreationResult> Function(
      InventoryItemRepository inventoryRepository,
    )
    operation,
  ) async {
    final inventoryRepository = ref.read(inventoryItemRepositoryProvider);
    final beforeItems = await _readInventoryForActivity(inventoryRepository);
    if (beforeItems == null) {
      return operation(inventoryRepository);
    }
    final trackingRepository = _ActivityTrackingInventoryItemRepository(
      delegate: inventoryRepository,
      initialItems: beforeItems,
    );
    final result = await operation(trackingRepository);
    if (result.isSuccess) {
      await _recordPreparedMealInventoryDiff(
        beforeItems: beforeItems,
        afterItems: trackingRepository.latestItems,
      );
    }
    return result;
  }

  Future<bool> _runInventoryTrackedBool(
    Future<bool> Function(InventoryItemRepository inventoryRepository)
    operation,
  ) async {
    final inventoryRepository = ref.read(inventoryItemRepositoryProvider);
    final beforeItems = await _readInventoryForActivity(inventoryRepository);
    if (beforeItems == null) {
      return operation(inventoryRepository);
    }
    final trackingRepository = _ActivityTrackingInventoryItemRepository(
      delegate: inventoryRepository,
      initialItems: beforeItems,
    );
    final saved = await operation(trackingRepository);
    if (saved) {
      await _recordPreparedMealInventoryDiff(
        beforeItems: beforeItems,
        afterItems: trackingRepository.latestItems,
      );
    }
    return saved;
  }

  Future<List<InventoryItem>?> _readInventoryForActivity(
    InventoryItemRepository inventoryRepository,
  ) async {
    try {
      return inventoryRepository.readAll();
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read inventory for prepared meal activity tracking.',
        name: _preparedMealsControllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> _recordPreparedMealInventoryDiff({
    required List<InventoryItem> beforeItems,
    required List<InventoryItem> afterItems,
  }) async {
    final actor = ref.read(inventoryActivityActorProvider);
    if (actor == null) {
      return;
    }

    final events = _buildPreparedMealInventoryDiffEvents(
      actor: actor,
      beforeItems: beforeItems,
      afterItems: afterItems,
      buildId: _newId,
    );
    if (events.isEmpty) {
      return;
    }

    final saved = await ref
        .read(inventoryActivityEventRepositoryProvider)
        .appendAll(events);
    if (!saved) {
      log(
        'Failed to record prepared meal inventory activity events.',
        name: _preparedMealsControllerLogName,
      );
    }
  }

  Future<PreparedMealCreationResult> _runCreationMutation({
    required Future<PreparedMealCreationResult> Function() operation,
    required String unexpectedErrorMessage,
  }) {
    final keepAliveLink = ref.keepAlive();
    return _mutationQueue
        .run<PreparedMealCreationResult>(
          operation: operation,
          fallbackValue: const PreparedMealCreationResult.failure(
            PreparedMealCreationFailureReason.mealSaveFailed,
          ),
          onError: (error, stackTrace) {
            log(
              unexpectedErrorMessage,
              name: _preparedMealsControllerLogName,
              error: error,
              stackTrace: stackTrace,
            );
          },
        )
        .whenComplete(keepAliveLink.close);
  }

  String _newId() {
    return const Uuid().v4();
  }
}

class _ActivityTrackingInventoryItemRepository
    implements InventoryItemRepository {
  _ActivityTrackingInventoryItemRepository({
    required InventoryItemRepository delegate,
    required List<InventoryItem> initialItems,
  }) : _delegate = delegate,
       _latestItems = List<InventoryItem>.from(initialItems);

  final InventoryItemRepository _delegate;
  List<InventoryItem> _latestItems;

  List<InventoryItem> get latestItems => List<InventoryItem>.from(
    _latestItems,
  );

  @override
  Stream<List<InventoryItem>> watchAll() {
    return _delegate.watchAll();
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return latestItems;
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    final saved = await _delegate.saveAll(items);
    if (saved) {
      _latestItems = List<InventoryItem>.from(items);
    }
    return saved;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    final saved = await _delegate.appendAll(items);
    if (saved) {
      _latestItems = _upsertItems(_latestItems, items);
    }
    return saved;
  }
}

List<InventoryItem> _upsertItems(
  List<InventoryItem> currentItems,
  List<InventoryItem> items,
) {
  if (items.isEmpty) {
    return List<InventoryItem>.from(currentItems);
  }

  final itemsById = <String, InventoryItem>{
    for (final item in currentItems) item.id: item,
  };
  for (final item in items) {
    itemsById[item.id] = item;
  }
  return itemsById.values.toList(growable: false);
}

List<InventoryActivityEvent> _buildPreparedMealInventoryDiffEvents({
  required InventoryActivityActor actor,
  required List<InventoryItem> beforeItems,
  required List<InventoryItem> afterItems,
  required String Function() buildId,
}) {
  final beforeById = <String, InventoryItem>{
    for (final item in beforeItems) item.id: item,
  };
  final afterById = <String, InventoryItem>{
    for (final item in afterItems) item.id: item,
  };
  final itemIds = <String>{...beforeById.keys, ...afterById.keys};
  final events = <InventoryActivityEvent>[];

  for (final itemId in itemIds) {
    final beforeItem = beforeById[itemId];
    final afterItem = afterById[itemId];
    final beforeAmount = beforeItem == null ? 0 : _stockAmount(beforeItem);
    final afterAmount = afterItem == null ? 0 : _stockAmount(afterItem);
    final delta = afterAmount - beforeAmount;
    if (delta == 0) {
      continue;
    }

    final eventItem = delta < 0 ? beforeItem : afterItem;
    if (eventItem == null) {
      continue;
    }

    events.add(
      InventoryActivityEvent.fromStockChange(
        id: buildId(),
        type: delta < 0
            ? InventoryActivityEventType.itemUsedInPreparedMeal
            : InventoryActivityEventType.itemReturnedFromPreparedMeal,
        actor: actor,
        item: eventItem,
        amount: delta.abs(),
        beforeQuantity: beforeItem?.quantity,
        afterQuantity: afterItem?.quantity,
        beforeCurrentAmount: beforeItem?.currentAmount,
        afterCurrentAmount: afterItem?.currentAmount,
      ),
    );
  }

  return events;
}

int _stockAmount(InventoryItem item) {
  if (item.usesAmountProgress) {
    return item.currentAmount;
  }
  return item.quantity;
}
