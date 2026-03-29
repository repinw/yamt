import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';

final inventoryBackedCalorieEntrySaveFlowProvider =
    Provider<InventoryBackedCalorieEntrySaveFlow>((ref) {
      return _ProviderBackedInventoryCalorieEntrySaveFlow(
        inventoryController: ref.read(
          inventoryItemsControllerProvider.notifier,
        ),
        commitStore: ref.read(inventoryCalorieEntryCommitStoreProvider),
      );
    });

abstract interface class InventoryBackedCalorieEntrySaveFlow {
  Future<bool> saveEntry({
    required CalorieEntry entry,
    required String pendingConsumptionId,
  });
}

class _ProviderBackedInventoryCalorieEntrySaveFlow
    implements InventoryBackedCalorieEntrySaveFlow {
  const _ProviderBackedInventoryCalorieEntrySaveFlow({
    required InventoryItemsController inventoryController,
    required InventoryCalorieEntryCommitStore commitStore,
  }) : _inventoryController = inventoryController,
       _commitStore = commitStore;

  final InventoryItemsController _inventoryController;
  final InventoryCalorieEntryCommitStore _commitStore;

  @override
  Future<bool> saveEntry({
    required CalorieEntry entry,
    required String pendingConsumptionId,
  }) async {
    final pendingConsumption = _inventoryController.pendingConsumptionById(
      pendingConsumptionId,
    );
    if (pendingConsumption == null) {
      return false;
    }

    final commitResult = await _commitStore.commitEntryAndInventory(
      entry: entry,
      pendingConsumption: pendingConsumption,
    );
    if (commitResult == null) {
      return false;
    }

    final finalized = await _inventoryController
        .finalizeCommittedPendingConsumption(
          draftId: pendingConsumptionId,
          itemId: commitResult.itemId,
          quantity: commitResult.quantity,
          currentAmount: commitResult.currentAmount,
        );
    if (finalized) {
      return true;
    }

    await _inventoryController.refresh();
    return true;
  }
}
