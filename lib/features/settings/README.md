# Settings Feature

Settings owns user preference and account surfaces. It composes finished
feature-owned controls for account, health, calories, appearance, and app
settings.

## Owns

- Settings and account pages at the feature root.
- Settings tiles, account cards, account dialogs, and snackbar helpers under
  `widgets/`.
- Account page flow and account controller state under `provider/`.

## Does Not Own

- Authentication infrastructure or Google sign-in controller behavior.
- Health Connect infrastructure, platform permissions, or health data.
- Calorie goal calculation, calorie state refresh, or calorie trend state.
- Home shell navigation state.

## Public Edge

- `settings_page.dart` is the main settings page.
- `account_page.dart` is the account management page.
- `widgets/settings_health_connect_tile.dart` is the settings-owned tile that
  delegates Health connection actions to the Health feature.
- Reusable settings tile components under `widgets/`.

Other features should compose the page or complete settings widgets instead of
wiring Settings provider internals directly.

## Providers

- `provider/` is legacy structure for the account controller and account page
  flow service.
- New Settings-owned providers should be placed next to their owner layer when
  possible instead of extending the legacy folder.
- Providers use Riverpod code generation.

Current providers:

- `provider/account_controller.dart`
- `provider/account_page_flow_service.dart`

## Accepted Dependencies

- `core` for routes, theme controllers, app version, shared layout, and common
  widgets.
- `features/auth` for account data, auth actions, and auth error mapping.
- `features/calories` for calorie goal settings surfaces.
- `features/health` for Health connection status, actions, and domain result
  models.
- `core/widgets` for optional shell chrome when Settings is embedded.
- `features/shared` for shared credential form widgets.

Keep cross-feature work at page, tile, or application action boundaries. Do not
make Settings own calorie or health business rules.

## Tests

- `test/features/settings/`
