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
  const new({required this._context});

  final PreparedMealWorkflowContext _context;

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
