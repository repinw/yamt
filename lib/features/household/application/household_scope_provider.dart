import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/data/auth_service.dart';

part 'household_scope_provider.g.dart';

/// A household that lost its access, and the own household that replaces it
/// until the profile catches up.
class HouseholdDataOwnerRecoveryState {
  /// Creates the state.
  const new({required this.staleOwnerUserId, required this.personalUserId});

  /// The household whose data the user can no longer read.
  final String staleOwnerUserId;

  /// The own household of the user.
  final String personalUserId;
}

/// The household that the profile names as active, or `null` while signed
/// out or before the own household exists.
@riverpod
String? householdDataOwnerUserId(Ref ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) {
    return null;
  }
  return ref.watch(
    userProfileProvider.select((profile) => profile.asData?.value?.householdId),
  );
}

/// The own household of the signed-in user, or `null` while signed out or
/// before it exists.
@riverpod
String? ownHouseholdId(Ref ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) {
    return null;
  }
  return ref.watch(
    userProfileProvider.select(
      (profile) => profile.asData?.value?.ownHouseholdId,
    ),
  );
}

/// Switches household scoped data to the own household when the active one
/// denies access, until the profile names the own household again.
@riverpod
class HouseholdDataOwnerRecovery extends _$HouseholdDataOwnerRecovery {
  @override
  HouseholdDataOwnerRecoveryState? build() {
    return null;
  }

  /// Reads the own household [personalUserId] instead of
  /// [staleOwnerUserId].
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

  /// Forgets the switch.
  void clear() {
    state = null;
  }
}

/// The id of the household whose data the user sees now.
@riverpod
String? activeHouseholdId(Ref ref) {
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
/// scoped data controllers choose a household.
///
/// Must only be called directly inside a provider's build method to correctly
/// register dependencies.
Future<void> waitForHouseholdDataOwnerProfile(Ref ref) async {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) {
    return;
  }

  final profileState = ref.watch(userProfileProvider);
  if (!profileState.isLoading) {
    return;
  }

  await ref.watch(userProfileProvider.future);
}
