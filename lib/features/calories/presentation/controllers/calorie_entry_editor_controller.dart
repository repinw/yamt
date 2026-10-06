import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/'
    'calorie_entry_amount_edit_flow.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/controllers/calorie_entries_controller.dart';

part 'calorie_entry_editor_controller.g.dart';

const _controllerLogName = 'CalorieEntryEditorController';

/// Saves, changes, and deletes logged calorie entries for the details page.
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

  /// Deletes [entry] from the diary. Returns whether it was deleted.
  Future<bool> deleteEntry(CalorieEntry entry) {
    return ref
        .read(calorieEntriesControllerProvider.notifier)
        .deleteEntry(entry.id);
  }
}
