import 'package:meta/meta.dart';

/// Role of a member in a household.
enum HouseholdRole {
  /// Invites and removes members and hands the lead on.
  admin,

  /// Uses the shared data.
  member,
}

/// A member of a household.
@immutable
class HouseholdMember {
  /// Creates a member.
  const new({
    required this.uid,
    required this.role,
    required this.joinedAt,
    this.displayName,
    this.email,
  });

  /// The user id.
  final String uid;

  /// The role in the household.
  final HouseholdRole role;

  /// When the user joined. The longest member takes over as admin.
  final DateTime joinedAt;

  /// The display name, if the user set one.
  final String? displayName;

  /// The e-mail address, if the account has one.
  final String? email;

  /// Whether the member is an admin.
  bool get isAdmin => role == HouseholdRole.admin;

  @override
  bool operator ==(Object other) =>
      other is HouseholdMember &&
      other.uid == uid &&
      other.role == role &&
      other.joinedAt == joinedAt &&
      other.displayName == displayName &&
      other.email == email;

  @override
  int get hashCode => Object.hash(uid, role, joinedAt, displayName, email);
}
