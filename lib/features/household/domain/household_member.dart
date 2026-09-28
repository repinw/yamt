import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:yamt/core/domain/date_time_json_converter.dart';

part 'household_member.freezed.dart';
part 'household_member.g.dart';

/// Role of a member in a household.
enum HouseholdRole {
  /// Invites and removes members and hands the lead on. A household has
  /// exactly one admin.
  admin,

  /// Uses the shared data.
  member,
}

/// A member of a household.
///
/// The member document holds [uid], [role] and [joinedAt]. The name and the
/// e-mail address come from the user profile.
@freezed
abstract class HouseholdMember with _$HouseholdMember {
  /// Creates a member.
  const factory({
    required String uid,
    required HouseholdRole role,
    @JsonKey(name: 'joined_at')
    @DateTimeJsonConverter()
    required DateTime joinedAt,
    @JsonKey(includeFromJson: false, includeToJson: false) String? displayName,
    @JsonKey(includeFromJson: false, includeToJson: false) String? email,
  }) = _HouseholdMember;

  const new _();

  /// Reads a member document.
  factory fromJson(Map<String, dynamic> json) =>
      _$HouseholdMemberFromJson(json);

  /// Whether the member is the admin.
  bool get isAdmin => role == HouseholdRole.admin;
}

/// The member who takes over the lead when [leavingUid] leaves: the one who
/// joined first. `null` when nobody else is left.
HouseholdMember? proposeSuccessor(
  List<HouseholdMember> members,
  String leavingUid,
) {
  return members
      .where((member) => member.uid != leavingUid)
      .sortedBy((member) => member.joinedAt)
      .firstOrNull;
}
