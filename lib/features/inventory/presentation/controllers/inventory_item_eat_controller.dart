import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_create_context.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/application/inventory_combined_eat_service.dart';
import 'package:yamt/features/inventory/application/inventory_eat_service.dart';
import 'package:yamt/features/inventory/application/inventory_entry_delete_service.dart';
import 'package:yamt/features/inventory/application/inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/application/inventory_plan_service.dart';
import 'package:yamt/features/inventory/domain/inventory_eat_outcome.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';

part 'inventory_item_eat_controller.g.dart';

/// Eats Vorrat items for the eat flows: reserves stock, logs the diary entry
/// or the plan, releases a reservation, and undoes an eat or a plan.
@riverpod
class InventoryItemEatController extends _$InventoryItemEatController {
  late InventoryPendingConsumptionStore _pendings;

  @override
  FutureOr<void> build() {
    // Kept so that a flow can still release its stock after this controller
    // was disposed.
    _pendings = ref.watch(inventoryPendingConsumptionStoreProvider);
  }

  /// Reserves [amount] of [item]'s stock, capped at what is left. Returns
  /// null when nothing is left.
  PendingInventoryConsumption? stage(InventoryItem item, int amount) =>
      _pendings.stage(item, amount);

  /// Releases the reservation [pendingId]. Returns whether it was staged.
  Future<bool> discard(String pendingId) => _pendings.discard(pendingId);

  /// Logs [request] for [item] with its reserved [pending] stock.
  Future<InventoryEatOutcome> log({
    required InventoryItem item,
    required InventoryItemEatRequest request,
    required PendingInventoryConsumption pending,
  }) => _whileAlive(
    inventoryEatServiceProvider,
    (service) => service.log(item: item, request: request, pending: pending),
  );

  /// Logs [entry] as the calorie editor returned it, with its reserved
  /// [pending] stock.
  Future<InventoryEatOutcome> logEdited({
    required CalorieEntry entry,
    required PendingInventoryConsumption pending,
    required CalorieInventoryCreateContext inventoryContext,
    CalorieScannedSourceRef? scannedSourceRef,
  }) => _whileAlive(
    inventoryEatServiceProvider,
    (service) => service.logEdited(
      entry: entry,
      pending: pending,
      inventoryContext: inventoryContext,
      scannedSourceRef: scannedSourceRef,
    ),
  );

  /// Logs [foods] as one combined diary entry. Returns null when nothing was
  /// saved.
  Future<CalorieEntry?> logCombined({
    required List<InventoryCombinedFood> foods,
    required DateTime loggedAt,
    required MealType mealType,
  }) => _whileAlive(
    inventoryCombinedEatServiceProvider,
    (service) =>
        service.save(foods: foods, loggedAt: loggedAt, mealType: mealType),
  );

  /// Undoes an eat: deletes [entry] and returns its amount to the stock.
  Future<bool> undo(CalorieEntry entry) =>
      _whileAlive(inventoryEntryDeleteServiceProvider, (service) async {
        final result = await service.delete(entry, restoreToInventory: true);
        return result.isSuccess;
      });

  /// Undoes a plan: deletes [plan]. Returns false when it failed.
  Future<bool> unplan(CalorieEntry plan) => _whileAlive(
    inventoryPlanServiceProvider,
    (planner) async =>
        !(await AsyncValue.guard(() => planner.unplan(plan))).hasError,
  );

  /// Keeps this controller and [provider] alive while [action] runs, so the
  /// write finishes after its screen closes.
  Future<T> _whileAlive<S, T>(
    ProviderListenable<S> provider,
    Future<T> Function(S value) action,
  ) async {
    final link = ref.keepAlive();
    final subscription = ref.listen(provider, (_, _) {});
    try {
      return await action(subscription.read());
    } finally {
      subscription.close();
      link.close();
    }
  }
}
