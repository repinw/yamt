# Architecture Check

Use this checklist to review each feature against `architecture.md`.

For each feature, check:

- feature ownership is clear
- accepted cross-feature dependencies are small and explicit
- providers live beside their implementation owner
- widgets follow the feature-first folder structure
- public edge is intentional
- tests live with the owning feature
- no hand-written barrels or `part` files were added

## Feature Checklist

- [x] `activity`
- [x] `auth`
- [x] `calories`
- [ ] `cooking_flow`
- [ ] `diary`
- [ ] `health`
- [ ] `home`
- [ ] `household`
- [ ] `inventory`
- [ ] `kitchen_utensils`
- [ ] `meal_templates`
- [ ] `onboarding`
- [ ] `product_nutrition`
- [ ] `product_search`
- [ ] `recipes`
- [ ] `scanner`
- [ ] `settings`
- [ ] `shared`
- [ ] `shoppinglist`
- [ ] `statistics`

## Check Notes

### `activity`

- Result: pass.
- Feature README documents ownership, non-ownership, public edge, providers,
  dependencies, and tests.
- Code uses `application/`, `domain/`, and `presentation/` layers; no
  feature-level `provider/` folder.
- Riverpod providers use code generation and generated `part` files only.
- Other app code imports the complete diary activity/weight section, matching
  the public edge.
- Dependencies on `core`, `auth`, `calories`, and `health` match the feature
  README.
- Tests live under `test/features/activity/`.

### `auth`

- Result: pass after README dependency note update.
- Feature README documents ownership, non-ownership, public edge, providers,
  dependencies, tests, and migration notes.
- Code uses `application/`, `data/`, `domain/`, and `presentation/` layers; no
  legacy feature-level `provider/` or `widgets/` folders are present.
- Riverpod providers/controllers use code generation and generated `part`
  files only.
- No manual providers, `ViewModel` naming, hand-written barrels, or
  hand-written `part` files found.
- Public consumers import documented auth edges such as `auth_service.dart`,
  `user_profile.dart`, `google_auth_controller.dart`, auth pages, and error
  mapper.
- Auth imports `features/shared` for credential-form widgets; README now lists
  that accepted dependency.
- Tests live under `test/features/auth/`.

### `calories`

- Result: pass after architecture fixes.
- Feature README documents ownership, non-ownership, public edge, providers,
  dependencies, and tests.
- Production cross-feature dependencies are limited to documented `core`,
  `auth`, and `health` usage; no production `inventory` dependency found.
- Tests live under `test/features/calories/`.
- Legacy `provider/` folder is documented, which is acceptable as existing
  transition structure.
- Manual Riverpod providers were migrated to code-generated `@riverpod`
  providers:
  - `provider/calorie_page_action_controller.dart`
  - `provider/burn_week_run_controller.dart`
  - `debug/calorie_debug_action_controller.dart`
  - `application/burn_week_live_sync_provider.dart`
  - `provider/calorie_entry_post_persist_hook.dart`
  - `data/burn_week_run_state_repository.dart`
- Hand-written calculator `part` files were removed; the flow now uses real
  Dart declarations in `calorie_goal_calculator_flow.dart`.
- Meal type and l10n re-export shims were removed; consumers import the
  owning `core` files directly:
  - `domain/meal_type.dart`
  - `presentation/meal_type_l10n.dart`
- `calories_page_keys.dart` no longer re-exports calculator keys; consumers
  import `calorie_goal_calculator_keys.dart` directly.
- `flutter analyze` and full `test/features/calories` suite pass.
