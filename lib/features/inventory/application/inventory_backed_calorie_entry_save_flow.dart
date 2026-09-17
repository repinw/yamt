import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';

part 'inventory_backed_calorie_entry_save_flow.g.dart';

const _flowLogName = 'InventoryBackedCalorieEntrySaveFlow';

/// The inventory backed calorie entry save flow provider.
@Riverpod(keepAlive: true)
InventoryBackedCalorieEntrySaveFlow inventoryBackedCalorieEntrySaveFlow(
  Ref ref,
) {
  ref.keepAlive();
  return InventoryBackedCalorieEntrySaveFlow(ref: ref);
}

/// Defines inventory backed calorie entry save flow.
class InventoryBackedCalorieEntrySaveFlow {
  /// The inventory backed calorie entry save flow.
  const new({required this._ref});

  final Ref _ref;

  /// Save entry.
  Future<bool> saveEntry({
    required CalorieEntry entry,
    required String pendingConsumptionId,
    PendingInventoryConsumption? pendingConsumption,
  }) async {
    log(
      'Starting inventory-backed calorie save for ${entry.id} '
      '(pendingConsumptionId=$pendingConsumptionId).',
      name: _flowLogName,
    );
    final pendingStore = _ref.read(inventoryPendingConsumptionStoreProvider);
    final applicationPending = pendingStore.pendingConsumptionById(
      pendingConsumptionId,
    );
    final effectivePendingConsumption =
        pendingConsumption ?? applicationPending;
    if (effectivePendingConsumption == null) {
      log(
        'Pending consumption $pendingConsumptionId was not found for '
        'calorie entry ${entry.id}.',
        name: _flowLogName,
      );
      return false;
    }

    log(
      'Found pending consumption $pendingConsumptionId '
      '(itemId=${effectivePendingConsumption.itemId}, '
      'amount=${effectivePendingConsumption.amount}).',
      name: _flowLogName,
    );

    final commitStore = _ref.read(inventoryCalorieEntryCommitStoreProvider);
    final commitResult = await commitStore.commitEntryAndInventory(
      entry: entry,
      pendingConsumption: effectivePendingConsumption,
    );
    if (commitResult == null) {
      log(
        'Commit store returned null for calorie entry ${entry.id} '
        'and pending consumption $pendingConsumptionId.',
        name: _flowLogName,
      );
      return false;
    }

    log(
      'Commit store persisted calorie entry ${entry.id} '
      '(itemId=${commitResult.itemId}, '
      'quantity=${commitResult.quantity}, '
      'currentAmount=${commitResult.currentAmount}).',
      name: _flowLogName,
    );

    if (applicationPending == null) {
      pendingStore.stage(effectivePendingConsumption);
    }
    final finalized = await pendingStore.finalize(
      id: pendingConsumptionId,
      itemId: commitResult.itemId,
      quantity: commitResult.quantity,
      currentAmount: commitResult.currentAmount,
      consumedAt: entry.loggedAt,
    );
    if (finalized || pendingConsumption != null) {
      log(
        'Finalized pending consumption $pendingConsumptionId for '
        'calorie entry ${entry.id}.',
        name: _flowLogName,
      );
      return true;
    }

    log(
      'Pending consumption $pendingConsumptionId was already finalized '
      'after persisting calorie entry ${entry.id}.',
      name: _flowLogName,
    );
    return true;
  }
}
