import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/household/domain/household_member.dart';
import 'package:yamt/features/household/presentation/controllers/'
    'household_membership_controller.dart';
import 'package:yamt/features/household/presentation/household_error_message.dart';
import 'package:yamt/features/household/presentation/models/household_member_label.dart';
import 'package:yamt/features/household/presentation/widgets/household_confirm_dialog.dart';
import 'package:yamt/features/household/presentation/widgets/household_leave_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Confirms a membership change, runs it and reports the result.
abstract final class HouseholdMembershipFlow {
  const new _();

  /// Hands the lead of the household to [member].
  static Future<void> makeAdmin(
    BuildContext context,
    WidgetRef ref,
    HouseholdMember member,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final name = householdMemberLabel(member, l10n);
    final confirmed = await showHouseholdConfirmDialog(
      context,
      title: l10n.householdMakeAdminTitle(name),
      message: l10n.householdMakeAdminMessage(name),
      action: l10n.householdMakeAdminAction,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    await _run(
      context,
      () => ref
          .read(householdMembershipControllerProvider.notifier)
          .makeAdmin(member.uid),
      success: l10n.householdMakeAdminSuccess(name),
    );
  }

  /// Removes [member] from the household.
  static Future<void> removeMember(
    BuildContext context,
    WidgetRef ref,
    HouseholdMember member,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final name = householdMemberLabel(member, l10n);
    final confirmed = await showHouseholdConfirmDialog(
      context,
      title: l10n.householdRemoveMemberTitle,
      message: l10n.householdRemoveMemberMessage(name),
      action: l10n.householdRemoveMemberAction,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    await _run(
      context,
      () => ref
          .read(householdMembershipControllerProvider.notifier)
          .removeMember(member.uid),
      success: l10n.householdRemoveMemberSuccess,
    );
  }

  /// Leaves the active household. An admin picks who leads after them.
  static Future<void> leave(
    BuildContext context,
    WidgetRef ref, {
    required List<HouseholdMember> members,
    required String currentUserId,
    required bool isOwnHousehold,
  }) async {
    final choice = await showHouseholdLeaveDialog(
      context,
      members: members,
      currentUserId: currentUserId,
      isOwnHousehold: isOwnHousehold,
    );
    if (choice == null || !context.mounted) {
      return;
    }
    await _run(
      context,
      () => ref
          .read(householdMembershipControllerProvider.notifier)
          .leaveHousehold(successorUid: choice.successorUid),
      success: AppLocalizations.of(context)!.householdLeaveSuccess,
    );
  }

  static Future<void> _run(
    BuildContext context,
    Future<void> Function() action, {
    required String success,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await action();
      messenger.showAppSnackBar(success);
    } on Object catch (error) {
      messenger.showAppSnackBar(
        householdErrorMessage(l10n, error),
        tone: AppSnackBarTone.error,
      );
    }
  }
}
