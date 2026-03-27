import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';

part 'calorie_entry_delete_flow.g.dart';

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

abstract interface class CalorieEntryDeleteFlow {
  Future<CalorieEntryDeleteResult> deleteEntry({
    required CalorieEntry entry,
    required bool restoreToInventory,
  });
}

@riverpod
CalorieEntryDeleteFlow calorieEntryDeleteFlow(Ref ref) {
  return _ProviderBackedCalorieEntryDeleteFlow(
    deleteEntryById: ref
        .read(calorieEntriesControllerProvider.notifier)
        .deleteEntry,
    restoreConsumedItem: ref
        .read(inventoryItemsControllerProvider.notifier)
        .restoreConsumedItem,
    rollbackRestoredItem: ref
        .read(inventoryItemsControllerProvider.notifier)
        .eatItem,
    restorePreparedMealPortions: ref
        .read(preparedMealsControllerProvider.notifier)
        .restorePreparedMealPortions,
    rollbackRestoredPreparedMeal: ref
        .read(preparedMealsControllerProvider.notifier)
        .throwAwayPreparedMeal,
  );
}

class _ProviderBackedCalorieEntryDeleteFlow implements CalorieEntryDeleteFlow {
  const _ProviderBackedCalorieEntryDeleteFlow({
    required Future<bool> Function(String entryId) deleteEntryById,
    required Future<bool> Function(String itemId, int amount)
    restoreConsumedItem,
    required Future<bool> Function(String itemId, int amount)
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
  final Future<bool> Function(String itemId, int amount) _rollbackRestoredItem;
  final Future<bool> Function({required String mealId, required int portions})
  _restorePreparedMealPortions;
  final Future<bool> Function({
    required String mealId,
    required int discardedPortions,
  })
  _rollbackRestoredPreparedMeal;

  @override
  Future<CalorieEntryDeleteResult> deleteEntry({
    required CalorieEntry entry,
    required bool restoreToInventory,
  }) async {
    if (!restoreToInventory) {
      final deleted = await _deleteEntryById(entry.id);
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
      return const CalorieEntryDeleteResult.failure(
        CalorieEntryDeleteFailureReason.restoreFailed,
      );
    }

    final restored = await _restorePreparedMealPortions(
      mealId: sourceMealId,
      portions: portionsToRestore,
    );
    if (!restored) {
      return const CalorieEntryDeleteResult.failure(
        CalorieEntryDeleteFailureReason.restoreFailed,
      );
    }

    final deleted = await _deleteEntryById(entry.id);
    if (deleted) {
      return const CalorieEntryDeleteResult.success(restoredToInventory: true);
    }

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
    }
    return const CalorieEntryDeleteResult.failure(
      CalorieEntryDeleteFailureReason.deleteFailed,
    );
  }
}
