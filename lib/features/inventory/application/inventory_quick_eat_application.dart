import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/application/last_planned_day_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
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
    plans: ref.watch(plannedEntryRepositoryProvider),
    overviewRevision: ref.watch(calorieOverviewRevisionProvider.notifier),
    lastPlannedDay: ref.watch(lastPlannedDayProvider.notifier),
    now: ref.watch(clockProvider),
  );
}

/// A saved eat of a prepared meal: the diary entry, or a plan when its day
/// lies after today.
typedef PreparedMealEatResult = ({CalorieEntry entry, bool isPlan});

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
  /// when it failed. [asPlan], or a day after today, saves a plan and keeps
  /// the portions.
  Future<PreparedMealEatResult?> consumePreparedMeal({
    required PreparedMeal meal,
    required num consumedPortions,
    required MealType mealType,
    required DateTime loggedDay,
    bool asPlan,
  });
}

/// Runs quick-eat mutations against Inventory repositories.
final class InventoryQuickEatApplication implements InventoryQuickEatActions {
  /// Creates the quick-eat application service.
  new({
    required this._preparedMealRepository,
    required this._calorieLogBridge,
    required this._plans,
    required this._overviewRevision,
    required this._lastPlannedDay,
    required this._now,
  });

  final PreparedMealRepository _preparedMealRepository;
  final PreparedMealCalorieLogBridge _calorieLogBridge;
  final PlannedEntryRepository _plans;
  final CalorieOverviewRevision _overviewRevision;
  final LastPlannedDay _lastPlannedDay;
  final DateTime Function() _now;
  final _mutationQueue = SerializedMutationQueue();

  @override
  Future<PreparedMealEatResult?> consumePreparedMeal({
    required PreparedMeal meal,
    required num consumedPortions,
    required MealType mealType,
    required DateTime loggedDay,
    bool asPlan = false,
  }) {
    return _mutationQueue.run<PreparedMealEatResult?>(
      operation: () => _consumePreparedMeal(
        meal: meal,
        consumedPortions: consumedPortions,
        mealType: mealType,
        loggedDay: loggedDay,
        asPlan: asPlan,
      ),
      fallbackValue: null,
      onError: _logMutationError,
    );
  }

  Future<PreparedMealEatResult?> _consumePreparedMeal({
    required PreparedMeal meal,
    required num consumedPortions,
    required MealType mealType,
    required DateTime loggedDay,
    required bool asPlan,
  }) async {
    if (consumedPortions <= 0 ||
        !_canConsumePreparedMeal(meal, consumedPortions)) {
      return null;
    }
    if (asPlan || isDiaryFutureDay(day: loggedDay, today: _now())) {
      return await _planPreparedMeal(
        meal: meal,
        consumedPortions: consumedPortions,
        mealType: mealType,
        loggedDay: loggedDay,
      );
    }
    final currentMeals = <PreparedMeal>[meal];
    final nextMeals = applyPreparedMealPortionReduction(
      currentMeals: currentMeals,
      mealIndex: 0,
      removedPortions: consumedPortions,
      updatedAt: _now(),
      keepDepletedMeal: true,
    );
    final entry = await _calorieLogBridge.consumePreparedMeal(
      currentMeals: currentMeals,
      nextMeals: nextMeals,
      meal: meal,
      consumedPortions: consumedPortions,
      mealType: mealType,
      loggedDay: loggedDay,
      publishMeals: (_) {},
      saveMeals: (_, updatedMeals) => _replaceMeal(updatedMeals.single),
    );
    return entry == null ? null : (entry: entry, isPlan: false);
  }

  /// Saves the plan to eat [consumedPortions] of [meal]. The meal keeps its
  /// portions until the plan is eaten.
  Future<PreparedMealEatResult?> _planPreparedMeal({
    required PreparedMeal meal,
    required num consumedPortions,
    required MealType mealType,
    required DateTime loggedDay,
  }) async {
    final plan = buildConsumedPreparedMealCalorieEntry(
      meal: meal,
      consumedPortions: consumedPortions,
      mealType: mealType,
      now: _now,
      nextEntryId: const Uuid().v4,
      loggedDay: loggedDay,
    );
    if (plan == null) {
      return null;
    }
    await _plans.savePlannedEntry(plan);
    _overviewRevision.markChanged();
    _lastPlannedDay.planned(plan.loggedAt);
    return (entry: plan, isPlan: true);
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
