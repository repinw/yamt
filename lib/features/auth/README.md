# Auth Feature

## Ownership

Auth owns:

- Firebase authentication access and auth-state providers.
- Account sign-in, registration, guest sign-in, Google sign-in, and guest setup
  controllers.
- Persisted user profile model and Firestore profile document normalization.
- Auth entry pages and auth-specific presentation widgets.
- Local profile-setup completion status.

Auth does not own:

- Household membership workflows beyond exposing the current profile and profile
  document helpers.
- Settings account management UI beyond reusable auth controllers and error
  message mapping.
- App routing decisions.

## Public Edge

Other features may import these concrete files directly:

- `data/auth_service.dart` for `firebaseAuthProvider`,
  `authStateChangesProvider`, and `userProfileProvider`.
- `data/auth_repository.dart` for tests and auth-owned controller overrides.
- `data/user_profile_document_codec.dart` for features that read user profile
  documents from Firestore.
- `domain/user_profile.dart` for profile-aware UI and household member lists.
- `presentation/controllers/google_auth_controller.dart` for account-linking
  flows.
- `presentation/auth_error_message_mapper.dart` for auth error messages.
- `presentation/welcome_page.dart` and `presentation/guest_name_setup_page.dart`
  for app routing.

Widgets under `presentation/widgets/` are auth presentation internals unless a
test imports them directly.

## Providers

- `data/auth_service.dart`
  - `firebaseAuthProvider`
  - `authStateChangesProvider`
  - `userProfileProvider`
- `data/auth_repository.dart`
  - `authRepositoryProvider`
- `data/google_sign_in_provider.dart`
  - `googleSignInProvider`
- `application/auth_profile_setup_status_provider.dart`
  - `authProfileSetupCompletedProvider`
- `presentation/auth_error_message_mapper.dart`
  - `authErrorMessageMapperProvider`
- `presentation/controllers/auth_form_controller.dart`
  - `authFormControllerProvider`
- `presentation/controllers/guest_auth_controller.dart`
  - `guestAuthControllerProvider`
- `presentation/controllers/google_auth_controller.dart`
  - `googleAuthControllerProvider`
- `presentation/controllers/guest_name_setup_controller.dart`
  - `canCancelGuestSetupProvider`
  - `guestNameSetupControllerProvider`

## Accepted Dependencies

- `core` for Firebase infrastructure, preferences, app theme controllers, and
  reusable UI primitives.
- `settings` may use auth providers/controllers for account-linking actions.
- `household` may use `UserProfile`, profile decoding helpers, and auth state to
  scope household membership.
- `inventory`, `calories`, `shoppinglist`, `kitchen_utensils`, `activity`,
  `diary`, and `onboarding` may use auth state to scope user-owned data.

## Tests

Auth tests live under `test/features/auth/` with the same broad layer split as
the feature:

- `data/`
- `presentation/`
- `presentation/controllers/`
- `presentation/widgets/`

Shared credential-form widget tests live under `test/features/shared/widgets/`.

## Migration Notes

Auth was migrated from the legacy feature-level `provider/` and `widgets/`
folders into the architecture layers. Do not add new auth files to those legacy
folders.
