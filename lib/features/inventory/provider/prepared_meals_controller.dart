import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_calorie_log_bridge.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_household_recovery.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_workflows.dart';
import 'package:yamt/features/inventory/application/'
    'template_ingredient_parser.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

export 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart'
    show
        PreparedMealCreationFailureReason,
        PreparedMealCreationResult,
        PreparedMealItemInput;

part 'prepared_meals_controller.g.dart';

const _preparedMealsControllerLogName = 'PreparedMealsController';

/// Defines prepared meals controller.
@Riverpod(dependencies: [inventoryItemRepository])
class PreparedMealsController extends _$PreparedMealsController {
  static const _uuid = Uuid();

  // Subscription is cancelled by _disposeSubscription.
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
      buildId: _uuid.v4,
      buildNow: DateTime.now,
      logName: _preparedMealsControllerLogName,
    );
  }

  @override
  FutureOr<List<PreparedMeal>> build() {
    ref
      ..watch(householdDataOwnerUserIdProvider)
      ..watch(preparedMealRepositoryProvider)
      ..onDispose(() {
        unawaited(_disposeSubscription());
      });
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
      operation: () {
        return _mutationWorkflows.createPreparedMeal(
          name: name,
          totalPortions: totalPortions,
          items: items,
          imageAssetId: imageAssetId,
          inventoryRepository: ref.read(inventoryItemRepositoryProvider),
        );
      },
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
  }) {
    return _runCreationMutation(
      operation: () {
        return _mutationWorkflows.createPreparedMealFromTemplate(
          template: template,
          totalPortions: totalPortions,
          recipeIngredientAssignments: recipeIngredientAssignments,
          recipeIngredientAmountConversions: recipeIngredientAmountConversions,
          inventoryRepository: ref.read(inventoryItemRepositoryProvider),
          ingredientParser: ref.read(templateIngredientParserProvider),
        );
      },
      unexpectedErrorMessage: 'Unexpected template meal creation error.',
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
      () => _mutationWorkflows.updatePreparedMealDetails(
        mealId: mealId,
        name: name,
        imageChanged: imageChanged,
        imageAssetId: imageAssetId,
        totalPortions: totalPortions,
        items: items,
        inventoryRepository: ref.read(inventoryItemRepositoryProvider),
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
      () => _mutationWorkflows.fillPreparedMealPendingIngredient(
        mealId: mealId,
        ingredient: ingredient,
        inventoryItemIds: inventoryItemIds,
        inventoryRepository: ref.read(inventoryItemRepositoryProvider),
        ingredientParser: ref.read(templateIngredientParserProvider),
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
    required int consumedPortions,
    required MealType mealType,
    DateTime? loggedDay,
  }) {
    final keepAliveLink = ref.keepAlive();
    return _runSerializedMutation(
      () => _mutationWorkflows.consumePreparedMeal(
        mealId: mealId,
        consumedPortions: consumedPortions,
        mealType: mealType,
        loggedDay: loggedDay,
        calorieLogBridge: ref.read(preparedMealCalorieLogBridgeProvider),
      ),
    ).whenComplete(keepAliveLink.close);
  }

  /// Throw away prepared meal.
  Future<bool> throwAwayPreparedMeal({
    required String mealId,
    required int discardedPortions,
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
    required int portions,
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
      () => _mutationWorkflows.unbundlePreparedMeal(
        mealId: mealId,
        inventoryRepository: ref.read(inventoryItemRepositoryProvider),
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
}
