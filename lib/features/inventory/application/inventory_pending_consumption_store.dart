import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';

part 'inventory_pending_consumption_store.g.dart';

/// Describes a committed inventory consumption for application observers.
final class InventoryPendingConsumptionFinalized {
  /// Creates a pending-consumption finalization event.
  const new({
    required this.id,
    required this.itemId,
    required this.quantity,
    required this.currentAmount,
    this.consumedAt,
  });

  /// The pending consumption id.
  final String id;

  /// The inventory item id.
  final String itemId;

  /// The resulting item quantity.
  final int quantity;

  /// The resulting amount remaining on the item.
  final int currentAmount;

  /// The time of the consumption, when available.
  final DateTime? consumedAt;
}

/// Pending-consumption state shared by inventory-backed completion flows.
abstract interface class InventoryPendingConsumptionStore {
  /// Emits application-level finalizations for observers such as controllers.
  Stream<InventoryPendingConsumptionFinalized> get finalizations;

  /// Stores a newly staged inventory consumption.
  void stage(PendingInventoryConsumption pending);

  /// Finds a staged inventory consumption.
  PendingInventoryConsumption? pendingConsumptionById(String id);

  /// Discards a staged inventory consumption.
  Future<bool> discard(String id);

  /// Removes a staged consumption after atomic persistence completed.
  Future<bool> finalize({
    required String id,
    required String itemId,
    required int quantity,
    required int currentAmount,
    DateTime? consumedAt,
  });
}

/// Provides the pending-consumption registry used by application flows.
@Riverpod(keepAlive: true)
InventoryPendingConsumptionStore inventoryPendingConsumptionStore(Ref ref) {
  final registry = _InventoryPendingConsumptionRegistry();
  ref.onDispose(() {
    unawaited(registry.dispose());
  });
  return registry;
}

final class _InventoryPendingConsumptionRegistry
    implements InventoryPendingConsumptionStore {
  final _pendingById = <String, PendingInventoryConsumption>{};
  final _finalizationController =
      StreamController<InventoryPendingConsumptionFinalized>.broadcast(
        sync: true,
      );

  @override
  Stream<InventoryPendingConsumptionFinalized> get finalizations =>
      _finalizationController.stream;

  @override
  void stage(PendingInventoryConsumption pending) {
    _pendingById[pending.id] = pending;
  }

  @override
  PendingInventoryConsumption? pendingConsumptionById(String id) {
    return _pendingById[id];
  }

  @override
  Future<bool> discard(String id) async {
    return _pendingById.remove(id) != null;
  }

  @override
  Future<bool> finalize({
    required String id,
    required String itemId,
    required int quantity,
    required int currentAmount,
    DateTime? consumedAt,
  }) async {
    if (_pendingById.remove(id) == null) {
      return false;
    }
    _finalizationController.add(
      InventoryPendingConsumptionFinalized(
        id: id,
        itemId: itemId,
        quantity: quantity,
        currentAmount: currentAmount,
        consumedAt: consumedAt,
      ),
    );
    return true;
  }

  Future<void> dispose() async {
    await _finalizationController.close();
  }
}
