# Calories Feature

Calories owns calorie logging, goal settings, Burn Week state, weekly check-in
state, calorie health trends, and calorie-owned side effects from health or
weight changes.

## Owns

- Calorie repositories and commit stores under `data/`.
- Calorie entries, goals, calculator inputs, weekly check-in, Burn Week, and
  trend domain models under `domain/`.
- Calorie use-case providers and cross-feature action wrappers under
  `application/`.
- Calorie pages, dialogs, sheets, and section widgets under `presentation/`.
- Legacy calorie controllers and derived providers under `provider/`.

## Does Not Own

- Health Connect infrastructure, permission state, or raw health services.
- Diary page ordering, date navigation, or diary-level composition.
- Activity card layout or activity-owned action orchestration.
- Inventory item storage, prepared meal storage, or household scope state.

## Public Edge

- `application/calorie_health_connection_actions.dart` wraps Health connection
  actions with calorie-owned side effects.
- `application/calorie_weight_state_refresh.dart` refreshes calorie state after
  health weight changes.
- Legacy controllers and derived providers under `provider/` are current public
  edge for existing Diary, Activity, Settings, Home, Onboarding, Statistics,
  and Inventory integrations.
- Domain models under `domain/` used by Diary, Activity, and Settings.
- Complete presentation surfaces such as calorie entry editors, goal dialogs,
  calculator sheets, health trend widgets, and diary health card parts.

Other features should depend on these public actions, domain types, or complete
widgets instead of reassembling Calories internals. New cross-feature behavior
should prefer `application/` providers or complete widgets over expanding the
legacy `provider/` surface.

## Providers

- New use-case providers live in `application/`.
- Repository providers live with repository implementations in `data/`.
- The feature-level `provider/` folder is legacy structure and currently holds
  calorie controllers and derived state. Do not add new provider files there
  unless working inside existing legacy code where moving would create
  unrelated churn.
- Providers use Riverpod code generation.

Main application providers:

- `application/calorie_health_connection_actions.dart`
- `application/calorie_weight_state_refresh.dart`
- `application/calorie_entry_delete_flow.dart`
- `application/inventory_backed_calorie_entry_save_flow.dart`

## Accepted Dependencies

- `core` for routing, theme tokens, shared widgets, and local day helpers.
- `features/auth` for user-scoped calorie repositories and cache storage.
- `features/health` for public health controllers, services, and domain data
  used by calorie goals, trends, and connection actions.
- `features/inventory` for inventory-backed calorie entry save/delete flows.
- `features/household` for household-scoped inventory commit storage.
- `features/calorie_goal` for shared calorie goal picker/result widgets.

Keep health-triggered calorie effects in Calories application providers. Health
must not depend on Calories.

## Tests

- `test/features/calories/application/`
- `test/features/calories/data/`
- `test/features/calories/domain/`
- `test/features/calories/presentation/`
- `test/features/calories/provider/`
