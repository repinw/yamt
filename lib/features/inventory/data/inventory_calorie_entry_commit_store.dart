// Commit store stays class-based for provider overrides and test fakes.

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/inventory/data/'
    'firestore_inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_result.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_store_contract.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';

export 'firestore_inventory_calorie_entry_commit_store.dart';
export 'inventory_calorie_entry_commit_mutation_builder.dart';
export 'inventory_calorie_entry_commit_result.dart';
export 'inventory_calorie_entry_commit_store_contract.dart';

part 'inventory_calorie_entry_commit_store.g.dart';

/// The inventory calorie entry commit store provider.
@riverpod
InventoryCalorieEntryCommitStore inventoryCalorieEntryCommitStore(Ref ref) {
  final inventoryOwnerUserId = ref.watch(
    effectiveHouseholdDataOwnerUserIdProvider,
  );
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    return const _UnavailableInventoryCalorieEntryCommitStore();
  }

  return FirestoreInventoryCalorieEntryCommitStore(
    firestore: firestore,
    dataCipher: ref.watch(userDataCipherProvider),
    inventoryOwnerUserId: inventoryOwnerUserId,
    actor: ref.watch(inventoryActivityActorProvider),
  );
}

class _UnavailableInventoryCalorieEntryCommitStore
    implements InventoryCalorieEntryCommitStore {
  const new();

  @override
  Future<InventoryCalorieEntryCommitResult?> commitEntryAndInventory({
    required CalorieEntry entry,
    required PendingInventoryConsumption pendingConsumption,
  }) async {
    return null;
  }
}
