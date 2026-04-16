import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';

const _deleteFlowLogName = 'CalorieEntryDeleteFlow';

enum CalorieEntryDeleteFailureReason { deleteFailed, restoreFailed }

class CalorieEntryDeleteResult {
  const CalorieEntryDeleteResult._({
    required this.isSuccess,
    required this.restoredToInventory,
    this.failureReason,
  });

  const CalorieEntryDeleteResult.success({required bool restoredToInventory})
    : this._(isSuccess: true, restoredToInventory: restoredToInventory);

  const CalorieEntryDeleteResult.failure(CalorieEntryDeleteFailureReason reason)
    : this._(
        isSuccess: false,
        restoredToInventory: false,
        failureReason: reason,
      );

  final bool isSuccess;
  final bool restoredToInventory;
  final CalorieEntryDeleteFailureReason? failureReason;
}

final calorieEntryDeleteFlowProvider = Provider<CalorieEntryDeleteFlow>((ref) {
  return CalorieEntryDeleteFlow(
    deleteEntryById: ref
        .read(calorieEntriesControllerProvider.notifier)
        .deleteEntry,
    restoreConsumedItem: ref
        .read(inventoryItemsControllerProvider.notifier)
        .restoreConsumedItem,
    rollbackRestoredItem: (itemId, amount, {consumedAt}) => ref
        .read(inventoryItemsControllerProvider.notifier)
        .eatItem(itemId, amount, consumedAt: consumedAt),
    restorePreparedMealPortions: ref
        .read(preparedMealsControllerProvider.notifier)
        .restorePreparedMealPortions,
    rollbackRestoredPreparedMeal:
        ({required mealId, required discardedPortions}) => ref
            .read(preparedMealsControllerProvider.notifier)
            .throwAwayPreparedMeal(
              mealId: mealId,
              discardedPortions: discardedPortions,
              reason: InventoryDiscardReason.other,
            ),
  );
});

class CalorieEntryDeleteFlow {
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
    required Future<bool> Function({
      required String mealId,
      required int portions,
    })
    restorePreparedMealPortions,
    required Future<bool> Function({
      required String mealId,
      required int discardedPortions,
    })
    rollbackRestoredPreparedMeal,
  }) : _deleteEntryById = deleteEntryById,
       _restoreConsumedItem = restoreConsumedItem,
       _rollbackRestoredItem = rollbackRestoredItem,
       _restorePreparedMealPortions = restorePreparedMealPortions,
       _rollbackRestoredPreparedMeal = rollbackRestoredPreparedMeal;

  final Future<bool> Function(String entryId) _deleteEntryById;
  final Future<bool> Function(String itemId, int amount) _restoreConsumedItem;
  final Future<bool> Function(String itemId, int amount, {DateTime? consumedAt})
  _rollbackRestoredItem;
  final Future<bool> Function({required String mealId, required int portions})
  _restorePreparedMealPortions;
  final Future<bool> Function({
    required String mealId,
    required int discardedPortions,
  })
  _rollbackRestoredPreparedMeal;

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
      final deleted = await _deleteEntryById(entry.id);
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

    final restored = await _restoreConsumedItem(sourceItemId, amountToRestore);
    if (!restored) {
      return const CalorieEntryDeleteResult.failure(
        CalorieEntryDeleteFailureReason.restoreFailed,
      );
    }

    final deleted = await _deleteEntryById(entry.id);
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
        portionsToRestore < 1) {
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

    final deleted = await _deleteEntryById(entry.id);
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
}
