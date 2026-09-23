import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/'
    'calorie_entry_inventory_restore_coordinator.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_snapshot_invalidator.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';
import 'package:yamt/features/calories/provider/calorie_overview_revision_provider.dart';

part 'calorie_entry_delete_flow.g.dart';

const _deleteFlowLogName = 'CalorieEntryDeleteFlow';

/// The calorie entry delete flow provider.
@riverpod
CalorieEntryDeleteFlow calorieEntryDeleteFlow(Ref ref) {
  ref.keepAlive();
  final calorieLogRepository = ref.read(calorieLogRepositoryProvider);
  final calorieSettingsRepository = ref.read(calorieSettingsRepositoryProvider);
  final overviewRevision = ref.read(calorieOverviewRevisionProvider.notifier);

  return CalorieEntryDeleteFlow(
    deleteEntryById: (entryId) async {
      final deleted = await calorieLogRepository.deleteEntry(entryId);
      if (deleted) {
        overviewRevision.markChanged();
      }
      return deleted;
    },
    restoreConsumedItem: _restoreConsumedItemUnavailable,
    rollbackRestoredItem: _rollbackRestoredItemUnavailable,
    sourceInventoryItemExists: _sourceInventoryItemUnavailable,
    restorePreparedMealPortions: _restorePreparedMealPortionsUnavailable,
    rollbackRestoredPreparedMeal: _rollbackPreparedMealUnavailable,
    invalidateSnapshotsFromDay: (day) =>
        invalidateCalorieWeeklyCheckInSnapshotsFromDay(
          day: day,
          settingsRepository: calorieSettingsRepository,
          now: ref.read(clockProvider)(),
        ),
    sourcePreparedMealExists: _sourcePreparedMealUnavailable,
  );
}

/// Defines calorie entry delete flow.
class CalorieEntryDeleteFlow {
  /// The calorie entry delete flow.
  new({
    required this.deleteEntryById,
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
    this.invalidateSnapshotsFromDay = _noopInvalidateSnapshotsFromDay,
  }) : _inventoryRestorer = CalorieEntryInventoryRestoreCoordinator(
         restoreConsumedItem: restoreConsumedItem,
         rollbackRestoredItem: rollbackRestoredItem,
         sourceInventoryItemExists: sourceInventoryItemExists,
         restorePreparedMealPortions: restorePreparedMealPortions,
         rollbackRestoredPreparedMeal: rollbackRestoredPreparedMeal,
         sourcePreparedMealExists: sourcePreparedMealExists,
       );

  /// Callback used to delete a calorie diary entry by its ID.
  final Future<bool> Function(String entryId) deleteEntryById;

  /// Callback used to invalidate weekly check-in snapshots from the given date.
  final Future<bool> Function(DateTime day) invalidateSnapshotsFromDay;
  final CalorieEntryInventoryRestoreCoordinator _inventoryRestorer;

  /// Whether the entry's inventory restore source still exists.
  Future<bool> canRestoreSource(CalorieEntry entry) {
    return _inventoryRestorer.canRestoreSource(entry);
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

    return await _inventoryRestorer.restoreAndCompensate(
      entry: entry,
      onDiaryDelete: () => _deleteDiaryEntry(entry),
    );
  }

  /// Takes the stock that deleting [entry] with a restore returned out of the
  /// inventory again.
  Future<bool> takeBackRestored(CalorieEntry entry) {
    return _inventoryRestorer.takeBackRestored(entry);
  }

  Future<bool> _deleteDiaryEntry(CalorieEntry entry) async {
    final deleted = await deleteEntryById(entry.id);
    if (deleted) {
      await invalidateSnapshotsFromDay(entry.loggedAt);
    }
    return deleted;
  }
}

Future<bool> _noopInvalidateSnapshotsFromDay(DateTime day) async {
  return true;
}

Future<bool> _restoreConsumedItemUnavailable(String itemId, int amount) async {
  return false;
}

Future<bool> _rollbackRestoredItemUnavailable(
  String itemId,
  int amount, {
  DateTime? consumedAt,
}) async {
  return false;
}

Future<bool> _sourceInventoryItemUnavailable(String itemId) async {
  return false;
}

Future<bool> _restorePreparedMealPortionsUnavailable({
  required String mealId,
  required num portions,
}) async {
  return false;
}

Future<bool> _rollbackPreparedMealUnavailable({
  required String mealId,
  required num discardedPortions,
}) async {
  return false;
}

Future<bool> _sourcePreparedMealUnavailable(String mealId) async {
  return false;
}
