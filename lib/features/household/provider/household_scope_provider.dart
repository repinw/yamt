import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/household/provider/household_members_provider.dart';

part 'household_scope_provider.g.dart';

/// Defines household data owner recovery state.
class HouseholdDataOwnerRecoveryState {
  /// The household data owner recovery state.
  const HouseholdDataOwnerRecoveryState({
    required this.staleOwnerUserId,
    required this.personalUserId,
  });

  /// The stale owner user id.
  final String staleOwnerUserId;

  /// The personal user id.
  final String personalUserId;
}

/// Household data owner user id.
@riverpod
String? householdDataOwnerUserId(Ref ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) {
    return null;
  }

  final householdId = ref.watch(userProfileProvider).asData?.value?.householdId;
  final normalizedHouseholdId = householdId?.trim();
  if (normalizedHouseholdId != null && normalizedHouseholdId.isNotEmpty) {
    return normalizedHouseholdId;
  }
  return user.uid;
}

/// Defines household data owner recovery.
@riverpod
class HouseholdDataOwnerRecovery extends _$HouseholdDataOwnerRecovery {
  @override
  HouseholdDataOwnerRecoveryState? build() {
    return null;
  }

  /// Recover to personal scope.
  void recoverToPersonalScope({
    required String staleOwnerUserId,
    required String personalUserId,
  }) {
    final normalizedStaleOwnerUserId = staleOwnerUserId.trim();
    final normalizedPersonalUserId = personalUserId.trim();
    if (normalizedStaleOwnerUserId.isEmpty ||
        normalizedPersonalUserId.isEmpty) {
      return;
    }

    state = HouseholdDataOwnerRecoveryState(
      staleOwnerUserId: normalizedStaleOwnerUserId,
      personalUserId: normalizedPersonalUserId,
    );
  }

  /// Clear.
  void clear() {
    state = null;
  }
}

/// Effective household data owner user id.
@riverpod
String? effectiveHouseholdDataOwnerUserId(Ref ref) {
  final actualDataOwnerUserId = ref.watch(householdDataOwnerUserIdProvider);
  final normalizedActualDataOwnerUserId = actualDataOwnerUserId?.trim();
  if (normalizedActualDataOwnerUserId == null ||
      normalizedActualDataOwnerUserId.isEmpty) {
    return null;
  }

  final recoveryState = ref.watch(householdDataOwnerRecoveryProvider);
  if (recoveryState == null) {
    return normalizedActualDataOwnerUserId;
  }

  if (normalizedActualDataOwnerUserId == recoveryState.staleOwnerUserId) {
    return recoveryState.personalUserId;
  }

  return normalizedActualDataOwnerUserId;
}

/// Waits until the signed-in user's profile has resolved before household
/// scoped data controllers choose a data owner.
Future<void> waitForHouseholdDataOwnerProfile(Ref ref) async {
  final user = ref.read(authStateChangesProvider).asData?.value;
  if (user == null) {
    return;
  }

  final profileState = ref.watch(userProfileProvider);
  if (!profileState.isLoading) {
    return;
  }

  await ref.watch(userProfileProvider.future);
}

/// Household has additional members.
@riverpod
bool householdHasAdditionalMembers(Ref ref) {
  final members = ref.watch(householdMembersProvider).asData?.value;
  return (members?.length ?? 0) > 1;
}
