import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/household/domain/household_member.dart';
import 'package:yamt/features/household/presentation/household_membership_flow.dart';
import 'package:yamt/features/household/presentation/models/household_member_label.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The members of the household. The admin may hand on the lead or remove a
/// member.
class HouseholdMembersSection extends StatelessWidget {
  /// Creates the section.
  const new({
    required this.members,
    required this.currentUserId,
    required this.canManageMembers,
    required this.isBusy,
    super.key,
  });

  /// Key of the admin badge.
  static const adminBadgeKey = Key('household_member_admin_badge');

  /// Key of the menu item that hands the lead on.
  static const makeAdminKey = Key('household_member_make_admin');

  /// Key of the menu item that removes a member.
  static const removeKey = Key('household_member_remove');

  /// Key of the action menu of the member [uid].
  static Key menuKey(String uid) =>
      ValueKey<String>('household_member_menu_$uid');

  /// The members, the admin first.
  final List<HouseholdMember> members;

  /// The signed-in user.
  final String currentUserId;

  /// Whether the user is the admin.
  final bool canManageMembers;

  /// Whether a household action runs.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final member in members)
          _MemberRow(
            key: ValueKey<String>(member.uid),
            member: member,
            isCurrentUser: member.uid == currentUserId,
            canManage: canManageMembers && member.uid != currentUserId,
            isBusy: isBusy,
          ),
      ],
    );
  }
}

enum _MemberAction { makeAdmin, remove }

class _MemberRow extends ConsumerWidget {
  const new({
    required this.member,
    required this.isCurrentUser,
    required this.canManage,
    required this.isBusy,
    super.key,
  });

  final HouseholdMember member;
  final bool isCurrentUser;
  final bool canManage;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final name = householdMemberLabel(member, l10n);
    final email = member.email;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(name.characters.first.toUpperCase())),
      title: Text(isCurrentUser ? l10n.householdMemberSelf(name) : name),
      subtitle: email != null && member.displayName != null
          ? Text(email)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (member.isAdmin)
            Tooltip(
              message: l10n.householdAdminBadge,
              child: Icon(
                Icons.shield_outlined,
                key: HouseholdMembersSection.adminBadgeKey,
                semanticLabel: l10n.householdAdminBadge,
              ),
            ),
          if (canManage)
            PopupMenuButton<_MemberAction>(
              key: HouseholdMembersSection.menuKey(member.uid),
              enabled: !isBusy,
              tooltip: l10n.householdMemberActions,
              onSelected: (action) => unawaited(switch (action) {
                _MemberAction.makeAdmin => HouseholdMembershipFlow.makeAdmin(
                  context,
                  ref,
                  member,
                ),
                _MemberAction.remove => HouseholdMembershipFlow.removeMember(
                  context,
                  ref,
                  member,
                ),
              }),
              itemBuilder: (_) => [
                PopupMenuItem(
                  key: HouseholdMembersSection.makeAdminKey,
                  value: _MemberAction.makeAdmin,
                  child: Text(l10n.householdMakeAdminAction),
                ),
                PopupMenuItem(
                  key: HouseholdMembersSection.removeKey,
                  value: _MemberAction.remove,
                  child: Text(l10n.householdRemoveMemberAction),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
