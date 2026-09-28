/// A household action failed in a way the user can act on.
sealed class HouseholdException implements Exception {
  const new();
}

/// Thrown when an invite does not exist or its secret does not open it.
final class InvalidHouseholdInviteCodeException extends HouseholdException {
  /// Creates the exception.
  const new();
}

/// Thrown when an invite is already expired.
final class ExpiredHouseholdInviteCodeException extends HouseholdException {
  /// Creates the exception.
  const new();
}

/// Thrown when the user is already in the household of an invite.
final class OwnHouseholdInviteCodeException extends HouseholdException {
  /// Creates the exception.
  const new();
}

/// Thrown when a guest account tries to invite people.
final class HouseholdVerificationRequiredException extends HouseholdException {
  /// Creates the exception.
  const new();
}

/// Thrown when only the admin may perform the requested action.
final class HouseholdAdminRequiredException extends HouseholdException {
  /// Creates the exception.
  const new();
}

/// Thrown when the requested member is not in the household.
final class HouseholdMemberNotFoundException extends HouseholdException {
  /// Creates the exception.
  const new();
}

/// Thrown when the user must leave the shared household before joining
/// another one.
final class HouseholdLeaveRequiredException extends HouseholdException {
  /// Creates the exception.
  const new();
}

/// Thrown when the household key is not ready yet, for example while the
/// user's data key is still loading.
final class HouseholdKeyUnavailableException extends HouseholdException {
  /// Creates the exception.
  const new();
}

/// Thrown when an unlock code does not open the household key that a member
/// left, or no member left one yet.
final class InvalidHouseholdRestoreCodeException extends HouseholdException {
  /// Creates the exception.
  const new();
}
