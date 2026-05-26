# Shared Feature

Shared owns small cross-feature UI pieces that are reusable but not general
enough for `core`.

## Owns

- Shared credential form widgets.
- Auth form component styling constants used by Auth presentation widgets.

## Does Not Own

- Authentication state, sign-in/register actions, or auth controllers.
- App-wide primitives that belong in `core`.
- Feature-specific pages or domain models.

## Public Edge

Other features may consume these public Shared entry points:

- `widgets/auth_form_components.dart`
- `widgets/email_password_credentials_form.dart`
- `widgets/credential_form_ui_constants.dart`

## Providers

Shared currently owns no Riverpod providers.

## Accepted Dependencies

Shared should stay dependency-light. It may depend on Flutter and app-wide
primitives from `core`, but should not depend on feature state or repositories.

Current accepted consumers:

- `auth` presentation widgets may use shared credential form components and
  constants.

## Tests

Shared widget tests live under `test/features/shared/widgets/`.
