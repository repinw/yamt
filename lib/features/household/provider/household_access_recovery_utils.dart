import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/household/provider/household_permission_recovery.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';

/// Should recover controller household access.
bool shouldRecoverControllerHouseholdAccess({
  required Ref ref,
  required Object error,
  required bool isRecoveringHouseholdAccess,
  required String? currentHouseholdDataOwnerUserId,
}) {
  final profile = ref.read(userProfileProvider).asData?.value;
  final actualDataOwnerUserId = ref.read(householdDataOwnerUserIdProvider);
  final effectiveDataOwnerUserId = ref.read(
    effectiveHouseholdDataOwnerUserIdProvider,
  );
  return shouldRecoverFromHouseholdPermissionDenied(
    error: error,
    isRecoveringHouseholdAccess: isRecoveringHouseholdAccess,
    currentUserId: signedInHouseholdRecoveryUserId(ref) ?? profile?.uid,
    actualDataOwnerUserId: actualDataOwnerUserId,
    effectiveDataOwnerUserId:
        currentHouseholdDataOwnerUserId ?? effectiveDataOwnerUserId,
    profileHouseholdId: profile?.householdId,
  );
}

/// Documented member.
Future<void> recoverControllerHouseholdAccess<T>({
  required Ref ref,
  required bool isRecoveringHouseholdAccess,
  required void Function({required bool value}) setIsRecoveringHouseholdAccess,
  required void Function(AsyncValue<List<T>> nextState) setState,
  required Future<List<T>> Function() restartHouseholdScopedSubscription,
  required String? currentHouseholdDataOwnerUserId,
  required String householdAccessRecoveryLogName,
  required String householdAccessRecoveryMessage,
  required bool showLoading,
  void Function()? onSkippedHouseholdAccessRecovery,
}) async {
  if (isRecoveringHouseholdAccess || !ref.mounted) {
    return;
  }

  setIsRecoveringHouseholdAccess(value: true);
  try {
    if (showLoading) {
      setState(AsyncLoading<List<T>>());
    }
    final nextState = await AsyncValue.guard(
      () => performControllerHouseholdAccessRecovery(
        ref: ref,
        restartHouseholdScopedSubscription: restartHouseholdScopedSubscription,
        currentHouseholdDataOwnerUserId: currentHouseholdDataOwnerUserId,
        householdAccessRecoveryLogName: householdAccessRecoveryLogName,
        householdAccessRecoveryMessage: householdAccessRecoveryMessage,
        onSkippedHouseholdAccessRecovery: onSkippedHouseholdAccessRecovery,
      ),
    );
    if (!ref.mounted) {
      return;
    }
    setState(nextState);
  } finally {
    setIsRecoveringHouseholdAccess(value: false);
  }
}

/// Documented member.
Future<List<T>> performControllerHouseholdAccessRecovery<T>({
  required Ref ref,
  required Future<List<T>> Function() restartHouseholdScopedSubscription,
  required String? currentHouseholdDataOwnerUserId,
  required String householdAccessRecoveryLogName,
  required String householdAccessRecoveryMessage,
  void Function()? onSkippedHouseholdAccessRecovery,
}) async {
  final personalUserId = signedInHouseholdRecoveryUserId(ref);
  final staleOwnerUserId = normalizeHouseholdScopeValue(
    currentHouseholdDataOwnerUserId,
  );
  if (personalUserId != null &&
      staleOwnerUserId != null &&
      staleOwnerUserId != personalUserId) {
    log(householdAccessRecoveryMessage, name: householdAccessRecoveryLogName);
    ref
        .read(householdDataOwnerRecoveryProvider.notifier)
        .recoverToPersonalScope(
          staleOwnerUserId: staleOwnerUserId,
          personalUserId: personalUserId,
        );
  } else {
    onSkippedHouseholdAccessRecovery?.call();
  }
  return restartHouseholdScopedSubscription();
}
