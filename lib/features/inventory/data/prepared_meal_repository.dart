import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/household/application/household_data_scope.dart';

import 'package:yamt/features/inventory/data/firestore_prepared_meal_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository_contract.dart';
import 'package:yamt/features/inventory/data/prepared_meal_store.dart';

export 'firestore_prepared_meal_repository.dart';
export 'prepared_meal_repository_contract.dart';
export 'prepared_meal_store.dart';

part 'prepared_meal_repository.g.dart';

/// Prepared meal repository.
@riverpod
PreparedMealRepository preparedMealRepository(Ref ref) {
  final scope = ref.watch(householdDataScopeProvider);
  return FirestorePreparedMealRepository(
    household: scope == null
        ? null
        : (
            householdId: scope.householdId,
            store: FirestorePreparedMealStore(
              firestore: scope.firestore,
              cipher: scope.cipher,
            ),
          ),
    sessionShutdownSignal: ref.watch(sessionShutdownSignalProvider),
  );
}
