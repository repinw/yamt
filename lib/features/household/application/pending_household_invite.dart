import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/household/domain/household_invite.dart';

part 'pending_household_invite.g.dart';

/// An invite link that opened the app and waits for the join form.
@Riverpod(keepAlive: true)
class PendingHouseholdInvite extends _$PendingHouseholdInvite {
  @override
  HouseholdInvite? build() => null;

  /// The waiting invite.
  HouseholdInvite? get invite => state;

  /// Keeps [value] until the join form takes it.
  set invite(HouseholdInvite? value) => state = value;

  /// Returns the waiting invite and forgets it.
  HouseholdInvite? take() {
    final invite = state;
    state = null;
    return invite;
  }
}
