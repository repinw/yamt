import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/ref_while_alive.dart';
import 'package:yamt/features/calories/application/calorie_entry_day_change.dart';
import 'package:yamt/features/calories/application/calorie_entry_saver.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_entry_amount_service.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_entry_delete_service.dart';

part 'diary_entry_change_controller.g.dart';

/// Saves, changes, and deletes logged diary entries. An entry that took
/// stock moves it with a changed amount and can give it back on delete.
@riverpod
class DiaryEntryChangeController extends _$DiaryEntryChangeController {
  @override
  FutureOr<void> build() {}

  /// Saves [entry].
  ///
  /// [previousDay] is the day the entry was logged on before; when it is
  /// earlier than the new day, the days from it on count as changed too.
  Future<bool> save(CalorieEntry entry, {DateTime? previousDay}) =>
      ref.whileAlive(calorieEntrySaverProvider, (saver) async {
        final dayChange = ref.read(calorieEntryDayChangeProvider);
        final saved = await saver(entry);
        if (saved &&
            previousDay != null &&
            previousDay.isBefore(entry.loggedAt)) {
          await dayChange(previousDay);
        }
        return saved;
      });

  /// Stores [entry] with [amount] and moves its stock with it.
  Future<InventoryEntryAmountChange> changeAmount(
    CalorieEntry entry,
    double amount,
  ) => ref.whileAlive(
    inventoryEntryAmountServiceProvider,
    (service) => service.changeAmount(entry, amount),
  );

  /// Whether the stock that [entry] took can still go back.
  Future<bool> canRestoreSource(CalorieEntry entry) => ref.whileAlive(
    inventoryEntryDeleteServiceProvider,
    (service) => service.canRestoreSource(entry),
  );

  /// Deletes [entry]; with [restoreToInventory], gives its stock back.
  Future<CalorieEntryDeleteResult> delete(
    CalorieEntry entry, {
    required bool restoreToInventory,
  }) => ref.whileAlive(
    inventoryEntryDeleteServiceProvider,
    (service) => service.delete(entry, restoreToInventory: restoreToInventory),
  );

  /// Undoes [delete]. Returns false when nothing was saved.
  Future<bool> undoDelete(
    CalorieEntry entry, {
    required bool restoredToInventory,
  }) => ref.whileAlive(
    inventoryEntryDeleteServiceProvider,
    (service) =>
        service.undoDelete(entry, restoredToInventory: restoredToInventory),
  );
}
