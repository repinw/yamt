import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// Persisted account profile used for household membership and member lists.
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String uid,
    String? householdId,
    String? email,
    String? displayName,
    @Default(false) bool isAnonymous,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
