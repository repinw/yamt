import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_entry_delete_service.dart';

part 'diary_entry_delete_controller.g.dart';

/// Deletes diary entries and undoes the delete. An entry that took stock
/// can give it back to the Vorrat.
@riverpod
class DiaryEntryDeleteController extends _$DiaryEntryDeleteController {
  @override
  FutureOr<void> build() {}

  /// Whether the stock that [entry] took can still go back.
  Future<bool> canRestoreSource(CalorieEntry entry) =>
      _whileAlive((service) => service.canRestoreSource(entry));

  /// Deletes [entry]; with [restoreToInventory], gives its stock back.
  Future<CalorieEntryDeleteResult> delete(
    CalorieEntry entry, {
    required bool restoreToInventory,
  }) => _whileAlive(
    (service) => service.delete(entry, restoreToInventory: restoreToInventory),
  );

  /// Undoes [delete]. Returns false when nothing was saved.
  Future<bool> undoDelete(
    CalorieEntry entry, {
    required bool restoredToInventory,
  }) => _whileAlive(
    (service) =>
        service.undoDelete(entry, restoredToInventory: restoredToInventory),
  );

  /// Keeps this controller and the service alive while [action] runs, so
  /// the write finishes after its page closes.
  Future<T> _whileAlive<T>(
    Future<T> Function(InventoryEntryDeleteService service) action,
  ) async {
    final link = ref.keepAlive();
    final subscription = ref.listen(
      inventoryEntryDeleteServiceProvider,
      (_, _) {},
    );
    try {
      return await action(subscription.read());
    } finally {
      subscription.close();
      link.close();
    }
  }
}
