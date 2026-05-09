import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_calorie_log_bridge.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_workflow_context.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';

/// Handles prepared meal consumption and discard workflows.
class PreparedMealConsumptionWorkflows {
  /// Creates consumption workflows.
  const PreparedMealConsumptionWorkflows({
    required PreparedMealWorkflowContext context,
  }) : _context = context;

  final PreparedMealWorkflowContext _context;

  /// Consumes prepared meal portions and forwards calorie logging.
  Future<bool> consumePreparedMeal({
    required String mealId,
    required num consumedPortions,
    required MealType mealType,
    required DateTime? loggedDay,
    required PreparedMealCalorieLogBridge calorieLogBridge,
  }) async {
    if (consumedPortions <= 0) {
      _context.logMessage(
        'consumePreparedMeal(): invalid consumedPortions='
        '$consumedPortions (mealId=$mealId)',
      );
      return false;
    }

    final currentMeals = await _context.loadMeals();
    final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
    if (mealIndex < 0) {
      _context.logMessage('consumePreparedMeal(): meal not found ($mealId)');
      return false;
    }

    final meal = currentMeals[mealIndex];
    _context.logMessage(
      'consumePreparedMeal(): starting '
      '(mealId=$mealId, consumedPortions=$consumedPortions, '
      'remainingPortions=${meal.remainingPortions}, '
      'totalPortions=${meal.totalPortions}, '
      'mealType=${mealType.name}, '
      'loggedDay=${loggedDay?.toIso8601String()})',
    );
    if (meal.hasPendingRecipeIngredients) {
      _context.logMessage(
        'consumePreparedMeal(): meal has pending recipe ingredients '
        '(mealId=$mealId)',
      );
      return false;
    }
    if (consumedPortions > meal.remainingPortions) {
      _context.logMessage(
        'consumePreparedMeal(): consumedPortions exceed remaining '
        '($consumedPortions > ${meal.remainingPortions}) '
        '(mealId=$mealId)',
      );
      return false;
    }
    if (consumedPortions == meal.remainingPortions) {
      _context.logMessage(
        'consumePreparedMeal(): meal will be fully depleted and kept '
        'with zero remaining portions (mealId=$mealId)',
      );
    }

    final nextMeals = applyPreparedMealPortionReduction(
      currentMeals: currentMeals,
      mealIndex: mealIndex,
      removedPortions: consumedPortions,
      updatedAt: _context.buildNow(),
      keepDepletedMeal: true,
    );
    return calorieLogBridge.consumePreparedMeal(
      currentMeals: currentMeals,
      nextMeals: nextMeals,
      meal: meal,
      consumedPortions: consumedPortions,
      mealType: mealType,
      loggedDay: loggedDay,
      publishMeals: _context.publishMeals,
      saveMeals: (previousMeals, nextMeals) {
        return _context.saveMeals(
          previousMeals: previousMeals,
          nextMeals: nextMeals,
        );
      },
    );
  }

  /// Discards prepared meal portions and persists a discard event.
  Future<bool> throwAwayPreparedMeal({
    required String mealId,
    required num discardedPortions,
    required InventoryDiscardReason reason,
    required InventoryDiscardEventRepository discardEventRepository,
  }) async {
    if (discardedPortions <= 0) {
      _context.logMessage(
        'throwAwayPreparedMeal(): invalid discardedPortions='
        '$discardedPortions',
      );
      return false;
    }

    _context.logMessage(
      'throwAwayPreparedMeal(): starting '
      '(mealId=$mealId, discardedPortions=$discardedPortions, '
      'reason=${reason.name})',
    );
    final currentMeals = await _context.loadMeals();
    final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
    if (mealIndex < 0) {
      _context.logMessage('throwAwayPreparedMeal(): meal not found ($mealId)');
      return false;
    }

    final meal = currentMeals[mealIndex];
    if (discardedPortions > meal.remainingPortions) {
      _context.logMessage(
        'throwAwayPreparedMeal(): discardedPortions exceed remaining '
        '($discardedPortions > ${meal.remainingPortions})',
      );
      return false;
    }

    final nextMeals = applyPreparedMealPortionReduction(
      currentMeals: currentMeals,
      mealIndex: mealIndex,
      removedPortions: discardedPortions,
      updatedAt: _context.buildNow(),
    );
    final savedMeals = await _context.saveMeals(
      previousMeals: currentMeals,
      nextMeals: nextMeals,
    );
    if (!savedMeals) {
      _context.logMessage('throwAwayPreparedMeal(): saveMeals returned false');
      return false;
    }
    _context.logMessage(
      'throwAwayPreparedMeal(): prepared meals saved, '
      'persisting discard event',
    );

    final discardEvent = InventoryDiscardEvent.fromPreparedMeal(
      id: _context.buildId(),
      meal: meal,
      discardedPortions: discardedPortions,
      reason: reason,
    );
    final eventSaved = await discardEventRepository.saveEvent(discardEvent);
    if (eventSaved) {
      _context.logMessage(
        'throwAwayPreparedMeal(): discard event saved (${discardEvent.id})',
      );
      return true;
    }

    _context.logMessage(
      'throwAwayPreparedMeal(): discard event save failed, '
      'restoring previous meal state',
    );
    await _context.saveMeals(previousMeals: nextMeals, nextMeals: currentMeals);
    return false;
  }
}
