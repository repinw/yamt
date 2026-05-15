import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/auth/domain/user_profile.dart';
import 'package:yamt/features/household/presentation/household_error_message.dart';
import 'package:yamt/features/household/provider/'
    'household_membership_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines household members section.
class HouseholdMembersSection extends ConsumerWidget {
  /// The household members section.
  const HouseholdMembersSection({
    required this.members,
    required this.currentUserId,
    required this.householdRootId,
    required this.canRemoveMembers,
    required this.isBusy,
    super.key,
  });

  /// The members.
  final List<UserProfile> members;

  /// The current user id.
  final String currentUserId;

  /// The household root id.
  final String householdRootId;

  /// Whether remove members.
  final bool canRemoveMembers;

  /// Whether busy.
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.householdMembersTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final member in members) ...[
          _MemberRow(
            member: member,
            currentUserId: currentUserId,
            householdRootId: householdRootId,
            canRemoveMembers: canRemoveMembers,
            isBusy: isBusy,
          ),
          if (member != members.last) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({
    required this.member,
    required this.currentUserId,
    required this.householdRootId,
    required this.canRemoveMembers,
    required this.isBusy,
  });

  final UserProfile member;
  final String currentUserId;
  final String householdRootId;
  final bool canRemoveMembers;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isCurrentUser = member.uid == currentUserId;
    final isLeader = member.uid == householdRootId;
    final displayName = member.displayName ?? member.email ?? member.uid;

    return Row(
      children: [
        CircleAvatar(child: Text(displayName.characters.first.toUpperCase())),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: theme.textTheme.bodyLarge),
              if (member.email != null && member.displayName != null)
                Text(member.email!, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        if (isLeader) _MemberChip(label: l10n.householdLeaderBadge),
        if (isLeader && isCurrentUser) const SizedBox(width: AppSpacing.xs),
        if (isCurrentUser) _MemberChip(label: l10n.householdYouBadge),
        if (canRemoveMembers && !isCurrentUser) ...[
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            onPressed: isBusy
                ? null
                : () => _confirmRemoval(context, ref, l10n, displayName),
            icon: const Icon(Icons.person_remove_outlined),
            tooltip: l10n.householdRemoveMemberAction,
          ),
        ],
      ],
    );
  }

  Future<void> _confirmRemoval(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String displayName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.householdRemoveMemberTitle),
          content: Text(l10n.householdRemoveMemberMessage(displayName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.householdRemoveMemberAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(householdMembershipControllerProvider.notifier)
          .removeMember(member.uid);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.householdRemoveMemberSuccess)),
      );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(householdErrorMessage(l10n, error))),
      );
    }
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(label),
      ),
    );
  }
}
