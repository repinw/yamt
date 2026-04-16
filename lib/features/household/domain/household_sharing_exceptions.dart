/// Thrown when a join code does not exist.
class InvalidHouseholdInviteCodeException implements Exception {
  /// The invalid household invite code exception.
  const InvalidHouseholdInviteCodeException();
}

/// Thrown when a join code is already expired.
class ExpiredHouseholdInviteCodeException implements Exception {
  /// The expired household invite code exception.
  const ExpiredHouseholdInviteCodeException();
}

/// Thrown when a user tries to join their own household.
class OwnHouseholdInviteCodeException implements Exception {
  /// The own household invite code exception.
  const OwnHouseholdInviteCodeException();
}

/// Thrown when a guest account tries to host a household.
class HouseholdVerificationRequiredException implements Exception {
  /// The household verification required exception.
  const HouseholdVerificationRequiredException();
}

/// Thrown when only the household leader may perform the requested action.
class HouseholdLeaderRequiredException implements Exception {
  /// The household leader required exception.
  const HouseholdLeaderRequiredException();
}

/// Thrown when the requested member removal is not allowed.
class HouseholdMemberRemovalDeniedException implements Exception {
  /// The household member removal denied exception.
  const HouseholdMemberRemovalDeniedException();
}

/// Thrown when no unique invite code could be generated.
class HouseholdInviteCodeGenerationFailedException implements Exception {
  /// The household invite code generation failed exception.
  const HouseholdInviteCodeGenerationFailedException();
}

/// Thrown when the user must leave the current household before joining.
class HouseholdLeaveRequiredException implements Exception {
  /// The household leave required exception.
  const HouseholdLeaveRequiredException();
}

/// Thrown when an operation requires an active guest household membership.
class HouseholdMembershipRequiredException implements Exception {
  /// The household membership required exception.
  const HouseholdMembershipRequiredException();
}
