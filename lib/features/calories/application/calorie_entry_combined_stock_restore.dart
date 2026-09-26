import 'dart:developer' show log;

import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';

const _logName = 'CalorieEntryCombinedStockRestore';

/// Returns the stock of a combined entry's foods when the entry is deleted.
///
/// Foods whose stock item no longer exists are skipped. When one return
/// fails, or the diary delete fails, the returns already made are taken back.
class CalorieEntryCombinedStockRestore {
  /// Creates the restore with the inventory operations it needs.
  const new({
    required this.restoreConsumedItem,
    required this.rollbackRestoredItem,
    required this.sourceInventoryItemExists,
  });

  /// Returns an amount to a stock item.
  final Future<bool> Function(String itemId, int amount) restoreConsumedItem;

  /// Takes a returned amount out of a stock item again.
  final Future<bool> Function(String itemId, int amount, {DateTime? consumedAt})
  rollbackRestoredItem;

  /// Whether a stock item still exists.
  final Future<bool> Function(String itemId) sourceInventoryItemExists;

  /// Whether at least one of [entry]'s stock items still exists.
  Future<bool> canRestoreSource(CalorieEntry entry) async {
    return (await _existingSources(entry)).isNotEmpty;
  }

  /// Returns the stock of [entry]'s foods, then runs [onDiaryDelete].
  Future<CalorieEntryDeleteResult> restoreAndCompensate({
    required CalorieEntry entry,
    required Future<bool> Function() onDiaryDelete,
  }) async {
    final sources = await _existingSources(entry);
    if (sources.isEmpty) {
      log(
        'No stock item of combined entry ${entry.id} exists anymore.',
        name: _logName,
      );
      return const CalorieEntryDeleteResult.failure(
        CalorieEntryDeleteFailureReason.sourceMissing,
      );
    }

    final restored = <CalorieEntryBundleComponent>[];
    for (final source in sources) {
      final ok = await restoreConsumedItem(
        source.sourceInventoryItemId!,
        source.sourceInventoryAmountToRestore!,
      );
      if (!ok) {
        log(
          'Returning ${source.sourceInventoryItemId} of combined entry '
          '${entry.id} failed; taking back ${restored.length} returns.',
          name: _logName,
        );
        await _takeBack(entry, restored);
        return const CalorieEntryDeleteResult.failure(
          CalorieEntryDeleteFailureReason.restoreFailed,
        );
      }
      restored.add(source);
    }

    if (await onDiaryDelete()) {
      return const CalorieEntryDeleteResult.success(restoredToInventory: true);
    }
    await _takeBack(entry, restored);
    return const CalorieEntryDeleteResult.failure(
      CalorieEntryDeleteFailureReason.deleteFailed,
    );
  }

  /// Takes the returned stock out again after the entry came back by undo.
  /// When one food cannot be taken out, the foods already taken out are
  /// returned again, so the stock matches the deleted entry.
  Future<bool> takeBackRestored(CalorieEntry entry) async {
    return await _takeBack(entry, await _existingSources(entry));
  }

  Future<bool> _takeBack(
    CalorieEntry entry,
    List<CalorieEntryBundleComponent> sources,
  ) async {
    final takenBack = <CalorieEntryBundleComponent>[];
    for (final source in sources) {
      final ok = await rollbackRestoredItem(
        source.sourceInventoryItemId!,
        source.sourceInventoryAmountToRestore!,
        consumedAt: entry.loggedAt,
      );
      if (!ok) {
        log(
          'Taking back ${source.sourceInventoryItemId} of combined entry '
          '${entry.id} failed; returning ${takenBack.length} foods again.',
          name: _logName,
        );
        for (final returned in takenBack) {
          await restoreConsumedItem(
            returned.sourceInventoryItemId!,
            returned.sourceInventoryAmountToRestore!,
          );
        }
        return false;
      }
      takenBack.add(source);
    }
    return true;
  }

  Future<List<CalorieEntryBundleComponent>> _existingSources(
    CalorieEntry entry,
  ) async {
    final sources = <CalorieEntryBundleComponent>[];
    for (final component in entry.bundleComponents) {
      if (component.canRestoreToInventory &&
          await sourceInventoryItemExists(component.sourceInventoryItemId!)) {
        sources.add(component);
      }
    }
    return sources;
  }
}
