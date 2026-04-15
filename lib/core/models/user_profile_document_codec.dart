import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/models/user_profile.dart';

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
