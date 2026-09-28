import 'package:cryptography/cryptography.dart';

/// State of the household key for the active household.
sealed class HouseholdKeyState {
  const new();
}

/// No data key yet, no user, no household yet, or Firestore is unavailable.
final class HouseholdKeyUnavailable extends HouseholdKeyState {
  /// Creates the state.
  const new();
}

/// The user started fresh and lost the key of [householdId]. Another member
/// must hand it back with an unlock code.
final class HouseholdKeyRestoreRequired extends HouseholdKeyState {
  /// Creates the state.
  const new({required this.householdId});

  /// The household whose key is missing.
  final String householdId;
}

/// The household key of [householdId] is available.
final class HouseholdKeyReady extends HouseholdKeyState {
  /// Creates the state.
  const new({required this.householdId, required this.key});

  /// The active household.
  final String householdId;

  /// The household key.
  final SecretKey key;
}
