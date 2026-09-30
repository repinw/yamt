import 'package:yamt/features/auth/domain/user_profile.dart';

/// Decodes Firestore user profile document into normalized model.
///
/// Temporary compatibility, added in 3.4.1: removed from 3.7.0 on, once every
/// stored profile holds `uid` and `isAnonymous` (the sign-in writes both).
UserProfile decodeUserProfileDocument(
  Map<String, dynamic> data,
  String documentId,
) {
  final normalizedData = Map<String, dynamic>.from(data);
  final uid =
      normalizeOptionalUserProfileValue(normalizedData['uid'] as String?) ??
      documentId;
  normalizedData['uid'] = uid;
  for (final field in <String>[
    'householdId',
    'ownHouseholdId',
    'email',
    'displayName',
  ]) {
    normalizedData[field] = normalizeOptionalUserProfileValue(
      normalizedData[field] as String?,
    );
  }
  return UserProfile.fromJson(normalizedData);
}

/// Trims empty optional profile strings down to `null`.
String? normalizeOptionalUserProfileValue(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}
