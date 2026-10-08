import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/household/application/household_permission_recovery.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';

/// Whether a controller that watched [currentHouseholdDataOwnerUserId] should
/// switch to the own household after [error].
///
/// Only a denied read in another household than the own one switches: the
/// user left it or an admin removed them.
bool shouldRecoverControllerHouseholdAccess({
  required Ref ref,
  required Object error,
  required bool isRecoveringHouseholdAccess,
  required String? currentHouseholdDataOwnerUserId,
}) {
  if (isRecoveringHouseholdAccess ||
      error is! FirebaseException ||
      error.code != 'permission-denied') {
    return false;
  }
  final ownHouseholdId = ref.read(ownHouseholdIdProvider);
  final watchedHouseholdId = normalizeHouseholdScopeValue(
    currentHouseholdDataOwnerUserId ?? ref.read(activeHouseholdIdProvider),
  );
  return ownHouseholdId != null &&
      watchedHouseholdId != null &&
      watchedHouseholdId != ownHouseholdId;
}

/// Switches a controller to the own household and restarts its
/// subscription.
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

/// Points household scoped data at the own household instead of
/// [currentHouseholdDataOwnerUserId], then restarts the subscription.
Future<List<T>> performControllerHouseholdAccessRecovery<T>({
  required Ref ref,
  required Future<List<T>> Function() restartHouseholdScopedSubscription,
  required String? currentHouseholdDataOwnerUserId,
  required String householdAccessRecoveryLogName,
  required String householdAccessRecoveryMessage,
  void Function()? onSkippedHouseholdAccessRecovery,
}) async {
  final ownHouseholdId = ref.read(ownHouseholdIdProvider);
  final staleHouseholdId = normalizeHouseholdScopeValue(
    currentHouseholdDataOwnerUserId,
  );
  if (ownHouseholdId != null &&
      staleHouseholdId != null &&
      staleHouseholdId != ownHouseholdId) {
    log(householdAccessRecoveryMessage, name: householdAccessRecoveryLogName);
    ref
        .read(householdDataOwnerRecoveryProvider.notifier)
        .recoverToPersonalScope(
          staleOwnerUserId: staleHouseholdId,
          personalUserId: ownHouseholdId,
        );
  } else {
    onSkippedHouseholdAccessRecovery?.call();
  }
  return await restartHouseholdScopedSubscription();
}

/// The household scope as one log line, for a controller that watched
/// [controllerHouseholdId].
String householdScopeDebugDetails(
  Ref ref, {
  required String? controllerHouseholdId,
}) {
  String show(String? value) => normalizeHouseholdScopeValue(value) ?? '<none>';
  final profile = ref.read(userProfileProvider).asData?.value;
  final recoveryState = ref.read(householdDataOwnerRecoveryProvider);
  final currentUserId = signedInHouseholdRecoveryUserId(ref) ?? profile?.uid;
  return 'authUserId=${show(currentUserId)} '
      'profileHouseholdId=${show(profile?.householdId)} '
      'actualDataOwnerId=${show(ref.read(householdDataOwnerUserIdProvider))} '
      'effectiveDataOwnerId=${show(ref.read(activeHouseholdIdProvider))} '
      'controllerDataOwnerId=${show(controllerHouseholdId)} '
      'recoveryStaleOwnerId=${recoveryState?.staleOwnerUserId ?? '<none>'} '
      'recoveryPersonalUserId=${recoveryState?.personalUserId ?? '<none>'}';
}
