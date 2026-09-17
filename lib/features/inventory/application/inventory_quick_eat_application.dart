import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_calorie_log_bridge.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'inventory_quick_eat_application.g.dart';

/// Creates repository-backed quick-eat mutations.
@riverpod
InventoryQuickEatApplication inventoryQuickEatApplication(Ref ref) {
  return InventoryQuickEatApplication(
    inventoryRepository: ref.watch(inventoryItemRepositoryProvider),
    preparedMealRepository: ref.watch(preparedMealRepositoryProvider),
    calorieLogBridge: ref.watch(preparedMealCalorieLogBridgeProvider),
    pendingConsumptions: ref.watch(inventoryPendingConsumptionStoreProvider),
  );
}

/// Provides application-level quick-eat mutations for Inventory callers.
@riverpod
InventoryQuickEatActions inventoryQuickEatActions(Ref ref) {
  return ref.watch(inventoryQuickEatApplicationProvider);
}

/// Inventory mutations needed by quick-eat callers.
abstract interface class InventoryQuickEatActions {
  /// Stages inventory consumption and returns its pending id.
  Future<String?> stageInventoryItemConsumption({
    required String itemId,
    required int amount,
  });

  /// Discards staged inventory consumption.
  Future<void> discardInventoryItemConsumption(String pendingConsumptionId);

  /// Consumes one prepared meal.
  Future<bool> consumePreparedMeal({
    required String mealId,
    required num consumedPortions,
    required MealType mealType,
    required DateTime loggedDay,
  });
}

/// Runs quick-eat mutations against Inventory repositories.
final class InventoryQuickEatApplication implements InventoryQuickEatActions {
  /// Creates the quick-eat application service.
  new({
    required this._inventoryRepository,
    required this._preparedMealRepository,
    required this._calorieLogBridge,
    required this._pendingConsumptions,
  });

  final InventoryItemRepository _inventoryRepository;
  final PreparedMealRepository _preparedMealRepository;
  final PreparedMealCalorieLogBridge _calorieLogBridge;
  final InventoryPendingConsumptionStore _pendingConsumptions;
  final _mutationQueue = SerializedMutationQueue();
  int _nextPendingConsumptionNumber = 0;

  @override
  Future<String?> stageInventoryItemConsumption({
    required String itemId,
    required int amount,
  }) {
    return _mutationQueue.run<String?>(
      operation: () =>
          _stageInventoryItemConsumption(itemId: itemId, amount: amount),
      fallbackValue: null,
      onError: _logMutationError,
    );
  }

  Future<String?> _stageInventoryItemConsumption({
    required String itemId,
    required int amount,
  }) async {
    if (amount < 1) {
      return null;
    }
    final item = (await _inventoryRepository.readAll())
        .where((candidate) => candidate.id == itemId)
        .firstOrNull;
    final availableAmount = _availableAmount(item);
    if (availableAmount < 1) {
      return null;
    }
    return _stagePendingConsumption(itemId, amount, availableAmount);
  }

  String _stagePendingConsumption(String itemId, int amount, int available) {
    final pending = PendingInventoryConsumption(
      id: _nextPendingConsumptionId(),
      itemId: itemId,
      amount: amount > available ? available : amount,
    );
    _pendingConsumptions.stage(pending);
    return pending.id;
  }

  @override
  Future<void> discardInventoryItemConsumption(String pendingConsumptionId) {
    return _pendingConsumptions.discard(pendingConsumptionId).then((_) {});
  }

  @override
  Future<bool> consumePreparedMeal({
    required String mealId,
    required num consumedPortions,
    required MealType mealType,
    required DateTime loggedDay,
  }) {
    return _mutationQueue.run<bool>(
      operation: () => _consumePreparedMeal(
        mealId: mealId,
        consumedPortions: consumedPortions,
        mealType: mealType,
        loggedDay: loggedDay,
      ),
      fallbackValue: false,
      onError: _logMutationError,
    );
  }

  Future<bool> _consumePreparedMeal({
    required String mealId,
    required num consumedPortions,
    required MealType mealType,
    required DateTime loggedDay,
  }) async {
    if (consumedPortions <= 0) {
      return false;
    }
    final currentMeals = await _preparedMealRepository.readAll();
    final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
    if (mealIndex < 0) {
      return false;
    }
    final meal = currentMeals[mealIndex];
    if (!_canConsumePreparedMeal(meal, consumedPortions)) {
      return false;
    }
    return _savePreparedMealConsumption(
      currentMeals: currentMeals,
      mealIndex: mealIndex,
      consumedPortions: consumedPortions,
      mealType: mealType,
      loggedDay: loggedDay,
    );
  }

  Future<bool> _savePreparedMealConsumption({
    required List<PreparedMeal> currentMeals,
    required int mealIndex,
    required num consumedPortions,
    required MealType mealType,
    required DateTime loggedDay,
  }) {
    final meal = currentMeals[mealIndex];
    final nextMeals = applyPreparedMealPortionReduction(
      currentMeals: currentMeals,
      mealIndex: mealIndex,
      removedPortions: consumedPortions,
      updatedAt: DateTime.now(),
      keepDepletedMeal: true,
    );
    return _calorieLogBridge.consumePreparedMeal(
      currentMeals: currentMeals,
      nextMeals: nextMeals,
      meal: meal,
      consumedPortions: consumedPortions,
      mealType: mealType,
      loggedDay: loggedDay,
      publishMeals: (_) {},
      saveMeals: (previousMeals, updatedMeals) {
        return _preparedMealRepository.saveAll(updatedMeals);
      },
    );
  }

  String _nextPendingConsumptionId() {
    _nextPendingConsumptionNumber += 1;
    return 'pending-consumption-$_nextPendingConsumptionNumber';
  }

  void _logMutationError(Object error, StackTrace stackTrace) {
    log(
      'Unexpected inventory quick-eat mutation error.',
      name: 'InventoryQuickEatApplication',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

bool _canConsumePreparedMeal(PreparedMeal meal, num consumedPortions) {
  return !meal.hasPendingRecipeIngredients &&
      consumedPortions <= meal.remainingPortions;
}

int _availableAmount(InventoryItem? item) {
  if (item == null) {
    return 0;
  }
  final amount = item.usesAmountProgress ? item.currentAmount : item.quantity;
  return amount > 0 ? amount : 0;
}
