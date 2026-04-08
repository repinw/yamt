import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/models/user_profile.dart';

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

String? householdIdFromUserProfileSnapshot(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
) {
  return normalizeOptionalUserProfileValue(
    snapshot.data()?['householdId'] as String?,
  );
}

String? normalizeOptionalUserProfileValue(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

bool isStandaloneGuestUserProfile(UserProfile profile) {
  return profile.isAnonymous &&
      normalizeOptionalUserProfileValue(profile.householdId) == null;
}
