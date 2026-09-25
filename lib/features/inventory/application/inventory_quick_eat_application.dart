import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_calorie_log_bridge.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'inventory_quick_eat_application.g.dart';

/// Creates repository-backed quick-eat mutations.
@riverpod
InventoryQuickEatApplication inventoryQuickEatApplication(Ref ref) {
  return InventoryQuickEatApplication(
    preparedMealRepository: ref.watch(preparedMealRepositoryProvider),
    calorieLogBridge: ref.watch(preparedMealCalorieLogBridgeProvider),
    pendingConsumptions: ref.watch(inventoryPendingConsumptionStoreProvider),
    now: ref.watch(clockProvider),
  );
}

/// Provides application-level quick-eat mutations for Inventory callers.
@riverpod
InventoryQuickEatActions inventoryQuickEatActions(Ref ref) {
  return ref.watch(inventoryQuickEatApplicationProvider);
}

/// Inventory mutations needed by quick-eat callers.
///
/// Callers pass the item or meal they show from the live inventory stream,
/// so no server read delays the save. The commit stores check the stock
/// again when they write.
abstract interface class InventoryQuickEatActions {
  /// Stages inventory consumption and returns its pending id.
  Future<String?> stageInventoryItemConsumption({
    required InventoryItem item,
    required int amount,
  });

  /// Discards staged inventory consumption.
  Future<void> discardInventoryItemConsumption(String pendingConsumptionId);

  /// Consumes one prepared meal and returns the saved calorie entry, or null
  /// when it failed.
  Future<CalorieEntry?> consumePreparedMeal({
    required PreparedMeal meal,
    required num consumedPortions,
    required MealType mealType,
    required DateTime loggedDay,
  });
}

/// Runs quick-eat mutations against Inventory repositories.
final class InventoryQuickEatApplication implements InventoryQuickEatActions {
  /// Creates the quick-eat application service.
  new({
    required this._preparedMealRepository,
    required this._calorieLogBridge,
    required this._pendingConsumptions,
    required this._now,
  });

  final PreparedMealRepository _preparedMealRepository;
  final PreparedMealCalorieLogBridge _calorieLogBridge;
  final InventoryPendingConsumptionStore _pendingConsumptions;
  final DateTime Function() _now;
  final _mutationQueue = SerializedMutationQueue();
  int _nextPendingConsumptionNumber = 0;

  @override
  Future<String?> stageInventoryItemConsumption({
    required InventoryItem item,
    required int amount,
  }) async {
    if (amount < 1) {
      return null;
    }
    final availableAmount = _availableAmount(item);
    if (availableAmount < 1) {
      return null;
    }
    return _stagePendingConsumption(item.id, amount, availableAmount);
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
  Future<CalorieEntry?> consumePreparedMeal({
    required PreparedMeal meal,
    required num consumedPortions,
    required MealType mealType,
    required DateTime loggedDay,
  }) {
    return _mutationQueue.run<CalorieEntry?>(
      operation: () => _consumePreparedMeal(
        meal: meal,
        consumedPortions: consumedPortions,
        mealType: mealType,
        loggedDay: loggedDay,
      ),
      fallbackValue: null,
      onError: _logMutationError,
    );
  }

  Future<CalorieEntry?> _consumePreparedMeal({
    required PreparedMeal meal,
    required num consumedPortions,
    required MealType mealType,
    required DateTime loggedDay,
  }) async {
    if (consumedPortions <= 0 ||
        !_canConsumePreparedMeal(meal, consumedPortions)) {
      return null;
    }
    final currentMeals = <PreparedMeal>[meal];
    final nextMeals = applyPreparedMealPortionReduction(
      currentMeals: currentMeals,
      mealIndex: 0,
      removedPortions: consumedPortions,
      updatedAt: _now(),
      keepDepletedMeal: true,
    );
    return await _calorieLogBridge.consumePreparedMeal(
      currentMeals: currentMeals,
      nextMeals: nextMeals,
      meal: meal,
      consumedPortions: consumedPortions,
      mealType: mealType,
      loggedDay: loggedDay,
      publishMeals: (_) {},
      saveMeals: (_, updatedMeals) => _replaceMeal(updatedMeals.single),
    );
  }

  /// Writes one meal into the stored list. Only the bridge fallback without
  /// an atomic commit store uses it.
  Future<bool> _replaceMeal(PreparedMeal meal) async {
    final storedMeals = await _preparedMealRepository.readAll();
    return await _preparedMealRepository.saveAll(
      storedMeals
          .map((stored) => stored.id == meal.id ? meal : stored)
          .toList(growable: false),
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
