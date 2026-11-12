import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/household/domain/household_invite.dart';

part 'pending_household_invite.g.dart';

/// An invite link that opened the app and waits for the join form.
@Riverpod(keepAlive: true)
class PendingHouseholdInvite extends _$PendingHouseholdInvite {
  @override
  HouseholdInvite? build() => null;

  /// Keeps [invite] until the join form takes it.
  void hold(HouseholdInvite invite) {
    if (state == invite) return;
    state = invite;
  }

  /// Returns the waiting invite and forgets it.
  HouseholdInvite? take() {
    final invite = state;
    state = null;
    return invite;
  }
}
