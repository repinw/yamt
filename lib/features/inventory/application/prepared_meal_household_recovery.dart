import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/household/application/'
    'household_access_recovery_utils.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Checks whether prepared meal controller should recover household access.
bool shouldRecoverPreparedMealHouseholdAccess({
  required Ref ref,
  required Object error,
  required bool isRecoveringHouseholdAccess,
  required String? currentHouseholdDataOwnerUserId,
}) {
  return shouldRecoverControllerHouseholdAccess(
    ref: ref,
    error: error,
    isRecoveringHouseholdAccess: isRecoveringHouseholdAccess,
    currentHouseholdDataOwnerUserId: currentHouseholdDataOwnerUserId,
  );
}

/// Recovers prepared meal controller after household access changed.
Future<void> recoverPreparedMealHouseholdAccess({
  required Ref ref,
  required bool isRecoveringHouseholdAccess,
  required void Function({required bool value}) setIsRecoveringHouseholdAccess,
  required void Function(AsyncValue<List<PreparedMeal>> nextState) setState,
  required Future<List<PreparedMeal>> Function() restartSubscription,
  required String? currentHouseholdDataOwnerUserId,
  required String logName,
  required bool showLoading,
}) {
  return recoverControllerHouseholdAccess<PreparedMeal>(
    ref: ref,
    isRecoveringHouseholdAccess: isRecoveringHouseholdAccess,
    setIsRecoveringHouseholdAccess: setIsRecoveringHouseholdAccess,
    setState: setState,
    restartHouseholdScopedSubscription: restartSubscription,
    currentHouseholdDataOwnerUserId: currentHouseholdDataOwnerUserId,
    householdAccessRecoveryLogName: logName,
    householdAccessRecoveryMessage:
        'Rebuilding prepared meal stream after household access changed.',
    showLoading: showLoading,
  );
}
