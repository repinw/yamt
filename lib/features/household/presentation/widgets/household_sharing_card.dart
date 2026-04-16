import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/household/presentation/household_error_message.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_invite_section.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_join_section.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_members_section.dart';
import 'package:yamt/features/household/provider/'
    'household_members_provider.dart';
import 'package:yamt/features/household/provider/'
    'household_membership_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines household sharing card.
class HouseholdSharingCard extends ConsumerWidget {
  /// The household sharing card.
  const HouseholdSharingCard({super.key, required this.user});

  /// The user.
  final User user;
  static const _logName = 'yamt.household';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(userProfileProvider);
    final membersAsync = ref.watch(householdMembersProvider);
    final membershipState = ref.watch(householdMembershipControllerProvider);

    if (profileAsync.hasError || membersAsync.hasError) {
      final error = profileAsync.error ?? membersAsync.error;
      final stackTrace = profileAsync.stackTrace ?? membersAsync.stackTrace;
      _logLoadError(
        userId: user.uid,
        source: profileAsync.hasError ? 'profile' : 'members',
        error: error ?? StateError('unknown'),
        stackTrace: stackTrace,
      );
      return _HouseholdCardShell(
        title: l10n.householdTitle,
        child: _HouseholdLoadErrorView(
          message: householdErrorMessage(l10n, error ?? StateError('unknown')),
          error: error,
        ),
      );
    }

    if (profileAsync.isLoading || membersAsync.isLoading) {
      return _HouseholdCardShell(
        title: l10n.householdTitle,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final profile = profileAsync.asData?.value;
    final members = membersAsync.asData?.value ?? const [];
    final householdRootId = profile?.householdId ?? user.uid;
    final isGuestMember = profile?.householdId != null;
    final isLeader = !user.isAnonymous && !isGuestMember;
    final hasAdditionalMembers = members.length > 1;
    final isBusy = membershipState.isLoading;

    return _HouseholdCardShell(
      title: l10n.householdTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isGuestMember && !hasAdditionalMembers)
            HouseholdJoinSection(isBusy: isBusy),
          if (hasAdditionalMembers) ...[
            HouseholdMembersSection(
              members: members,
              currentUserId: user.uid,
              householdRootId: householdRootId,
              canRemoveMembers: isLeader,
              isBusy: isBusy,
            ),
          ],
          if (isLeader) ...[
            if (!isGuestMember && !hasAdditionalMembers)
              const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.lg),
            HouseholdInviteSection(isBusy: isBusy),
          ] else if (user.isAnonymous && !isGuestMember) ...[
            if (!isGuestMember && !hasAdditionalMembers)
              const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.lg),
            _HouseholdInfoBanner(message: l10n.householdHostVerificationHint),
          ],
          if (isGuestMember) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isBusy ? null : () => _confirmLeave(context, ref),
                icon: const Icon(Icons.logout),
                label: Text(l10n.householdLeaveAction),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _logLoadError({
    required String userId,
    required String source,
    required Object error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      'Failed to load household data from $source for user $userId.',
      name: _logName,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.householdLeaveTitle),
          content: Text(l10n.householdLeaveMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.householdLeaveAction),
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
          .leaveHousehold();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.householdLeaveSuccess)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(householdErrorMessage(l10n, error))),
      );
    }
  }
}

class _HouseholdLoadErrorView extends StatelessWidget {
  const _HouseholdLoadErrorView({required this.message, required this.error});

  final String message;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message),
        if (kDebugMode && error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          SelectableText(error.toString(), style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _HouseholdCardShell extends StatelessWidget {
  const _HouseholdCardShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.group_outlined),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class _HouseholdInfoBanner extends StatelessWidget {
  const _HouseholdInfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
