import 'dart:developer' show log;

import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';

const _logName = 'CalorieEntryCombinedStockRestore';

/// Returns the stock of a combined entry's foods when the entry is deleted.
///
/// Foods whose stock item no longer exists are skipped. All other foods are
/// returned in one inventory write, so either every food comes back or none.
/// When the diary delete fails afterwards, the stock is taken out again.
class CalorieEntryCombinedStockRestore {
  /// Creates the restore with the inventory operations it needs.
  const new({
    required this.restoreConsumedItems,
    required this.rollbackRestoredItems,
    required this.sourceInventoryItemExists,
  });

  /// Returns amounts to stock items in one write.
  final Future<bool> Function(Map<String, int> amountsByItemId)
  restoreConsumedItems;

  /// Takes returned amounts out of stock items again in one write.
  final Future<bool> Function(
    Map<String, int> amountsByItemId, {
    DateTime? consumedAt,
  })
  rollbackRestoredItems;

  /// Whether a stock item still exists.
  final Future<bool> Function(String itemId) sourceInventoryItemExists;

  /// Whether at least one of [entry]'s stock items still exists.
  Future<bool> canRestoreSource(CalorieEntry entry) async {
    return (await _existingAmounts(entry)).isNotEmpty;
  }

  /// Returns the stock of [entry]'s foods, then runs [onDiaryDelete].
  Future<CalorieEntryDeleteResult> restoreAndCompensate({
    required CalorieEntry entry,
    required Future<bool> Function() onDiaryDelete,
  }) async {
    final amounts = await _existingAmounts(entry);
    if (amounts.isEmpty) {
      log(
        'No stock item of combined entry ${entry.id} exists anymore.',
        name: _logName,
      );
      return const CalorieEntryDeleteResult.failure(
        CalorieEntryDeleteFailureReason.sourceMissing,
      );
    }

    if (!await restoreConsumedItems(amounts)) {
      log(
        'Returning the stock of combined entry ${entry.id} failed.',
        name: _logName,
      );
      return const CalorieEntryDeleteResult.failure(
        CalorieEntryDeleteFailureReason.restoreFailed,
      );
    }

    if (await onDiaryDelete()) {
      return const CalorieEntryDeleteResult.success(restoredToInventory: true);
    }
    if (!await rollbackRestoredItems(amounts, consumedAt: entry.loggedAt)) {
      log(
        'Taking back the stock of combined entry ${entry.id} after a failed '
        'diary delete failed.',
        name: _logName,
      );
    }
    return const CalorieEntryDeleteResult.failure(
      CalorieEntryDeleteFailureReason.deleteFailed,
    );
  }

  /// Takes the returned stock out again after the entry came back by undo.
  Future<bool> takeBackRestored(CalorieEntry entry) async {
    final amounts = await _existingAmounts(entry);
    if (amounts.isEmpty) {
      return true;
    }
    return await rollbackRestoredItems(amounts, consumedAt: entry.loggedAt);
  }

  /// The amount to return per stock item that still exists.
  Future<Map<String, int>> _existingAmounts(CalorieEntry entry) async {
    final amounts = <String, int>{};
    for (final component in entry.bundleComponents) {
      final itemId = component.sourceInventoryItemId;
      if (component.canRestoreToInventory &&
          await sourceInventoryItemExists(itemId!)) {
        amounts[itemId] = component.sourceInventoryAmountToRestore!;
      }
    }
    return amounts;
  }
}
