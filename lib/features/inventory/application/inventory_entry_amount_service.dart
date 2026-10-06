import 'dart:developer' show log;
import 'dart:math' show min;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_entry_saver.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_edits.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';

part 'inventory_entry_amount_service.g.dart';

const _logName = 'InventoryEntryAmountService';

/// How far the Vorrat stock followed a changed amount.
enum InventoryEntryStockChange {
  /// The stock now matches the new amount.
  applied,

  /// The stock ran out before it could follow the increase.
  stockExhausted,

  /// The source item is no longer in the Vorrat.
  sourceMissing,

  /// The entry takes no stock, or its pieces do not follow the amount.
  stockUnchanged,
}

/// Result of changing the consumed amount of a diary entry.
class InventoryEntryAmountChange {
  /// Creates the result.
  const new({required this.saved, required this.entry, required this.stock});

  /// Whether the changed entry was stored.
  final bool saved;

  /// The stored entry, or the unchanged one when nothing was stored.
  final CalorieEntry entry;

  /// How far the stock followed the change.
  final InventoryEntryStockChange stock;
}

/// The inventory entry amount service.
@riverpod
InventoryEntryAmountService inventoryEntryAmountService(Ref ref) {
  return InventoryEntryAmountService(
    saver: ref.watch(calorieEntrySaverProvider),
    itemStore: ref.watch(inventoryCalorieEntryCommitStoreProvider),
    items: ref.watch(inventoryItemRepositoryProvider),
    pendings: ref.watch(inventoryPendingConsumptionStoreProvider),
    now: ref.watch(clockProvider),
  );
}

/// Changes the consumed amount of diary entries. An entry that took stock
/// by weight or volume moves it with the amount, in the same write: more
/// takes more, as far as the stock reaches, and less gives the difference
/// back. Pieces keep their stock.
class InventoryEntryAmountService {
  /// Creates the service.
  const new({
    required this._saver,
    required this._itemStore,
    required this._items,
    required this._pendings,
    required this._now,
  });

  final CalorieEntrySaver _saver;
  final InventoryCalorieEntryCommitStore _itemStore;
  final InventoryItemRepository _items;
  final InventoryPendingConsumptionStore _pendings;
  final DateTime Function() _now;

  /// Stores [entry] with [amount] and moves its stock with it.
  Future<InventoryEntryAmountChange> changeAmount(
    CalorieEntry entry,
    double amount,
  ) async {
    final rescaled = rescaleCalorieEntry(entry, amount: amount, now: _now());
    final itemId = entry.sourceInventoryItemId?.trim();
    final reserved = entry.sourceInventoryAmountToRestore;
    if (!entry.canRestoreToInventory || itemId == null || reserved == null) {
      return await _saveOnly(
        entry,
        rescaled,
        InventoryEntryStockChange.stockUnchanged,
      );
    }
    final InventoryItem? item;
    try {
      item = (await _items.readAll()).where((i) => i.id == itemId).firstOrNull;
    } on Object catch (error, stackTrace) {
      log(
        'Could not read item $itemId to change entry ${entry.id}.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      // Saving without the stock would let entry and Vorrat drift apart.
      return InventoryEntryAmountChange(
        saved: false,
        entry: entry,
        stock: InventoryEntryStockChange.stockUnchanged,
      );
    }
    if (item == null) {
      return await _saveOnly(
        entry,
        rescaled,
        InventoryEntryStockChange.sourceMissing,
      );
    }
    if (!inventoryItemUsesFixedCalorieUnit(item)) {
      return await _saveOnly(
        entry,
        rescaled,
        InventoryEntryStockChange.stockUnchanged,
      );
    }

    final delta = amount.round() - reserved;
    if (delta == 0) {
      return await _saveOnly(
        entry,
        rescaled,
        InventoryEntryStockChange.applied,
      );
    }
    if (delta < 0) {
      return await _saveWithStock(
        entry,
        rescaled.copyWith(sourceInventoryAmountToRestore: reserved + delta),
        InventoryEntryStockChange.applied,
        (stored) => _itemStore.saveEntryAndRestoreItems(
          entry: stored,
          amountsByItemId: {itemId: -delta},
        ),
      );
    }
    final taken = min(delta, item.availableAmount);
    final stock = taken < delta
        ? InventoryEntryStockChange.stockExhausted
        : InventoryEntryStockChange.applied;
    if (taken == 0) {
      return await _saveOnly(entry, rescaled, stock);
    }
    return await _saveWithStock(
      entry,
      rescaled.copyWith(sourceInventoryAmountToRestore: reserved + taken),
      stock,
      takesStock: true,
      (stored) => _itemStore.commitEntryAndInventoryItems(
        entry: stored,
        pendingConsumptions: [
          PendingInventoryConsumption(
            id: '${entry.id}-amount',
            itemId: itemId,
            amount: taken,
          ),
        ],
      ),
    );
  }

  Future<InventoryEntryAmountChange> _saveOnly(
    CalorieEntry entry,
    CalorieEntry changed,
    InventoryEntryStockChange stock,
  ) async {
    final saved = await _saver(changed);
    return InventoryEntryAmountChange(
      saved: saved,
      entry: saved ? changed : entry,
      stock: stock,
    );
  }

  Future<InventoryEntryAmountChange> _saveWithStock(
    CalorieEntry entry,
    CalorieEntry changed,
    InventoryEntryStockChange stock,
    Future<List<InventoryCalorieEntryCommitResult>?> Function(CalorieEntry)
    write, {
    bool takesStock = false,
  }) async {
    final saved = await _saver(
      changed,
      persistEntry: (stored) async {
        final results = await write(stored);
        if (results == null || results.isEmpty) {
          return false;
        }
        // Hands the new stock to the Vorrat list at once, so its next
        // whole-list save does not write the old stock back.
        for (final result in results) {
          _pendings.finalize(
            id: '',
            itemId: result.itemId,
            quantity: result.quantity,
            currentAmount: result.currentAmount,
            consumedAt: takesStock ? stored.loggedAt : null,
          );
        }
        return true;
      },
    );
    return InventoryEntryAmountChange(
      saved: saved,
      entry: saved ? changed : entry,
      stock: stock,
    );
  }
}
