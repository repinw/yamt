import 'dart:developer' show log;

import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';

part 'inventory_backed_calorie_entry_save_flow.g.dart';

const _flowLogName = 'InventoryBackedCalorieEntrySaveFlow';

/// The inventory backed calorie entry save flow provider.
@Riverpod(dependencies: [InventoryItemsController])
InventoryBackedCalorieEntrySaveFlow inventoryBackedCalorieEntrySaveFlow(
  Ref ref,
) {
  ref.keepAlive();
  return InventoryBackedCalorieEntrySaveFlow(ref: ref);
}

/// Defines inventory backed calorie entry save flow.
@Dependencies([InventoryItemsController])
class InventoryBackedCalorieEntrySaveFlow {
  /// The inventory backed calorie entry save flow.
  const InventoryBackedCalorieEntrySaveFlow({required Ref ref}) : _ref = ref;

  final Ref _ref;

  /// Save entry.
  Future<bool> saveEntry({
    required CalorieEntry entry,
    required String pendingConsumptionId,
    PendingInventoryConsumption? pendingConsumption,
    InventoryItemsController? inventoryController,
  }) async {
    log(
      'Starting inventory-backed calorie save for ${entry.id} '
      '(pendingConsumptionId=$pendingConsumptionId).',
      name: _flowLogName,
    );
    final effectiveInventoryController =
        inventoryController ??
        _ref.read(inventoryItemsControllerProvider.notifier);
    if (effectiveInventoryController == null) {
      log(
        'Inventory items controller was not available for calorie entry '
        '${entry.id}.',
        name: _flowLogName,
      );
      return false;
    }
    final effectivePendingConsumption =
        pendingConsumption ??
        effectiveInventoryController.pendingConsumptionById(
          pendingConsumptionId,
        );
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

    final finalized = await effectiveInventoryController
        .finalizeCommittedPendingConsumption(
          draftId: pendingConsumptionId,
          itemId: commitResult.itemId,
          quantity: commitResult.quantity,
          currentAmount: commitResult.currentAmount,
          consumedAt: entry.loggedAt,
        );
    if (finalized) {
      log(
        'Finalized pending consumption $pendingConsumptionId for '
        'calorie entry ${entry.id}.',
        name: _flowLogName,
      );
      return true;
    }

    log(
      'Failed to finalize pending consumption $pendingConsumptionId after '
      'persisting calorie entry ${entry.id}. Refreshing inventory controller.',
      name: _flowLogName,
    );
    await effectiveInventoryController.refresh();
    log(
      'Inventory controller refreshed after finalize failure for '
      'calorie entry ${entry.id}.',
      name: _flowLogName,
    );
    return true;
  }
}
