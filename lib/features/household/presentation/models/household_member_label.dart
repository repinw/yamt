import 'package:yamt/features/household/domain/household_member.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The name under which [member] appears: the display name, else the e-mail
/// address.
String householdMemberLabel(HouseholdMember member, AppLocalizations l10n) {
  return member.displayName ?? member.email ?? l10n.householdMemberNoName;
}
