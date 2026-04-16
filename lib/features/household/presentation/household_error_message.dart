import 'package:yamt/features/household/domain/household_sharing_exceptions.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Household error message.
String householdErrorMessage(AppLocalizations l10n, Object error) {
  return switch (error) {
    InvalidHouseholdInviteCodeException() => l10n.householdJoinInvalidCode,
    ExpiredHouseholdInviteCodeException() => l10n.householdJoinExpiredCode,
    OwnHouseholdInviteCodeException() => l10n.householdJoinOwnCode,
    HouseholdVerificationRequiredException() =>
      l10n.householdInviteVerificationRequired,
    HouseholdLeaderRequiredException() => l10n.householdLeaderOnly,
    HouseholdMemberRemovalDeniedException() => l10n.householdRemoveMemberFailed,
    _ => l10n.householdActionFailed,
  };
}
