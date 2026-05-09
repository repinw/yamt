import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/provider/calorie_overview_revision_provider.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';

part 'calorie_entry_delete_flow.g.dart';

const _deleteFlowLogName = 'CalorieEntryDeleteFlow';

/// Defines calorie entry delete failure reason.
enum CalorieEntryDeleteFailureReason {
  /// Delete failed.
  deleteFailed,

  /// Restore failed.
  restoreFailed,

  /// Restore source was already removed from inventory.
  sourceMissing,
}

/// Defines calorie entry delete result.
class CalorieEntryDeleteResult {
  const CalorieEntryDeleteResult._({
    required this.isSuccess,
    required this.restoredToInventory,
    this.failureReason,
  });

  /// Creates a [CalorieEntryDeleteResult] for success.
  const CalorieEntryDeleteResult.success({required bool restoredToInventory})
    : this._(isSuccess: true, restoredToInventory: restoredToInventory);

  /// Creates a [CalorieEntryDeleteResult] for failure.
  const CalorieEntryDeleteResult.failure(CalorieEntryDeleteFailureReason reason)
    : this._(
        isSuccess: false,
        restoredToInventory: false,
        failureReason: reason,
      );

  /// Whether success.
  final bool isSuccess;

  /// The restored to inventory.
  final bool restoredToInventory;

  /// The failure reason.
  final CalorieEntryDeleteFailureReason? failureReason;
}

/// The calorie entry delete flow provider.
@Riverpod(
  dependencies: [
    inventoryItemRepository,
    InventoryItemsController,
    PreparedMealsController,
  ],
)
CalorieEntryDeleteFlow calorieEntryDeleteFlow(Ref ref) {
  final calorieLogRepository = ref.read(calorieLogRepositoryProvider);
  final calorieSettingsRepository = ref.read(calorieSettingsRepositoryProvider);
  final inventoryItemRepository = ref.read(inventoryItemRepositoryProvider);
  final inventoryController = ref.read(
    inventoryItemsControllerProvider.notifier,
  );
  final overviewRevision = ref.read(calorieOverviewRevisionProvider.notifier);
  final preparedMealRepository = ref.read(preparedMealRepositoryProvider);
  final preparedMealsController = ref.read(
    preparedMealsControllerProvider.notifier,
  );

  return CalorieEntryDeleteFlow(
    deleteEntryById: (entryId) async {
      final deleted = await calorieLogRepository.deleteEntry(entryId);
      if (deleted) {
        overviewRevision.markChanged();
      }
      return deleted;
    },
    restoreConsumedItem: inventoryController.restoreConsumedItem,
    rollbackRestoredItem: inventoryController.eatItem,
    sourceInventoryItemExists: (itemId) async {
      final normalizedItemId = itemId.trim();
      if (normalizedItemId.isEmpty) {
        return false;
      }
      try {
        final loadedItems = await inventoryItemRepository.readAll();
        return loadedItems.any((item) => item.id == normalizedItemId);
      } on Object catch (error, stackTrace) {
        log(
          'Failed to check inventory restore source. Trying restore anyway '
          '(itemId=$normalizedItemId).',
          name: _deleteFlowLogName,
          error: error,
          stackTrace: stackTrace,
        );
        return true;
      }
    },
    restorePreparedMealPortions:
        preparedMealsController.restorePreparedMealPortions,
    rollbackRestoredPreparedMeal:
        ({required mealId, required discardedPortions}) =>
            preparedMealsController.throwAwayPreparedMeal(
              mealId: mealId,
              discardedPortions: discardedPortions,
              reason: InventoryDiscardReason.other,
            ),
    invalidateSnapshotsFromDay: (day) =>
        _invalidateWeeklyCheckInSnapshotsFromDay(
          day: day,
          settingsRepository: calorieSettingsRepository,
        ),
    sourcePreparedMealExists: (mealId) async {
      final normalizedMealId = mealId.trim();
      if (normalizedMealId.isEmpty) {
        return false;
      }
      try {
        final loadedMeals = await preparedMealRepository.readAll();
        return loadedMeals.any((meal) => meal.id == normalizedMealId);
      } on Object catch (error, stackTrace) {
        log(
          'Failed to check prepared meal restore source. Trying restore '
          'anyway (mealId=$normalizedMealId).',
          name: _deleteFlowLogName,
          error: error,
          stackTrace: stackTrace,
        );
        return true;
      }
    },
  );
}

/// Defines calorie entry delete flow.
class CalorieEntryDeleteFlow {
  /// The calorie entry delete flow.
  const CalorieEntryDeleteFlow({
    required Future<bool> Function(String entryId) deleteEntryById,
    required Future<bool> Function(String itemId, int amount)
    restoreConsumedItem,
    required Future<bool> Function(
      String itemId,
      int amount, {
      DateTime? consumedAt,
    })
    rollbackRestoredItem,
    required Future<bool> Function(String itemId) sourceInventoryItemExists,
    required Future<bool> Function({
      required String mealId,
      required num portions,
    })
    restorePreparedMealPortions,
    required Future<bool> Function({
      required String mealId,
      required num discardedPortions,
    })
    rollbackRestoredPreparedMeal,
    required Future<bool> Function(String mealId) sourcePreparedMealExists,
    Future<bool> Function(DateTime day) invalidateSnapshotsFromDay =
        _noopInvalidateSnapshotsFromDay,
  }) : _deleteEntryById = deleteEntryById,
       _restoreConsumedItem = restoreConsumedItem,
       _rollbackRestoredItem = rollbackRestoredItem,
       _sourceInventoryItemExists = sourceInventoryItemExists,
       _restorePreparedMealPortions = restorePreparedMealPortions,
       _rollbackRestoredPreparedMeal = rollbackRestoredPreparedMeal,
       _invalidateSnapshotsFromDay = invalidateSnapshotsFromDay,
       _sourcePreparedMealExists = sourcePreparedMealExists;

  final Future<bool> Function(String entryId) _deleteEntryById;
  final Future<bool> Function(String itemId, int amount) _restoreConsumedItem;
  final Future<bool> Function(String itemId, int amount, {DateTime? consumedAt})
  _rollbackRestoredItem;
  final Future<bool> Function(String itemId) _sourceInventoryItemExists;
  final Future<bool> Function({required String mealId, required num portions})
  _restorePreparedMealPortions;
  final Future<bool> Function({
    required String mealId,
    required num discardedPortions,
  })
  _rollbackRestoredPreparedMeal;
  final Future<bool> Function(DateTime day) _invalidateSnapshotsFromDay;
  final Future<bool> Function(String mealId) _sourcePreparedMealExists;

  /// Whether the entry's inventory restore source still exists.
  Future<bool> canRestoreSource(CalorieEntry entry) async {
    if (entry.canReturnPreparedMealToInventory) {
      final mealId = entry.bundleSourcePreparedMealId?.trim();
      if (mealId == null || mealId.isEmpty) {
        return false;
      }
      return _sourcePreparedMealExists(mealId);
    }

    if (entry.canRestoreToInventory) {
      final itemId = entry.sourceInventoryItemId?.trim();
      if (itemId == null || itemId.isEmpty) {
        return false;
      }
      return _sourceInventoryItemExists(itemId);
    }

    return false;
  }

  /// Delete entry.
  Future<CalorieEntryDeleteResult> deleteEntry({
    required CalorieEntry entry,
    required bool restoreToInventory,
  }) async {
    log(
      'deleteEntry(): starting '
      '(entryId=${entry.id}, restoreToInventory=$restoreToInventory, '
      'loggedAt=${entry.loggedAt.toIso8601String()}, '
      'createdAt=${entry.createdAt.toIso8601String()}, '
      'preparedMealId=${entry.bundleSourcePreparedMealId}, '
      'preparedMealPortions=${entry.bundleConsumedPortions})',
      name: _deleteFlowLogName,
    );
    if (!restoreToInventory) {
      final deleted = await _deleteDiaryEntry(entry);
      if (!deleted) {
        log(
          'deleteEntry(): diary delete failed without inventory restore '
          '(entryId=${entry.id}).',
          name: _deleteFlowLogName,
        );
      }
      return deleted
          ? const CalorieEntryDeleteResult.success(restoredToInventory: false)
          : const CalorieEntryDeleteResult.failure(
              CalorieEntryDeleteFailureReason.deleteFailed,
            );
    }

    if (entry.canReturnPreparedMealToInventory) {
      return _returnPreparedMealToInventory(entry);
    }

    final sourceItemId = entry.sourceInventoryItemId?.trim();
    final amountToRestore = entry.sourceInventoryAmountToRestore;
    if (sourceItemId == null ||
        sourceItemId.isEmpty ||
        amountToRestore == null ||
        amountToRestore < 1) {
      return const CalorieEntryDeleteResult.failure(
        CalorieEntryDeleteFailureReason.restoreFailed,
      );
    }

    final sourceExists = await _sourceInventoryItemExists(sourceItemId);
    if (!sourceExists) {
      log(
        'deleteEntry(): inventory restore source missing '
        '(entryId=${entry.id}, itemId=$sourceItemId).',
        name: _deleteFlowLogName,
      );
      return const CalorieEntryDeleteResult.failure(
        CalorieEntryDeleteFailureReason.sourceMissing,
      );
    }

    final restored = await _restoreConsumedItem(sourceItemId, amountToRestore);
    if (!restored) {
      return const CalorieEntryDeleteResult.failure(
        CalorieEntryDeleteFailureReason.restoreFailed,
      );
    }

    final deleted = await _deleteDiaryEntry(entry);
    if (deleted) {
      return const CalorieEntryDeleteResult.success(restoredToInventory: true);
    }

    final rolledBack = await _rollbackRestoredItem(
      sourceItemId,
      amountToRestore,
      consumedAt: entry.loggedAt,
    );
    if (!rolledBack) {
      log(
        'Failed to rollback restored inventory amount '
        'after diary delete failure entryId=${entry.id} '
        'itemId=$sourceItemId amount=$amountToRestore.',
        name: _deleteFlowLogName,
      );
    }
    return const CalorieEntryDeleteResult.failure(
      CalorieEntryDeleteFailureReason.deleteFailed,
    );
  }

  Future<CalorieEntryDeleteResult> _returnPreparedMealToInventory(
    CalorieEntry entry,
  ) async {
    final sourceMealId = entry.bundleSourcePreparedMealId?.trim();
    final portionsToRestore = entry.bundleConsumedPortions;
    if (sourceMealId == null ||
        sourceMealId.isEmpty ||
        portionsToRestore == null ||
        portionsToRestore <= 0) {
      log(
        '_returnPreparedMealToInventory(): missing prepared meal restore '
        'data (entryId=${entry.id}, mealId=$sourceMealId, '
        'portions=$portionsToRestore).',
        name: _deleteFlowLogName,
      );
      return const CalorieEntryDeleteResult.failure(
        CalorieEntryDeleteFailureReason.restoreFailed,
      );
    }

    final sourceExists = await _sourcePreparedMealExists(sourceMealId);
    if (!sourceExists) {
      log(
        '_returnPreparedMealToInventory(): prepared meal source missing '
        '(entryId=${entry.id}, mealId=$sourceMealId).',
        name: _deleteFlowLogName,
      );
      return const CalorieEntryDeleteResult.failure(
        CalorieEntryDeleteFailureReason.sourceMissing,
      );
    }

    log(
      '_returnPreparedMealToInventory(): restoring prepared meal '
      '(entryId=${entry.id}, mealId=$sourceMealId, '
      'portions=$portionsToRestore, '
      'loggedAt=${entry.loggedAt.toIso8601String()}, '
      'createdAt=${entry.createdAt.toIso8601String()}).',
      name: _deleteFlowLogName,
    );
    final restored = await _restorePreparedMealPortions(
      mealId: sourceMealId,
      portions: portionsToRestore,
    );
    if (!restored) {
      log(
        '_returnPreparedMealToInventory(): restore failed '
        '(entryId=${entry.id}, mealId=$sourceMealId, '
        'portions=$portionsToRestore).',
        name: _deleteFlowLogName,
      );
      return const CalorieEntryDeleteResult.failure(
        CalorieEntryDeleteFailureReason.restoreFailed,
      );
    }

    final deleted = await _deleteDiaryEntry(entry);
    if (deleted) {
      log(
        '_returnPreparedMealToInventory(): restore and diary delete '
        'succeeded (entryId=${entry.id}, mealId=$sourceMealId).',
        name: _deleteFlowLogName,
      );
      return const CalorieEntryDeleteResult.success(restoredToInventory: true);
    }

    log(
      '_returnPreparedMealToInventory(): diary delete failed after restore '
      '(entryId=${entry.id}, mealId=$sourceMealId, '
      'portions=$portionsToRestore).',
      name: _deleteFlowLogName,
    );
    final rolledBack = await _rollbackRestoredPreparedMeal(
      mealId: sourceMealId,
      discardedPortions: portionsToRestore,
    );
    if (!rolledBack) {
      log(
        'Failed to rollback restored prepared meal portions '
        'after diary delete failure entryId=${entry.id} '
        'mealId=$sourceMealId portions=$portionsToRestore.',
        name: _deleteFlowLogName,
      );
    } else {
      log(
        '_returnPreparedMealToInventory(): rollback after diary delete '
        'failure succeeded (entryId=${entry.id}, mealId=$sourceMealId).',
        name: _deleteFlowLogName,
      );
    }
    return const CalorieEntryDeleteResult.failure(
      CalorieEntryDeleteFailureReason.deleteFailed,
    );
  }

  Future<bool> _deleteDiaryEntry(CalorieEntry entry) async {
    final deleted = await _deleteEntryById(entry.id);
    if (deleted) {
      await _invalidateSnapshotsFromDay(entry.loggedAt);
    }
    return deleted;
  }
}

Future<bool> _noopInvalidateSnapshotsFromDay(DateTime day) async {
  return true;
}

Future<bool> _invalidateWeeklyCheckInSnapshotsFromDay({
  required DateTime day,
  required CalorieSettingsRepository settingsRepository,
}) async {
  try {
    final previous = await settingsRepository.readSettings();
    final nextSettings = previous.invalidateWeeklyCheckInSnapshotsFromDay(
      day: day,
      invalidatedAt: DateTime.now(),
    );
    if (identical(previous, nextSettings)) {
      return true;
    }
    return settingsRepository.saveSettings(nextSettings);
  } on Object catch (error, stackTrace) {
    log(
      'Failed to invalidate weekly check-in snapshots.',
      name: _deleteFlowLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return false;
  }
}
