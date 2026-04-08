import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/models/user_profile.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

String? normalizeHouseholdScopeValue(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

String? householdRootIdForProfile(UserProfile? profile) {
  if (profile == null) {
    return null;
  }

  return normalizeHouseholdScopeValue(profile.householdId) ??
      normalizeHouseholdScopeValue(profile.uid);
}

bool shouldRecoverFromHouseholdPermissionDenied({
  required Object error,
  required bool isRecoveringHouseholdAccess,
  required String? currentUserId,
  required String? actualDataOwnerUserId,
  required String? effectiveDataOwnerUserId,
  required String? profileHouseholdId,
}) {
  if (isRecoveringHouseholdAccess ||
      error is! FirebaseException ||
      error.code != 'permission-denied') {
    return false;
  }

  final normalizedCurrentUserId = normalizeHouseholdScopeValue(currentUserId);
  final normalizedActualDataOwnerUserId = normalizeHouseholdScopeValue(
    actualDataOwnerUserId,
  );
  final normalizedEffectiveDataOwnerUserId = normalizeHouseholdScopeValue(
    effectiveDataOwnerUserId,
  );
  final normalizedProfileHouseholdId = normalizeHouseholdScopeValue(
    profileHouseholdId,
  );
  if (normalizedCurrentUserId == null) {
    return normalizedProfileHouseholdId != null;
  }

  return normalizedEffectiveDataOwnerUserId != normalizedCurrentUserId ||
      normalizedActualDataOwnerUserId != normalizedCurrentUserId ||
      normalizedProfileHouseholdId != null;
}

bool hasWatchedHouseholdRootChanged({
  required String watchedHouseholdRootId,
  required UserProfile? latestProfile,
}) {
  final normalizedWatchedHouseholdRootId = normalizeHouseholdScopeValue(
    watchedHouseholdRootId,
  );
  final latestHouseholdRootId = householdRootIdForProfile(latestProfile);
  return normalizedWatchedHouseholdRootId != null &&
      latestHouseholdRootId != null &&
      latestHouseholdRootId != normalizedWatchedHouseholdRootId;
}

String? signedInHouseholdRecoveryUserId(Ref ref) {
  return normalizeHouseholdScopeValue(
    ref.read(authStateChangesProvider).asData?.value?.uid,
  );
}
