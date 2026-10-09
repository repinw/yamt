import 'dart:developer' show log;

import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_stock_activity.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Reads and writes Vorrat meals for the meal mutations: one meal document
/// per change, stock restored when the meal write fails.
class PreparedMealWriter {
  /// Creates the writer. With `newMealsInPot`, meals that a change adds
  /// start in the pot.
  new({
    required this._meals,
    required this._clock,
    required this._logName,
    this._newMealsInPot = false,
    String Function()? newId,
  }) : _newId = newId ?? const Uuid().v4;

  final PreparedMealRepository _meals;
  final DateTime Function() _clock;
  final String _logName;
  final bool _newMealsInPot;
  final String Function() _newId;

  /// Reads the meals of the household that a change starts from.
  Future<List<PreparedMeal>> loadMeals() => _meals.readAllForChange();

  /// Writes the meals that [nextMeals] changes against [previousMeals].
  /// Throws when the repository throws.
  Future<bool> saveMeals({
    required List<PreparedMeal> previousMeals,
    required List<PreparedMeal> nextMeals,
  }) {
    final previousIds = {for (final meal in previousMeals) meal.id};
    return _meals.saveChanges(
      previous: previousMeals,
      next: [
        for (final meal in nextMeals)
          if (_newMealsInPot && !previousIds.contains(meal.id))
            meal.copyWith(inPot: true)
          else
            meal,
      ],
    );
  }

  /// Writes [previousItems] back after a failed meal write. Only the items
  /// that [writtenItems] changed go back, so items that another device wrote
  /// meanwhile stay.
  Future<void> restoreInventory({
    required InventoryItemRepository inventoryRepository,
    required List<InventoryItem> writtenItems,
    required List<InventoryItem> previousItems,
  }) async {
    try {
      await inventoryRepository.saveChanges(
        previous: writtenItems,
        next: previousItems,
      );
    } on Object catch (error, stackTrace) {
      log(
        'Failed to restore inventory after a prepared meal rollback.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Runs [operation] on a Vorrat that remembers its last write. Records the
  /// stock change in the history when [succeeded] says the change went
  /// through, and writes the Vorrat back when [operation] throws.
  Future<T> trackStock<T>({
    required InventoryItemRepository inventory,
    required InventoryActivityEventRepository activity,
    required InventoryActivityActor? actor,
    required Future<T> Function(InventoryItemRepository inventory) operation,
    required bool Function(T result) succeeded,
  }) async {
    final beforeItems = await inventory.readAllForChange();
    final tracking = PreparedMealStockTrackingRepository(
      delegate: inventory,
      initialItems: beforeItems,
    );
    final T result;
    try {
      result = await operation(tracking);
    } on Object {
      // A meal write that throws leaves the Vorrat already changed.
      if (!const ListEquality<InventoryItem>().equals(
        tracking.latestItems,
        beforeItems,
      )) {
        await restoreInventory(
          inventoryRepository: inventory,
          writtenItems: tracking.latestItems,
          previousItems: beforeItems,
        );
      }
      rethrow;
    }
    if (succeeded(result)) {
      await recordPreparedMealStockActivity(
        actor: actor,
        activityRepository: activity,
        beforeItems: beforeItems,
        afterItems: tracking.latestItems,
        buildId: buildId,
        logName: _logName,
      );
    }
    return result;
  }

  /// A new id for a saved meal or event.
  String buildId() => _newId();

  /// The time of the change.
  DateTime buildNow() => _clock();

  /// Writes one log message.
  void logMessage(String message) => log(message, name: _logName);
}
