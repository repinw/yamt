# Settings Feature

Settings owns user preference and account surfaces. It composes finished
feature-owned controls for account, health, calories, appearance, and app
settings.

## Owns

- Settings and account pages under `presentation/pages/`.
- Settings tiles, account cards, the profile summary card, and account
  dialogs under `presentation/widgets/<widget_name>/`.
- Account page flow and account controller state under `presentation/controllers/`.

## Does Not Own

- Authentication infrastructure or Google sign-in controller behavior.
- Health Connect infrastructure, platform permissions, or health data.
- Calorie goal calculation, calorie state refresh, or calorie trend state.
- Home shell navigation state.

## Public Edge

- `presentation/pages/settings_page.dart` is the main settings page. It is a
  pushed page with its own app bar, opened from the Home side menu at
  `AppRoutes.homeSettings`.
- `presentation/pages/account_page.dart` is the account management page.
- `presentation/widgets/settings_health_connect_tile/settings_health_connect_tile.dart` is the settings-owned tile that
  delegates Health connection actions to the Health feature.
- Reusable settings tile components under `presentation/widgets/settings_tiles/`.
- `presentation/widgets/settings_profile_summary_card/settings_profile_summary_card.dart`
  is the profile card of the Home side menu: optional name, height, sex,
  birthday with age, and the current goals (calories, target weight, goal
  mode, protein, carbs, fat). Its button opens the macro goals sheet. Body
  data and goals come from the calorie calculator profile; the macros come
  from the Calories nutrition target resolver, like the diary's.

Other features should compose the page or complete settings widgets instead of
wiring Settings provider internals directly.

## Providers

- Providers use Riverpod code generation.

Current providers:

- `data/secondary_auth_client.dart`
- `presentation/controllers/account_controller.dart`
- `presentation/controllers/account_page_flow_service.dart`

## Accepted Dependencies

- `core` for routes, theme controllers, app version, shared layout, and common
  widgets.
- `features/auth` for account data, auth actions, and auth error mapping.
- `features/calories` for the profile summary card's body data and goals
  (settings repository and nutrition target resolver), and calorie goal
  settings surfaces, including the complete goal archive page that the goal
  archive row opens through app routing (`AppRoutes.homeSettingsGoalArchive`).
- `features/health` for Health connection status, actions, and domain result
  models.
- `features/home_widget` for the home-screen widget's silent/verbose choice,
  rendered in the App section through its public
  `HomeWidgetVerboseModeBuilder`.
- `core/widgets` for shared layout helpers.
- `features/shared` for shared credential form widgets.

Keep cross-feature work at page, tile, or application action boundaries. Do not
make Settings own calorie or health business rules.

## Tests

- `test/features/settings/`
