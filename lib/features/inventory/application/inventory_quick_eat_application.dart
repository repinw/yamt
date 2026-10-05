import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_calorie_log_bridge.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'inventory_quick_eat_application.g.dart';

/// Creates repository-backed quick-eat mutations.
@riverpod
InventoryQuickEatApplication inventoryQuickEatApplication(Ref ref) {
  return InventoryQuickEatApplication(
    preparedMealRepository: ref.watch(preparedMealRepositoryProvider),
    calorieLogBridge: ref.watch(preparedMealCalorieLogBridgeProvider),
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
/// Callers pass the meal they show from the live inventory stream, so no
/// server read delays the save. The commit store checks the portions again
/// when it writes.
abstract interface class InventoryQuickEatActions {
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
    required this._now,
  });

  final PreparedMealRepository _preparedMealRepository;
  final PreparedMealCalorieLogBridge _calorieLogBridge;
  final DateTime Function() _now;
  final _mutationQueue = SerializedMutationQueue();

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
