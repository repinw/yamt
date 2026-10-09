import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/household/application/household_data_scope.dart';

import 'package:yamt/features/inventory/data/'
    'firestore_inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_item_repository_contract.dart';
import 'package:yamt/features/inventory/data/inventory_item_store.dart';

export 'firestore_inventory_item_repository.dart';
export 'inventory_item_repository_contract.dart';
export 'inventory_item_store.dart';

part 'inventory_item_repository.g.dart';

/// Inventory item repository.
@riverpod
InventoryItemRepository inventoryItemRepository(Ref ref) {
  final scope = ref.watch(householdDataScopeProvider);
  return FirestoreInventoryItemRepository(
    household: scope == null
        ? null
        : (
            householdId: scope.householdId,
            store: FirestoreInventoryItemStore(
              firestore: scope.firestore,
              cipher: scope.cipher,
            ),
          ),
    sessionShutdownSignal: ref.watch(sessionShutdownSignalProvider),
  );
}
