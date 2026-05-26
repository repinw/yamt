# Onboarding Feature

Onboarding owns the first-run calorie goal setup flow. It collects the data
needed to start calorie tracking, coordinates the one-time save workflow, and
records that the signed-in user completed onboarding.

Detailed flow documentation lives in `onboarding_description.md`.

## Owns

- Calorie goal onboarding completion state.
- One-time finish flow that saves the starting calorie goal.
- Same-day catch-up placeholder calculation and writing.
- Onboarding-specific start-date and tracking-mode domain types.
- Calorie onboarding page, wizard, steps, keys, and UI-only controllers.

## Does Not Own

- Reusable calorie goal settings, calculator models, or calorie log storage.
- Burn Week controller ownership.
- Auth identity, profile setup, or app routing infrastructure.
- Shared calorie goal editor widgets owned by Calories.

## Public Edge

Other features may consume these public Onboarding entry points:

- `presentation/calorie_goal_onboarding_page.dart`
- `presentation/calorie_goal_onboarding_keys.dart`
- `provider/calorie_goal_onboarding_completed_provider.dart`
- `domain/calorie_goal_onboarding_start.dart`
- `domain/calorie_goal_onboarding_preferences.dart`

## Providers

- Finish-flow providers live in `application/`.
- UI-only wizard controllers live under `presentation/widgets/onboarding/`.
- `provider/` is legacy and currently holds onboarding completion state used by
  the router. Move it in a follow-up cleanup when router ownership is revisited.

## Accepted Dependencies

Onboarding currently has explicit dependencies on:

- `core` for routing and preferences.
- `auth` for the current user ID used by completion markers.
- `calories` for calculator state, saved goal settings, calorie log
  persistence, and Burn Week setup.

## Tests

Onboarding tests live under `test/features/onboarding/`, matching application,
domain, presentation, and legacy provider ownership.

## Migration Notes

- `onboarding_description.md` remains the long-form flow reference.
- The remaining legacy `provider/` file is documented transition structure.
