import 'dart:developer' show log;

import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';

const _restoreCoordinatorLogName = 'CalorieEntryInventoryRestoreCoordinator';

/// Coordinates returning consumed inventory stock or prepared meal portions
/// when a calorie entry is deleted, including rollback on delete failure.
class CalorieEntryInventoryRestoreCoordinator {
  /// Creates an inventory restore coordinator.
  const new({
    required this.restoreConsumedItem,
    required this.rollbackRestoredItem,
    required this.sourceInventoryItemExists,
    required this.restorePreparedMealPortions,
    required this.rollbackRestoredPreparedMeal,
    required this.sourcePreparedMealExists,
  });

  /// Restores consumed inventory item amount.
  final Future<bool> Function(String itemId, int amount) restoreConsumedItem;

  /// Rolls back restored inventory item amount.
  final Future<bool> Function(String itemId, int amount, {DateTime? consumedAt})
  rollbackRestoredItem;

  /// Checks if source inventory item exists.
  final Future<bool> Function(String itemId) sourceInventoryItemExists;

  /// Restores prepared meal portions.
  final Future<bool> Function({required String mealId, required num portions})
  restorePreparedMealPortions;

  /// Rolls back restored prepared meal portions.
  final Future<bool> Function({
    required String mealId,
    required num discardedPortions,
  })
  rollbackRestoredPreparedMeal;

  /// Checks if source prepared meal exists.
  final Future<bool> Function(String mealId) sourcePreparedMealExists;

  /// Whether the entry's inventory restore source still exists.
  Future<bool> canRestoreSource(CalorieEntry entry) async {
    if (entry.canReturnPreparedMealToInventory) {
      final mealId = entry.bundleSourcePreparedMealId?.trim();
      if (mealId == null || mealId.isEmpty) {
        return false;
      }
      return await sourcePreparedMealExists(mealId);
    }

    if (entry.canRestoreToInventory) {
      final itemId = entry.sourceInventoryItemId?.trim();
      if (itemId == null || itemId.isEmpty) {
        return false;
      }
      return await sourceInventoryItemExists(itemId);
    }

    return false;
  }

  /// Takes the stock or portions that deleting [entry] returned out of the
  /// inventory again. Undoes [restoreAndCompensate] after the entry is back.
  Future<bool> takeBackRestored(CalorieEntry entry) async {
    if (entry.canReturnPreparedMealToInventory) {
      final mealId = entry.bundleSourcePreparedMealId?.trim();
      final portions = entry.bundleConsumedPortions;
      if (mealId == null || mealId.isEmpty || portions == null) {
        return false;
      }
      return await rollbackRestoredPreparedMeal(
        mealId: mealId,
        discardedPortions: portions,
      );
    }

    final itemId = entry.sourceInventoryItemId?.trim();
    final amount = entry.sourceInventoryAmountToRestore;
    if (itemId == null || itemId.isEmpty || amount == null) {
      return false;
    }
    return await rollbackRestoredItem(
      itemId,
      amount,
      consumedAt: entry.loggedAt,
    );
  }

  /// Restores inventory and executes [onDiaryDelete], rolling back on failure.
  Future<CalorieEntryDeleteResult> restoreAndCompensate({
    required CalorieEntry entry,
    required Future<bool> Function() onDiaryDelete,
  }) async {
    if (entry.canReturnPreparedMealToInventory) {
      return await _returnPreparedMealToInventory(
        entry: entry,
        onDiaryDelete: onDiaryDelete,
      );
    }

    return await _returnItemToInventory(
      entry: entry,
      onDiaryDelete: onDiaryDelete,
    );
  }

  Future<CalorieEntryDeleteResult> _returnItemToInventory({
    required CalorieEntry entry,
    required Future<bool> Function() onDiaryDelete,
  }) async {
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

    final sourceExists = await sourceInventoryItemExists(sourceItemId);
    if (!sourceExists) {
      log(
        'deleteEntry(): inventory restore source missing '
        '(entryId=${entry.id}, itemId=$sourceItemId).',
        name: _restoreCoordinatorLogName,
      );
      return const CalorieEntryDeleteResult.failure(
        CalorieEntryDeleteFailureReason.sourceMissing,
      );
    }

    final restored = await restoreConsumedItem(sourceItemId, amountToRestore);
    if (!restored) {
      return const CalorieEntryDeleteResult.failure(
        CalorieEntryDeleteFailureReason.restoreFailed,
      );
    }

    final deleted = await onDiaryDelete();
    if (deleted) {
      return const CalorieEntryDeleteResult.success(restoredToInventory: true);
    }

    final rolledBack = await rollbackRestoredItem(
      sourceItemId,
      amountToRestore,
      consumedAt: entry.loggedAt,
    );
    if (!rolledBack) {
      log(
        'Failed to rollback restored inventory amount '
        'after diary delete failure entryId=${entry.id} '
        'itemId=$sourceItemId amount=$amountToRestore.',
        name: _restoreCoordinatorLogName,
      );
    }
    return const CalorieEntryDeleteResult.failure(
      CalorieEntryDeleteFailureReason.deleteFailed,
    );
  }

  Future<CalorieEntryDeleteResult> _returnPreparedMealToInventory({
    required CalorieEntry entry,
    required Future<bool> Function() onDiaryDelete,
  }) async {
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
        name: _restoreCoordinatorLogName,
      );
      return const CalorieEntryDeleteResult.failure(
        CalorieEntryDeleteFailureReason.restoreFailed,
      );
    }

    final sourceExists = await sourcePreparedMealExists(sourceMealId);
    if (!sourceExists) {
      log(
        '_returnPreparedMealToInventory(): prepared meal source missing '
        '(entryId=${entry.id}, mealId=$sourceMealId).',
        name: _restoreCoordinatorLogName,
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
      name: _restoreCoordinatorLogName,
    );
    final restored = await restorePreparedMealPortions(
      mealId: sourceMealId,
      portions: portionsToRestore,
    );
    if (!restored) {
      log(
        '_returnPreparedMealToInventory(): restore failed '
        '(entryId=${entry.id}, mealId=$sourceMealId, '
        'portions=$portionsToRestore).',
        name: _restoreCoordinatorLogName,
      );
      return const CalorieEntryDeleteResult.failure(
        CalorieEntryDeleteFailureReason.restoreFailed,
      );
    }

    final deleted = await onDiaryDelete();
    if (deleted) {
      log(
        '_returnPreparedMealToInventory(): restore and diary delete '
        'succeeded (entryId=${entry.id}, mealId=$sourceMealId).',
        name: _restoreCoordinatorLogName,
      );
      return const CalorieEntryDeleteResult.success(restoredToInventory: true);
    }

    log(
      '_returnPreparedMealToInventory(): diary delete failed after restore '
      '(entryId=${entry.id}, mealId=$sourceMealId, '
      'portions=$portionsToRestore).',
      name: _restoreCoordinatorLogName,
    );
    final rolledBack = await rollbackRestoredPreparedMeal(
      mealId: sourceMealId,
      discardedPortions: portionsToRestore,
    );
    if (!rolledBack) {
      log(
        'Failed to rollback restored prepared meal portions '
        'after diary delete failure entryId=${entry.id} '
        'mealId=$sourceMealId portions=$portionsToRestore.',
        name: _restoreCoordinatorLogName,
      );
    } else {
      log(
        '_returnPreparedMealToInventory(): rollback after diary delete '
        'failure succeeded (entryId=${entry.id}, mealId=$sourceMealId).',
        name: _restoreCoordinatorLogName,
      );
    }
    return const CalorieEntryDeleteResult.failure(
      CalorieEntryDeleteFailureReason.deleteFailed,
    );
  }
}
