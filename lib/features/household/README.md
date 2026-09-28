# Household Feature

## Purpose

Household owns the households that share a pantry: who is a member, who
leads, which household is active, and the household key that encrypts the
shared data.

## Owns

- `households/{householdId}` with its `members`, `keys`, and `key_restores`,
  the `household_invites`, and the `householdId` and `ownHouseholdId` fields
  of the user profile.
- The household key session, the cipher that household repositories watch,
  and the plaintext migration of household data.
- Wiping and deleting the data and images of a household.
- The household page: members, invites, joining, leaving, and unlocking the
  key after a fresh start.

## Does Not Own

- The household data itself (inventory, shopping list, prepared meals,
  recipes, kitchen utensils). Those features store it under
  `households/{householdId}`.
- The user data key and the fresh start. Auth sets the pending flag that the
  household key session cleans up after.
- Account deletion.

## Rules

- Every user always has an own household. Joining another one pauses it,
  leaving goes back to it. A user removed from the own household gets a new,
  empty one.
- A household has exactly one admin. Whoever becomes admin replaces the admin
  in the same write.
- The last member who leaves deletes the household.
- Switching the active household runs in a transaction, so the profile never
  names a household before the membership there exists.
