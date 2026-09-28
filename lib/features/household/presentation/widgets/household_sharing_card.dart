import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/household/application/'
    'household_members_provider.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/domain/household_key_state.dart';
import 'package:yamt/features/household/domain/household_member.dart';
import 'package:yamt/features/household/presentation/controllers/'
    'household_membership_controller.dart';
import 'package:yamt/features/household/presentation/household_error_message.dart';
import 'package:yamt/features/household/presentation/household_membership_flow.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_invite_section.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_join_section.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_key_restore_section.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_members_section.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_unlock_code_section.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The household of the signed-in user: members, invites, joining and
/// leaving.
class HouseholdSharingCard extends ConsumerWidget {
  /// Creates the card.
  const new({required this.user, super.key});

  /// Key of the button that leaves the household.
  static const leaveKey = Key('household_leave_button');

  static const _logName = 'yamt.household';

  /// The signed-in user.
  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen(householdMembersProvider, (_, next) {
      if (next.hasError) {
        developer.log(
          'Failed to load the household members of ${user.uid}.',
          name: _logName,
          error: next.error,
          stackTrace: next.stackTrace,
        );
      }
    });

    return Card(
      child: Padding(
        padding: AppInsets.card,
        child: ref
            .watch(householdMembersProvider)
            .when(
              data: (members) =>
                  _HouseholdContent(user: user, members: members),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(householdErrorMessage(l10n, error)),
            ),
      ),
    );
  }
}

class _HouseholdContent extends ConsumerWidget {
  const new({required this.user, required this.members});

  final User user;
  final List<HouseholdMember> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final keyState = ref.watch(householdKeySessionProvider).value;
    final requesters =
        ref.watch(householdKeyRestoreRequestsProvider).value ??
        const <HouseholdMember>[];
    final isBusy = ref.watch(householdMembershipControllerProvider).isLoading;
    final isOwnHousehold =
        ref.watch(activeHouseholdIdProvider) ==
        ref.watch(ownHouseholdIdProvider);
    final isAdmin =
        members.firstWhereOrNull((member) => member.uid == user.uid)?.isAdmin ??
        false;
    final isAlone = members.length <= 1;
    final canJoin = isAlone && isOwnHousehold;

    final sections = <Widget>[
      if (keyState is HouseholdKeyRestoreRequired)
        HouseholdKeyRestoreSection(isBusy: isBusy),
      if (keyState is HouseholdKeyReady)
        for (final requester in requesters)
          HouseholdUnlockCodeSection(
            key: ValueKey<String>(requester.uid),
            member: requester,
            isBusy: isBusy,
          ),
      if (!isAlone)
        HouseholdMembersSection(
          members: members,
          currentUserId: user.uid,
          canManageMembers: isAdmin,
          isBusy: isBusy,
        ),
      if (isAdmin && user.isAnonymous)
        _HouseholdInfoBanner(message: l10n.householdHostVerificationHint)
      else if (isAdmin)
        HouseholdInviteSection(isBusy: isBusy),
      if (canJoin)
        HouseholdJoinSection(isBusy: isBusy)
      else
        OutlinedButton.icon(
          key: HouseholdSharingCard.leaveKey,
          onPressed: isBusy
              ? null
              : () => HouseholdMembershipFlow.leave(
                  context,
                  ref,
                  members: members,
                  currentUserId: user.uid,
                  isOwnHousehold: isOwnHousehold,
                ),
          icon: const Icon(Icons.logout),
          label: Text(l10n.householdLeaveAction),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, section) in sections.indexed) ...[
          if (index > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Divider(height: 1),
            ),
          section,
        ],
      ],
    );
  }
}

class _HouseholdInfoBanner extends StatelessWidget {
  const new({required this.message});

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
