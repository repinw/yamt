import 'package:yamt/features/household/domain/household_exceptions.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The message for a failed household action.
String householdErrorMessage(AppLocalizations l10n, Object error) {
  if (error is! HouseholdException) {
    return l10n.householdActionFailed;
  }
  return switch (error) {
    InvalidHouseholdInviteCodeException() => l10n.householdJoinInvalidCode,
    ExpiredHouseholdInviteCodeException() => l10n.householdJoinExpiredCode,
    OwnHouseholdInviteCodeException() => l10n.householdJoinOwnCode,
    HouseholdVerificationRequiredException() =>
      l10n.householdInviteVerificationRequired,
    HouseholdAdminRequiredException() => l10n.householdAdminOnly,
    HouseholdMemberNotFoundException() => l10n.householdMemberNotFound,
    HouseholdLeaveRequiredException() => l10n.householdJoinLeaveFirst,
    HouseholdChangedException() => l10n.householdChanged,
    HouseholdKeyUnavailableException() => l10n.householdKeyUnavailable,
    InvalidHouseholdRestoreCodeException() =>
      l10n.householdKeyRestoreInvalidCode,
  };
}
