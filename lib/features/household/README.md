# Household Feature

Household owns sharing membership, household data ownership, invite codes, and
the settings surface that lets a user join, leave, or manage a household.

## Owns

- Household invite generation, join, leave, and member removal workflows.
- Household-scoped data owner resolution.
- Household member stream aggregation and transient permission recovery.
- Household sharing page, sections, controllers, and error mapping.
- Household sharing exceptions.

## Does Not Own

- Authentication identity and profile storage. Household consumes Auth public
  providers for the current user and profile.
- Feature data stored under the household owner. Inventory, shopping list,
  kitchen utensils, and other features own their repositories.
- App routing outside exposing the household page as a settings destination.

## Public Edge

Other features may consume these public Household entry points:

- `presentation/household_page.dart`
- `application/household_scope_provider.dart`
- `application/household_members_provider.dart`
- `application/household_access_recovery_utils.dart`
- `application/household_permission_recovery.dart`
- `presentation/controllers/household_invite_code_controller.dart`
- `presentation/controllers/household_membership_controller.dart`
- `domain/household_sharing_exceptions.dart`

## Providers

- Repository providers live in `data/`.
- Household scope, member, and recovery providers live in `application/`.
- Household UI action controllers live in `presentation/controllers/`.
- `provider/` was removed from the tracked feature structure. Do not add new
  household provider files there.

## Accepted Dependencies

Household currently has explicit dependencies on:

- `core` for Firebase infrastructure.
- `auth` for current user identity and profile data.

Current accepted consumers include Inventory, Kitchen Utensils, Shopping List,
Meal Templates, Home tests, and Settings routing. Consumers should import the
public edge listed above instead of internal widgets or repository details.

## Tests

Household tests live under `test/features/household/`, with application tests
under `application/` and controller tests under `presentation/controllers/`.

## Migration Notes

- Legacy files from `provider/` were moved to `application/` or
  `presentation/controllers/` according to provider ownership.
- Generated `*.g.dart` files moved with their annotated provider files.
