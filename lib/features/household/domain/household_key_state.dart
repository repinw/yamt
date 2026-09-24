import 'package:cryptography/cryptography.dart';

/// State of the household key for the current household data owner.
sealed class HouseholdKeyState {
  const new();
}

/// No data key yet, no user, or Firestore is unavailable.
final class HouseholdKeyUnavailable extends HouseholdKeyState {
  /// Creates the state.
  const new();
}

/// The user is a member of [ownerUid]'s household but holds no key for it,
/// for example because the join stopped before the key entry was saved. The
/// user must join again with a QR code or link.
final class HouseholdKeyInviteRequired extends HouseholdKeyState {
  /// Creates the state.
  const new({required this.ownerUid});

  /// The household data owner.
  final String ownerUid;
}

/// The household key of [ownerUid] is available.
final class HouseholdKeyReady extends HouseholdKeyState {
  /// Creates the state.
  const new({required this.ownerUid, required this.key});

  /// The household data owner.
  final String ownerUid;

  /// The household key.
  final SecretKey key;
}
