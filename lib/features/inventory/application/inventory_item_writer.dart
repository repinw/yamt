import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_stock_changes.dart';

part 'inventory_item_writer.g.dart';

/// The Vorrat item writer provider.
@riverpod
InventoryItemWriter inventoryItemWriter(Ref ref) => InventoryItemWriter(
  inventory: ref.watch(inventoryItemRepositoryProvider),
  activity: ref.watch(inventoryActivityEventRepositoryProvider),
  actor: ref.watch(inventoryActivityActorProvider),
  newId: const Uuid().v4,
);

/// The result of a Vorrat item mutation, and the list it wrote last, or null
/// when it wrote nothing that stays.
typedef InventoryItemChange<T> = ({T result, List<InventoryItem>? written});

/// Writes Vorrat item lists and records their changes in the Vorrat
/// history.
class InventoryItemWriter {
  /// Creates the writer.
  new({
    required this._inventory,
    required this._activity,
    required this._actor,
    required this.newId,
  });

  final InventoryItemRepository _inventory;
  final InventoryActivityEventRepository _activity;
  final InventoryActivityActor? _actor;

  /// Makes the ids of new events.
  final String Function() newId;

  /// Writes the items that differ between [previous] and [next].
  Future<bool> save(List<InventoryItem> previous, List<InventoryItem> next) =>
      _inventory.saveChanges(previous: previous, next: next);

  /// Writes [previous] back after a later step failed. A failed write is
  /// logged and gives false, so the caller keeps the list that is stored.
  Future<bool> rollBack(
    List<InventoryItem> next,
    List<InventoryItem> previous,
  ) async {
    try {
      return await save(next, previous);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to roll back inventory mutation.',
        name: 'InventoryItemMutationService',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Adds [item] as a new document.
  Future<bool> append(InventoryItem item) =>
      _inventory.appendAll(<InventoryItem>[item]);

  /// Records that [amount] came back to the item [itemId].
  Future<void> recordRestore(
    List<InventoryItem> previous,
    List<InventoryItem> next,
    String itemId,
    int amount,
  ) {
    final before = findInventoryItem(previous, itemId);
    final after = findInventoryItem(next, itemId);
    return record(
      InventoryActivityEventType.itemRestored,
      after ?? before,
      before: before,
      after: after,
      amount: amount,
    );
  }

  /// Records a stock change of [item] in the Vorrat history.
  Future<void> record(
    InventoryActivityEventType type,
    InventoryItem? item, {
    required int amount,
    InventoryItem? before,
    InventoryItem? after,
    DateTime? happenedAt,
    String? reason,
  }) async {
    final actor = _actor;
    if (actor == null || item == null) {
      return;
    }
    final event = InventoryActivityEvent.fromStockChange(
      id: newId(),
      type: type,
      actor: actor,
      item: item,
      amount: amount < 0 ? 0 : amount,
      beforeQuantity: before?.quantity,
      afterQuantity: after?.quantity,
      beforeCurrentAmount: before?.currentAmount,
      afterCurrentAmount: after?.currentAmount,
      happenedAt: happenedAt,
      reason: reason,
    );
    if (!await _activity.appendAll(<InventoryActivityEvent>[event])) {
      log(
        'Failed to record inventory activity event ${event.id}.',
        name: 'InventoryItemMutationService',
      );
    }
  }
}
