import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';

const _flowLogName = 'InventoryBackedCalorieEntrySaveFlow';

/// The inventory backed calorie entry save flow provider.
final inventoryBackedCalorieEntrySaveFlowProvider =
    Provider<InventoryBackedCalorieEntrySaveFlow>((ref) {
      return InventoryBackedCalorieEntrySaveFlow(
        inventoryController: ref.read(
          inventoryItemsControllerProvider.notifier,
        ),
        commitStore: ref.read(inventoryCalorieEntryCommitStoreProvider),
      );
    });

/// Defines inventory backed calorie entry save flow.
class InventoryBackedCalorieEntrySaveFlow {
  /// The inventory backed calorie entry save flow.
  const InventoryBackedCalorieEntrySaveFlow({
    required InventoryItemsController inventoryController,
    required InventoryCalorieEntryCommitStore commitStore,
  }) : _inventoryController = inventoryController,
       _commitStore = commitStore;

  final InventoryItemsController _inventoryController;
  final InventoryCalorieEntryCommitStore _commitStore;

  /// Save entry.
  Future<bool> saveEntry({
    required CalorieEntry entry,
    required String pendingConsumptionId,
  }) async {
    log(
      'Starting inventory-backed calorie save for ${entry.id} '
      '(pendingConsumptionId=$pendingConsumptionId).',
      name: _flowLogName,
    );
    final pendingConsumption = _inventoryController.pendingConsumptionById(
      pendingConsumptionId,
    );
    if (pendingConsumption == null) {
      log(
        'Pending consumption $pendingConsumptionId was not found for '
        'calorie entry ${entry.id}.',
        name: _flowLogName,
      );
      return false;
    }

    log(
      'Found pending consumption $pendingConsumptionId '
      '(itemId=${pendingConsumption.itemId}, '
      'amount=${pendingConsumption.amount}).',
      name: _flowLogName,
    );

    final commitResult = await _commitStore.commitEntryAndInventory(
      entry: entry,
      pendingConsumption: pendingConsumption,
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

    final finalized = await _inventoryController
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
    await _inventoryController.refresh();
    log(
      'Inventory controller refreshed after finalize failure for '
      'calorie entry ${entry.id}.',
      name: _flowLogName,
    );
    return true;
  }
}
