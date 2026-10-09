import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/calories/application/calorie_day_log_service.dart';
import 'package:yamt/features/calories/application/calorie_entry_saver.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_diary_entry.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_service.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';

part 'inventory_quick_eat_application.g.dart';

/// Creates repository-backed quick-eat mutations.
@riverpod
InventoryQuickEatApplication inventoryQuickEatApplication(Ref ref) {
  return InventoryQuickEatApplication(
    saveEntry: ref.watch(calorieEntrySaverProvider),
    commitStore: ref.watch(preparedMealCalorieEntryCommitStoreProvider),
    mealMutations: ref.watch(preparedMealMutationServiceProvider),
    dayLog: ref.watch(calorieDayLogServiceProvider),
    now: ref.watch(clockProvider),
  );
}

/// A saved eat of a prepared meal: the diary entry, or a plan when its day
/// lies after today.
typedef PreparedMealEatResult = ({CalorieEntry entry, bool isPlan});

/// Logs and plans portions of Vorrat meals.
///
/// Callers pass the meal they show from the live inventory stream, so no
/// server read delays the save. The commit store checks the portions again
/// when it writes the entry and the meal in one batch.
class InventoryQuickEatApplication {
  /// Creates the quick-eat application service.
  new({
    required this._saveEntry,
    required this._commitStore,
    required this._mealMutations,
    required this._dayLog,
    required this._now,
  });

  final CalorieEntrySaver _saveEntry;
  final PreparedMealCalorieEntryCommitStore? _commitStore;
  final PreparedMealMutationService _mealMutations;
  final CalorieDayLogService _dayLog;
  final DateTime Function() _now;
  final _mutationQueue = SerializedMutationQueue();

  /// Logs [consumedPortions] of [meal] and returns the saved entry, or null
  /// when it failed. [asPlan], or a day after today, saves a plan and keeps
  /// the portions. [potNetWeight], the food in the pot when the cook weighed
  /// it on the eat page, is stored on the meal first for the household;
  /// [consumedPortions] already count from it.
  Future<PreparedMealEatResult?> consumePreparedMeal({
    required PreparedMeal meal,
    required num consumedPortions,
    required MealType mealType,
    required DateTime loggedDay,
    bool asPlan = false,
    int? potNetWeight,
  }) {
    return _mutationQueue.run<PreparedMealEatResult?>(
      operation: () => _consumePreparedMeal(
        meal: meal,
        consumedPortions: consumedPortions,
        mealType: mealType,
        loggedDay: loggedDay,
        asPlan: asPlan,
        potNetWeight: potNetWeight,
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
    required int? potNetWeight,
  }) async {
    final weighed = potNetWeight == null
        ? meal
        : await _mealMutations.weighPot(
            mealId: meal.id,
            netWeight: potNetWeight,
          );
    final isPlan = asPlan || _dayLog.plansOn(loggedDay);
    final action = isPlan ? PreparedMealAction.plan : PreparedMealAction.eat;
    if (!weighed.allowsPortions(action, consumedPortions)) {
      return null;
    }
    if (isPlan) {
      return await _planPreparedMeal(
        meal: weighed,
        consumedPortions: consumedPortions,
        mealType: mealType,
        loggedDay: loggedDay,
      );
    }
    final commitStore = _commitStore;
    final entry = buildConsumedPreparedMealCalorieEntry(
      meal: weighed,
      consumedPortions: consumedPortions,
      mealType: mealType,
      now: _now,
      nextEntryId: const Uuid().v4,
      loggedDay: loggedDay,
    );
    if (commitStore == null || entry == null) {
      return null;
    }
    final saved = await _saveEntry(
      entry,
      persistEntry: (persisted) =>
          commitStore.commitEntryAndPreparedMeal(entry: persisted),
    );
    return saved ? (entry: entry, isPlan: false) : null;
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
    await _dayLog.plan(plan);
    return (entry: plan, isPlan: true);
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
