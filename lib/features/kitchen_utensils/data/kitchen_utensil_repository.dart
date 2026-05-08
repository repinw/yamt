import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'firestore_kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_data_providers.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository_contract.dart';

part 'kitchen_utensil_repository.g.dart';

/// Kitchen utensil repository.
@riverpod
KitchenUtensilRepository kitchenUtensilRepository(Ref ref) {
  return FirestoreKitchenUtensilRepository(
    session: ref.watch(kitchenUtensilUserSessionProvider),
    sessionShutdownSignal: ref.watch(sessionShutdownSignalProvider),
    store: ref.watch(kitchenUtensilStoreProvider),
    imageStore: ref.watch(kitchenUtensilImageStoreProvider),
  );
}
