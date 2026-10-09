import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/household/application/household_data_scope.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'firestore_kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_data_providers.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository_contract.dart';
import 'package:yamt/features/kitchen_utensils/data/kitchen_utensil_store.dart';

part 'kitchen_utensil_repository.g.dart';

/// Kitchen utensil repository.
@riverpod
KitchenUtensilRepository kitchenUtensilRepository(Ref ref) {
  final scope = ref.watch(householdDataScopeProvider);
  return FirestoreKitchenUtensilRepository(
    household: scope == null
        ? null
        : (
            householdId: scope.householdId,
            store: FirestoreKitchenUtensilStore(
              firestore: scope.firestore,
              cipher: scope.cipher,
            ),
          ),
    sessionShutdownSignal: ref.watch(sessionShutdownSignalProvider),
    imageStore: ref.watch(kitchenUtensilImageStoreProvider),
  );
}
