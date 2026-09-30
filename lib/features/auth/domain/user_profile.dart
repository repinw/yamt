import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// Persisted account profile used for household membership and member lists.
@freezed
abstract class UserProfile with _$UserProfile {
  /// Creates persisted user profile model.
  ///
  /// [householdId] names the active household and [ownHouseholdId] the
  /// user's own household. Both are `null` only until the own household
  /// exists.
  const factory({
    required String uid,
    String? householdId,
    String? ownHouseholdId,
    String? email,
    String? displayName,
    @Default(false) bool isAnonymous,
  }) = _UserProfile;

  /// Decodes profile from JSON.
  factory fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
}
