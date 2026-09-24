import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/features/auth/domain/user_profile.dart';

/// Decodes Firestore user profile document into normalized model.
UserProfile decodeUserProfileDocument(
  Map<String, dynamic> data,
  String documentId,
) {
  final normalizedData = Map<String, dynamic>.from(data);
  final uid =
      normalizeOptionalUserProfileValue(normalizedData['uid'] as String?) ??
      documentId;
  normalizedData['uid'] = uid;
  normalizedData['householdId'] = normalizeOptionalUserProfileValue(
    normalizedData['householdId'] as String?,
  );
  normalizedData['email'] = normalizeOptionalUserProfileValue(
    normalizedData['email'] as String?,
  );
  normalizedData['displayName'] = normalizeOptionalUserProfileValue(
    normalizedData['displayName'] as String?,
  );
  return UserProfile.fromJson(normalizedData);
}

/// Reads normalized household id from user profile snapshot.
String? householdIdFromUserProfileSnapshot(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
) {
  return normalizeOptionalUserProfileValue(
    snapshot.data()?['householdId'] as String?,
  );
}

/// Returns [profile] with the household id of [lastCommittedProfile] while
/// the snapshot has writes that the server has not committed yet.
///
/// Joining a household writes the householdId to the local cache first.
/// Firestore rules read the committed value, so household data keeps its
/// current owner until the server commits the join.
UserProfile withCommittedHouseholdId(
  UserProfile profile, {
  required bool hasPendingWrites,
  required UserProfile? lastCommittedProfile,
}) {
  if (!hasPendingWrites || lastCommittedProfile == null) {
    return profile;
  }
  return profile.copyWith(householdId: lastCommittedProfile.householdId);
}

/// Trims empty optional profile strings down to `null`.
String? normalizeOptionalUserProfileValue(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

/// Returns whether profile represents standalone guest without household.
bool isStandaloneGuestUserProfile(UserProfile profile) {
  return profile.isAnonymous &&
      normalizeOptionalUserProfileValue(profile.householdId) == null;
}
