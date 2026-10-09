import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_entry_day_change.dart';
import 'package:yamt/features/calories/application/calorie_entry_saver.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';

part 'inventory_entry_delete_service.g.dart';

const _logName = 'InventoryEntryDeleteService';

/// The inventory entry delete service.
@riverpod
InventoryEntryDeleteService inventoryEntryDeleteService(Ref ref) {
  return InventoryEntryDeleteService(
    diary: ref.watch(calorieLogRepositoryProvider),
    saver: ref.watch(calorieEntrySaverProvider),
    dayChange: ref.watch(calorieEntryDayChangeProvider),
    itemStore: ref.watch(inventoryCalorieEntryCommitStoreProvider),
    mealStore: ref.watch(preparedMealCalorieEntryCommitStoreProvider),
    items: ref.watch(inventoryItemRepositoryProvider),
    meals: ref.watch(preparedMealRepositoryProvider),
    pendings: ref.watch(inventoryPendingConsumptionStoreProvider),
  );
}

/// Deletes diary entries and undoes the delete. An entry that took stock
/// can give it back to the Vorrat; the delete and the stock change are one
/// write.
class InventoryEntryDeleteService {
  /// Creates the service.
  const new({
    required this._diary,
    required this._saver,
    required this._dayChange,
    required this._itemStore,
    required this._mealStore,
    required this._items,
    required this._meals,
    required this._pendings,
  });

  final CalorieLogRepositoryContract _diary;
  final CalorieEntrySaver _saver;
  final CalorieEntryDayChange _dayChange;
  final InventoryCalorieEntryCommitStore _itemStore;
  final PreparedMealCalorieEntryCommitStore? _mealStore;
  final InventoryItemRepository _items;
  final PreparedMealRepository _meals;
  final InventoryPendingConsumptionStore _pendings;

  static const _restoreFailed = CalorieEntryDeleteResult.failure(
    CalorieEntryDeleteFailureReason.restoreFailed,
  );

  /// Whether the stock that [entry] took can still go back: its item, one
  /// of its foods' items, or its prepared meal still exists. A failed lookup
  /// counts as yes, so the delete still tries.
  Future<bool> canRestoreSource(CalorieEntry entry) async {
    try {
      if (entry.canReturnCombinedToInventory || entry.canRestoreToInventory) {
        return (await _existingAmounts(entry)).isNotEmpty;
      }
      if (entry.canReturnPreparedMealToInventory) {
        final mealId = entry.bundleSourcePreparedMealId!.trim();
        return (await _meals.readAllForChange()).any(
          (meal) => meal.id == mealId,
        );
      }
      return false;
    } on Object catch (error, stackTrace) {
      log(
        'Could not check the stock source of entry ${entry.id}.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return true;
    }
  }

  /// Deletes [entry]. With [restoreToInventory], gives its stock or portions
  /// back in the same write.
  Future<CalorieEntryDeleteResult> delete(
    CalorieEntry entry, {
    required bool restoreToInventory,
  }) async {
    final CalorieEntryDeleteResult result;
    if (!restoreToInventory) {
      result = await _diary.deleteEntry(entry.id)
          ? const CalorieEntryDeleteResult.success(restoredToInventory: false)
          : const CalorieEntryDeleteResult.failure(
              CalorieEntryDeleteFailureReason.deleteFailed,
            );
    } else if (entry.canReturnCombinedToInventory) {
      result = await _restoreItems(entry, _restorableAmounts(entry));
    } else if (entry.canReturnPreparedMealToInventory) {
      result =
          await _mealStore?.deleteEntryAndRestorePreparedMeal(entry: entry) ??
          _restoreFailed;
    } else if (entry.canRestoreToInventory) {
      result = await _restoreItems(entry, _restorableAmounts(entry));
    } else {
      result = _restoreFailed;
    }
    if (result.isSuccess) {
      await _dayChange(entry.loggedAt);
    }
    return result;
  }

  /// Undoes [delete]: saves [entry] again and, when the delete gave stock
  /// back, takes that stock again in the same write. Returns false when
  /// nothing was saved.
  Future<bool> undoDelete(
    CalorieEntry entry, {
    required bool restoredToInventory,
  }) async {
    if (!restoredToInventory) {
      return await _saver(entry);
    }
    if (entry.canReturnPreparedMealToInventory && !entry.isCombined) {
      final mealStore = _mealStore;
      return mealStore != null &&
          await _saver(
            entry,
            persistEntry: (entry) =>
                mealStore.commitEntryAndPreparedMeal(entry: entry),
          );
    }
    // Only the items that still exist get stock taken again, at most what
    // they hold now.
    final Map<String, int> amounts;
    try {
      amounts = await _existingAmounts(entry, capAtStock: true);
    } on Object catch (error, stackTrace) {
      log(
        'Could not read the items to undo the delete of entry ${entry.id}.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
    if (amounts.isEmpty) {
      // A combined entry still comes back; a single one without its item
      // does not.
      return entry.isCombined && await _saver(entry);
    }
    return await _saver(
      entry,
      persistEntry: (entry) async => _reportStock(
        await _itemStore.commitEntryAndInventoryItems(
          entry: entry,
          pendingConsumptions: [
            for (final MapEntry(key: itemId, value: amount) in amounts.entries)
              PendingInventoryConsumption(
                id: '${entry.id}-$itemId',
                itemId: itemId,
                amount: amount,
              ),
          ],
        ),
      ),
    );
  }

  /// Hands the new stock of [results] to the Vorrat list at once, so its
  /// next whole-list save does not write the old stock back. Returns
  /// whether there are results.
  bool _reportStock(List<InventoryCalorieEntryCommitResult>? results) {
    if (results == null) {
      return false;
    }
    for (final result in results) {
      _pendings.finalize(
        id: '',
        itemId: result.itemId,
        quantity: result.quantity,
        currentAmount: result.currentAmount,
      );
    }
    return true;
  }

  Future<CalorieEntryDeleteResult> _restoreItems(
    CalorieEntry entry,
    Map<String, int> amounts,
  ) async {
    final restored = await _itemStore.deleteEntryAndRestoreItems(
      entry: entry,
      amountsByItemId: amounts,
    );
    if (!_reportStock(restored)) {
      return _restoreFailed;
    }
    if (restored!.isEmpty) {
      return const CalorieEntryDeleteResult.failure(
        CalorieEntryDeleteFailureReason.sourceMissing,
      );
    }
    return const CalorieEntryDeleteResult.success(restoredToInventory: true);
  }

  /// The stock to give back per item: one item for a single entry, one per
  /// food for a combined entry.
  Map<String, int> _restorableAmounts(CalorieEntry entry) {
    if (entry.isCombined) {
      return {
        for (final component in entry.bundleComponents)
          if (component.canRestoreToInventory)
            component.sourceInventoryItemId!.trim():
                component.sourceInventoryAmountToRestore!,
      };
    }
    if (!entry.canRestoreToInventory) {
      return const {};
    }
    return {
      entry.sourceInventoryItemId!.trim():
          entry.sourceInventoryAmountToRestore!,
    };
  }

  /// [_restorableAmounts] of the items that still exist. With
  /// [capAtStock], each amount is at most the item's stock, and items
  /// without stock are left out.
  Future<Map<String, int>> _existingAmounts(
    CalorieEntry entry, {
    bool capAtStock = false,
  }) async {
    final amounts = _restorableAmounts(entry);
    if (amounts.isEmpty) {
      return amounts;
    }
    final stock = {
      for (final item in await _items.readAll()) item.id: item.availableAmount,
    };
    return {
      for (final MapEntry(key: itemId, value: amount) in amounts.entries)
        if (stock[itemId] case final available?)
          if (!capAtStock)
            itemId: amount
          else if (available > 0)
            itemId: amount < available ? amount : available,
    };
  }
}
