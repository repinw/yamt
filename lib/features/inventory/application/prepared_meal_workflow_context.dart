import 'dart:developer' show log;

import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Loads the controller's current prepared meals.
typedef LoadPreparedMeals = Future<List<PreparedMeal>> Function();

/// Saves updated prepared meals while keeping previous state for rollback.
typedef SavePreparedMeals =
    Future<bool> Function({
      required List<PreparedMeal> previousMeals,
      required List<PreparedMeal> nextMeals,
    });

/// Restores inventory after a meal mutation failed.
typedef RestoreInventoryItems =
    Future<void> Function({
      required InventoryItemRepository inventoryRepository,
      required List<InventoryItem> previousItems,
    });

/// Publishes optimistic prepared meal state.
typedef PublishPreparedMeals = void Function(List<PreparedMeal> meals);

/// Builds a fresh id for persisted entities.
typedef BuildMutationId = String Function();

/// Captures the current timestamp for mutations.
typedef BuildMutationTime = DateTime Function();

/// Shared dependencies for prepared meal workflow classes.
class PreparedMealWorkflowContext {
  /// Creates prepared meal workflow context.
  const PreparedMealWorkflowContext({
    required this.loadMeals,
    required this.saveMeals,
    required this.restoreInventory,
    required this.publishMeals,
    required this.buildId,
    required this.buildNow,
    required this.logName,
  });

  /// Reads the latest prepared meals.
  final LoadPreparedMeals loadMeals;

  /// Persists prepared meal list updates.
  final SavePreparedMeals saveMeals;

  /// Restores inventory after a failed mutation.
  final RestoreInventoryItems restoreInventory;

  /// Publishes in-memory prepared meals during async work.
  final PublishPreparedMeals publishMeals;

  /// Builds ids for saved entities.
  final BuildMutationId buildId;

  /// Supplies timestamps for meal updates.
  final BuildMutationTime buildNow;

  /// Log name used for workflow diagnostics.
  final String logName;

  /// Writes one workflow log message.
  void logMessage(String message) {
    log(message, name: logName);
  }
}
