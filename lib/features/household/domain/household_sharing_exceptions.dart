/// Thrown when a join code does not exist.
class InvalidHouseholdInviteCodeException implements Exception {
  const InvalidHouseholdInviteCodeException();
}

/// Thrown when a join code is already expired.
class ExpiredHouseholdInviteCodeException implements Exception {
  const ExpiredHouseholdInviteCodeException();
}

/// Thrown when a user tries to join their own household.
class OwnHouseholdInviteCodeException implements Exception {
  const OwnHouseholdInviteCodeException();
}

/// Thrown when a guest account tries to host a household.
class HouseholdVerificationRequiredException implements Exception {
  const HouseholdVerificationRequiredException();
}

/// Thrown when only the household leader may perform the requested action.
class HouseholdLeaderRequiredException implements Exception {
  const HouseholdLeaderRequiredException();
}

/// Thrown when the requested member removal is not allowed.
class HouseholdMemberRemovalDeniedException implements Exception {
  const HouseholdMemberRemovalDeniedException();
}

/// Thrown when no unique invite code could be generated.
class HouseholdInviteCodeGenerationFailedException implements Exception {
  const HouseholdInviteCodeGenerationFailedException();
}
