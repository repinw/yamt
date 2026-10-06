import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/'
    'calorie_entry_amount_edit_flow.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';
import 'package:yamt/features/calories/presentation/controllers/calorie_entries_controller.dart';

part 'calorie_entry_editor_controller.g.dart';

const _controllerLogName = 'CalorieEntryEditorController';

/// Controller managing save and delete of calorie entries from the diary.
@riverpod
class CalorieEntryEditorController extends _$CalorieEntryEditorController {
  @override
  void build() {
    ref.keepAlive();
  }

  /// Saves a newly created or edited calorie entry.
  Future<bool> saveEntry({
    required CalorieEntry entry,
    bool isEditing = false,
  }) async {
    log(
      'Saving calorie entry ${entry.id} (edit=$isEditing).',
      name: _controllerLogName,
    );
    final notifier = ref.read(calorieEntriesControllerProvider.notifier);
    final saved = await notifier.saveEntry(entry, isNewEntry: !isEditing);

    log(
      'Calorie entry save completed for ${entry.id} with result=$saved.',
      name: _controllerLogName,
    );
    return saved;
  }

  /// Changes the consumed amount of a stored entry.
  ///
  /// An entry logged from the inventory moves its stock with the new amount.
  Future<CalorieEntryAmountChangeResult> changeAmount({
    required CalorieEntry entry,
    required double amount,
  }) async {
    final flow = ref.read(calorieEntryAmountEditFlowProvider);
    return await flow.changeAmount(
      entry: entry,
      amount: amount,
      now: ref.read(clockProvider)(),
    );
  }

  /// Checks if entry source can be restored to inventory.
  Future<bool> canRestoreSource(CalorieEntry entry) async {
    final deleteFlow = ref.read(calorieEntryDeleteFlowProvider);
    return await deleteFlow.canRestoreSource(entry);
  }

  /// Deletes or returns entry to inventory.
  Future<CalorieEntryDeleteResult> deleteEntry({
    required CalorieEntry entry,
    required bool restoreToInventory,
  }) async {
    final deleteFlow = ref.read(calorieEntryDeleteFlowProvider);
    return await deleteFlow.deleteEntry(
      entry: entry,
      restoreToInventory: restoreToInventory,
    );
  }

  /// Undoes [deleteEntry]: saves [entry] again and, when the delete returned
  /// its stock, takes that stock out of the inventory again.
  Future<bool> undoDelete(
    CalorieEntry entry, {
    required bool restoredToInventory,
  }) async {
    final saved = await saveEntry(entry: entry);
    if (!saved || !restoredToInventory) {
      return saved;
    }
    final deleteFlow = ref.read(calorieEntryDeleteFlowProvider);
    if (await deleteFlow.takeBackRestored(entry)) {
      return true;
    }
    await deleteFlow.deleteEntry(entry: entry, restoreToInventory: false);
    return false;
  }
}
