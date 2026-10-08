import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/inventory/application/inventory_item_writer.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_stock_changes.dart';

part 'inventory_item_mutation_service.g.dart';

/// The result of reducing inventory item stock.
typedef InventoryItemReductionResult = ({int removedAmount});

/// A deleted item and where it stood in the list, so it can come back.
typedef DeletedInventoryItem = ({InventoryItem item, int index});

/// The Vorrat item mutations provider.
@riverpod
InventoryItemMutationService inventoryItemMutationService(Ref ref) =>
    InventoryItemMutationService(
      writer: ref.watch(inventoryItemWriterProvider),
      clock: ref.watch(clockProvider),
    );

/// Changes the stock of Vorrat items, adds and deletes them.
///
/// Each mutation takes the current list, writes only the items it changed,
/// records the change in the Vorrat history, and returns its result with
/// the list it wrote. A failed write throws.
/// The caller runs the mutations one after the other, so each starts from
/// the list the one before wrote.
class InventoryItemMutationService {
  /// Creates the mutations.
  new({required this._writer, required this._clock});

  final InventoryItemWriter _writer;
  final DateTime Function() _clock;

  /// Eats [amount] of the item, capped at its stock.
  Future<InventoryItemChange<InventoryItemReductionResult?>> eat(
    List<InventoryItem> items,
    String itemId,
    int amount, {
    DateTime? consumedAt,
  }) async {
    final before = findInventoryItem(items, itemId);
    final removed = clampedRemovalAmount(before, amount);
    if (removed == null) {
      return (result: null, written: null);
    }
    final next = buildReducedItems(
      currentItems: items,
      itemId: itemId,
      amount: removed,
      consumedAt: consumedAt ?? _clock(),
    );
    if (next == null || !await _writer.save(items, next)) {
      return (result: null, written: null);
    }
    await _writer.record(
      InventoryActivityEventType.itemConsumed,
      before,
      before: before,
      after: findInventoryItem(next, itemId),
      amount: removed,
      happenedAt: consumedAt,
    );
    return (result: (removedAmount: removed), written: next);
  }

  /// Returns several amounts to their items in one write. Nothing changes
  /// when an item is missing.
  Future<InventoryItemChange<bool>> restore(
    List<InventoryItem> items,
    Map<String, int> amounts,
  ) async {
    var next = items;
    for (final MapEntry(key: itemId, value: amount) in amounts.entries) {
      final restored = buildRestoredItems(
        currentItems: next,
        itemId: itemId,
        amount: amount,
      );
      if (restored == null) {
        return (result: false, written: null);
      }
      next = restored;
    }
    if (!await _writer.save(items, next)) {
      return (result: false, written: null);
    }
    for (final MapEntry(key: itemId, value: amount) in amounts.entries) {
      await _writer.recordRestore(items, next, itemId, amount);
    }
    return (result: true, written: next);
  }

  /// Adds a new item.
  Future<InventoryItemChange<bool>> add(
    List<InventoryItem> items,
    InventoryItem item,
  ) async {
    if (!await _writer.append(item)) {
      return (result: false, written: null);
    }
    await _writer.record(
      InventoryActivityEventType.itemAdded,
      item,
      after: item,
      amount: item.availableAmount,
    );
    return (
      result: true,
      written: [...items.where((current) => current.id != item.id), item],
    );
  }

  /// Deletes the item; returns it with its place for [restoreDeleted].
  Future<InventoryItemChange<DeletedInventoryItem?>> delete(
    List<InventoryItem> items,
    String itemId,
  ) async {
    final index = items.indexWhere((item) => item.id == itemId);
    if (index < 0) {
      return (result: null, written: null);
    }
    final item = items[index];
    final next = List.of(items)..removeAt(index);
    if (!await _writer.save(items, next)) {
      return (result: null, written: null);
    }
    await _writer.record(
      InventoryActivityEventType.itemDeleted,
      item,
      before: item,
      amount: item.availableAmount,
    );
    return (result: (item: item, index: index), written: next);
  }

  /// Puts a deleted item back at its place; true also when it is back
  /// already.
  Future<InventoryItemChange<bool>> restoreDeleted(
    List<InventoryItem> items,
    DeletedInventoryItem deleted,
  ) async {
    if (items.any((item) => item.id == deleted.item.id)) {
      return (result: true, written: null);
    }
    final next = List.of(items)
      ..insert(deleted.index.clamp(0, items.length), deleted.item);
    if (!await _writer.save(items, next)) {
      return (result: false, written: null);
    }
    await _writer.record(
      InventoryActivityEventType.itemRestored,
      deleted.item,
      after: deleted.item,
      amount: deleted.item.availableAmount,
    );
    return (result: true, written: next);
  }
}
