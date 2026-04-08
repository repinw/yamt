import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

part 'household_scope_provider.g.dart';

class HouseholdDataOwnerRecoveryState {
  const HouseholdDataOwnerRecoveryState({
    required this.staleOwnerUserId,
    required this.personalUserId,
  });

  final String staleOwnerUserId;
  final String personalUserId;
}

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

@riverpod
class HouseholdDataOwnerRecovery extends _$HouseholdDataOwnerRecovery {
  @override
  HouseholdDataOwnerRecoveryState? build() {
    return null;
  }

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

  void clear() {
    state = null;
  }
}

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

@riverpod
bool householdHasAdditionalMembers(Ref ref) {
  final members = ref.watch(householdMembersProvider).asData?.value;
  return (members?.length ?? 0) > 1;
}
