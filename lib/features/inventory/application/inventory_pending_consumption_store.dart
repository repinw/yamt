import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
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

/// Stock reserved for eats that are not saved yet.
///
/// The reservation lives here, outside the screens, because the calorie
/// editor saves it after the eat page has closed.
abstract interface class InventoryPendingConsumptionStore {
  /// Emits application-level finalizations for observers such as controllers.
  Stream<InventoryPendingConsumptionFinalized> get finalizations;

  /// Reserves [amount] of [item], capped at its stock, under a new id.
  /// Returns null when [item] holds nothing or [amount] is below 1.
  PendingInventoryConsumption? stage(InventoryItem item, int amount);

  /// Finds a staged inventory consumption.
  PendingInventoryConsumption? pendingConsumptionById(String id);

  /// Discards a staged inventory consumption.
  Future<bool> discard(String id);

  /// Removes the consumption [id] after its write went through and tells
  /// [finalizations] the stock the item has now.
  void finalize({
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
  PendingInventoryConsumption? stage(InventoryItem item, int amount) {
    final available = item.availableAmount;
    final stagedAmount = amount > available ? available : amount;
    if (stagedAmount < 1) {
      return null;
    }
    final pending = PendingInventoryConsumption(
      id: const Uuid().v4(),
      itemId: item.id,
      amount: stagedAmount,
    );
    _pendingById[pending.id] = pending;
    return pending;
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
  void finalize({
    required String id,
    required String itemId,
    required int quantity,
    required int currentAmount,
    DateTime? consumedAt,
  }) {
    _pendingById.remove(id);
    _finalizationController.add(
      InventoryPendingConsumptionFinalized(
        id: id,
        itemId: itemId,
        quantity: quantity,
        currentAmount: currentAmount,
        consumedAt: consumedAt,
      ),
    );
  }

  Future<void> dispose() async {
    await _finalizationController.close();
  }
}
