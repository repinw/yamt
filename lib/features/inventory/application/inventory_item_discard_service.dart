import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/inventory/application/inventory_item_writer.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_stock_changes.dart';

part 'inventory_item_discard_service.g.dart';

/// The result of discarding inventory item stock.
typedef InventoryItemDiscardResult = ({
  String discardEventId,
  int removedAmount,
});

/// The Vorrat discard service provider.
@riverpod
InventoryItemDiscardService inventoryItemDiscardService(Ref ref) =>
    InventoryItemDiscardService(
      writer: ref.watch(inventoryItemWriterProvider),
      discardEvents: ref.watch(inventoryDiscardEventRepositoryProvider),
      clock: ref.watch(clockProvider),
    );

/// Throws Vorrat stock away and takes that back, together with its discard
/// event.
class InventoryItemDiscardService {
  /// Creates the service.
  new({
    required this._writer,
    required this._discardEvents,
    required this._clock,
  });

  final InventoryItemWriter _writer;
  final InventoryDiscardEventRepository _discardEvents;
  final DateTime Function() _clock;

  /// Throws away [amount] of the item, capped at its stock, and records the
  /// discard. The stock comes back when the discard cannot be saved.
  Future<InventoryItemChange<InventoryItemDiscardResult?>> throwAway(
    List<InventoryItem> items,
    String itemId,
    int amount,
    InventoryDiscardReason reason,
  ) async {
    final item = findInventoryItem(items, itemId);
    final discarded = clampedRemovalAmount(item, amount);
    if (item == null || discarded == null) {
      return (result: null, written: null);
    }
    final next = buildReducedItems(
      currentItems: items,
      itemId: itemId,
      amount: discarded,
      consumedAt: _clock(),
    );
    if (next == null || !await _writer.save(items, next)) {
      return (result: null, written: null);
    }
    final discardEventId = _writer.newId();
    final eventSaved = await _discardEvents.saveEvent(
      InventoryDiscardEvent.fromInventoryItem(
        id: discardEventId,
        item: item,
        discardedAmount: discarded,
        reason: reason,
      ),
    );
    if (!eventSaved) {
      final rolledBack = await _writer.rollBack(next, items);
      return (result: null, written: rolledBack ? null : next);
    }
    await _writer.record(
      InventoryActivityEventType.itemDiscarded,
      item,
      before: item,
      after: findInventoryItem(next, itemId),
      amount: discarded,
      reason: reason.name,
    );
    return (
      result: (discardEventId: discardEventId, removedAmount: discarded),
      written: next,
    );
  }

  /// Gives thrown-away stock back and deletes its discard event. The stock
  /// is taken out again when the event cannot be deleted.
  Future<InventoryItemChange<bool>> undoThrowAway(
    List<InventoryItem> items, {
    required String itemId,
    required int amount,
    required String discardEventId,
  }) async {
    final next = buildRestoredItems(
      currentItems: items,
      itemId: itemId,
      amount: amount,
    );
    if (next == null || !await _writer.save(items, next)) {
      return (result: false, written: null);
    }
    await _writer.recordRestore(items, next, itemId, amount);
    if (await _discardEvents.deleteEvent(discardEventId)) {
      return (result: true, written: next);
    }
    final rolledBack = await _writer.rollBack(next, items);
    if (!rolledBack) {
      log(
        'Failed to rollback thrown-away item undo after discard event '
        'delete failure (itemId=$itemId, discardEventId=$discardEventId).',
        name: 'InventoryItemMutationService',
      );
    }
    return (result: false, written: rolledBack ? null : next);
  }
}
