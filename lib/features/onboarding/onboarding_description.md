# Onboarding Feature

`lib/features/onboarding` owns the calorie-goal onboarding experience. It is the
first-run setup flow that collects the data needed for the calorie calculator,
saves the initial goal, starts or resets Burn Week, optionally creates same-day
catch-up placeholder entries, and records that the current user has completed
the flow.

The feature lives outside `lib/features/calories`, but it is tightly integrated
with the calorie engine. `lib/features/calories` still owns the reusable calorie
models, calculator form controller, goal controller, log repository, and Burn
Week state. Onboarding owns the one-time guided setup and the special logic
needed to enter an already-running day cleanly. Shared calorie-goal UI widgets
live in `lib/features/calorie_goal`.

## What It Does

- Shows a full-screen wizard for calorie goal setup.
- Collects sex, age, height, current weight, target weight, activity level,
  goal mode, and weekly pace through the calorie calculator form controller.
- Skips the pace step when the user wants to maintain weight.
- Lets the user decide whether the goal starts today or on a future date.
- For same-day starts, asks whether today's intake will be tracked exactly or
  estimated.
- For estimated same-day starts, lets the user choose a low, normal, or high
  catch-up estimate.
- Saves the calculated calorie goal through the calorie goal controller.
- Starts, resets, or bootstraps Burn Week based on the selected start date and
  whether learned TDEE already exists.
- Creates onboarding placeholder calorie entries when the user starts today and
  wants to estimate already-consumed calories.
- Marks calorie onboarding as completed in user-scoped app preferences.
- Automatically treats users with an existing saved calorie goal as completed,
  then backfills the completion marker.
- Drives router gating so authenticated users with completed profile setup are
  sent to calorie onboarding until this feature is complete.

## Folder Structure

`application/`

Coordinates the cross-feature finish action:

- `calorie_goal_onboarding_finish_flow.dart`: Saves the calculated goal, applies
  the selected goal start date, and coordinates Burn Week
  start/reset/bootstrap.
- `calorie_goal_onboarding_catch_up_placeholder_writer.dart`: Writes placeholder
  entries for estimated same-day starts.

`domain/`

Contains pure onboarding-specific logic:

- `calorie_goal_onboarding_preferences.dart`: Defines the per-user completion
  preference key and marker value.
- `calorie_goal_onboarding_start.dart`: Defines same-day catch-up estimate
  options and today's tracking modes.
- `onboarding_catch_up_calculator.dart`: Estimates how many calories should
  already have been consumed based on time of day, daily goal, and low/normal/high
  user selection. It also distributes catch-up calories across meals and assigns
  natural meal midpoint times for placeholder entries.

`provider/`

Connects router state, auth state, preferences, and existing calorie settings:

- `calorie_goal_onboarding_completed_provider.dart`: Returns whether the
  current user has completed calorie onboarding. It first checks the
  user-scoped preference marker, then falls back to saved calorie settings. If a
  saved goal already exists, it writes the marker and returns completed.
- `markCalorieGoalOnboardingCompleted`: Marks onboarding complete from provider
  logic.
- `markCalorieGoalOnboardingCompletedFromContainer`: Marks onboarding complete
  from widget/router contexts where a `ProviderContainer` is available.

`presentation/`

Contains the page, wizard, and step widgets:

- `calorie_goal_onboarding_page.dart`: Loads existing calorie settings and
  starts the wizard with either those settings or empty defaults.
- `widgets/onboarding/calorie_onboarding_wizard.dart`: Owns step state,
  validation, PageView navigation, saving state, and route exit protection.
- `widgets/onboarding/calorie_onboarding_wizard_controller.dart`: Tracks wizard
  page index, validation-error visibility, saving state, and route-exit flags.
- `widgets/onboarding/calorie_onboarding_start_date_controller.dart`: Tracks
  start-now/future-date choices and resolves save parameters for the selected
  start-date mode.
- `widgets/onboarding/calorie_onboarding_step_pages.dart`: Builds the
  non-scrollable onboarding `PageView` and wires each step widget.
- `widgets/onboarding/calorie_onboarding_wizard_chrome.dart`: Renders the
  progress, back, and next controls shown around the middle wizard steps.
- `widgets/onboarding/calorie_onboarding_finish_handler.dart`: Builds the finish
  request, shows localized save failures, marks onboarding complete, and exits
  the setup route.
- `steps/step_0_welcome.dart`: Intro screen.
- `steps/step_1_personal_info.dart`: Sex, age, and height.
- `steps/step_2_activity.dart`: Activity level.
- `steps/step_3_goal_weight.dart`: Current and target weight.
- `steps/step_4_pace.dart`: Weekly goal pace plus warnings for aggressive
  gain/loss rates.
- `steps/step_5_info.dart`: Explains the learning week and tracking tools.
- `steps/step_6_start_date.dart`: Start today/future date, exact/estimated
  today tracking, and catch-up estimate choices.
- `steps/step_7_ready.dart`: Final calculated-goal summary and finish action.
- Shared step widgets provide labeled inputs, selectable cards, and common
  scrollable step layout.

`*.g.dart`

Generated Riverpod files. They should not be edited manually.

## Important Data Flows

### Router Gating

1. `appRouterProvider` watches auth, profile setup completion, and
   `calorieGoalOnboardingCompletedProvider`.
2. Unauthenticated users go to welcome.
3. Authenticated users without profile setup go to guest name setup.
4. Authenticated users with profile setup but without calorie onboarding go to
   `AppRoutes.calorieGoalSetup`.
5. While onboarding completion is loading, startup/setup routes stay blocked on
   splash to avoid route flicker.
6. Once onboarding is complete, visiting calorie setup redirects to the diary
   home route.

### Completing Existing Users

1. `calorieGoalOnboardingCompletedProvider` reads the current auth user.
2. It checks `calorie_goal_onboarding_completed:{userId}` in app preferences.
3. If no marker exists, it reads calorie settings.
4. If settings already contain a goal, the provider writes the marker and
   returns completed.
5. If there is no marker and no goal, router sends the user to onboarding.

### Wizard Navigation

1. `CalorieGoalOnboardingPage` loads `CalorieGoalSettings`.
2. `CalorieOnboardingWizard` creates a calculator form provider from the saved
   calculator profile, using empty onboarding defaults where needed.
3. Steps are shown through a non-scrollable `PageView`; only the wizard buttons
   move forward/backward.
4. Personal info and goal weight steps block progress until required form fields
   are valid.
5. Maintain-weight users skip the pace step.
6. Start-date progress is blocked until the user chooses today/future date and,
   for today, exact or estimated tracking.

### Saving The Goal

1. The ready step calls the wizard finish callback.
2. `CalorieOnboardingFinishHandler` reads the calculated profile and final
   daily kcal goal.
3. `CalorieGoalOnboardingFinishFlow.saveGoal` receives a
   `CalorieGoalOnboardingFinishRequest` and applies Burn Week setup before
   saving the calculated goal.
4. The goal controller saves the calculated goal with the selected start date and
   optional `countGoalStartDayForLearning` flag.
5. On success, onboarding writes the completion marker.
6. The wizard allows route exit and returns to the previous route or diary home.
7. On failure, saving state is reset and a localized failure snackbar is shown.

### Starting Today With Exact Tracking

1. The user chooses "start today".
2. The user chooses exact tracking.
3. The goal start date is today.
4. `countGoalStartDayForLearning` is saved as `true`.
5. No catch-up placeholder entries are created.
6. Burn Week starts from today.

### Starting Today With Estimated Tracking

1. The user chooses "start today".
2. The user chooses estimated tracking and selects low, normal, or high.
3. The finish flow reads calorie entries already logged today.
4. `calculateOnboardingCatchUpKcal` estimates how many kcal should exist by the
   current time of day.
5. Already logged kcal are subtracted from the desired catch-up total.
6. If at least 100 kcal remain, the placeholder writer creates entries across
   breakfast, lunch, snack, and dinner according to the current time.
7. The goal start day is excluded from learning by saving
   `countGoalStartDayForLearning` as `false`.
8. Burn Week is bootstrapped from today.

### Starting Later

1. The user chooses a future date.
2. Date picking is constrained from tomorrow to ten years ahead.
3. If the user already has learned TDEE, Burn Week is restarted from the future
   date.
4. Otherwise Burn Week is reset until the goal starts.
5. The calculated goal is saved with `allowFutureGoalStart: true`.

## Integrations

- `core/router`: Redirects users into or out of onboarding based on completion
  state.
- `features/auth`: Supplies the current user ID for completion markers.
- `core/preferences`: Stores the user-scoped onboarding completion marker.
- `features/calorie_goal`: Provides shared goal picker, result, warning, and
  goal-start card widgets.
- `lib/features/calories`: Provides the calculator form controller, goal
  settings, goal controller, calorie log repository, calorie entries, diary day
  helpers, and Burn Week controllers.
- `l10n`: Supplies all user-facing copy in the wizard.

## Persistence Model

- Completion marker:
  `calorie_goal_onboarding_completed:{userId}` in app preferences, value `1`.
- Calculated goal:
  saved through `CalorieGoalController` into calorie goal settings.
- Placeholder entries:
  saved as calorie entries through `CalorieLogRepository`, marked as onboarding
  placeholders.
- Burn Week:
  started, reset, restarted, or bootstrapped through `BurnWeekRunController`.

## Tests

`test/features/onboarding` mirrors the feature structure:

- `application/` tests finish-flow behavior, Burn Week setup, goal saving,
  future starts, exact same-day starts, estimated catch-up starts, and
  placeholder entry creation.
- `domain/` tests preference keys and catch-up calculation/distribution logic.
- `provider/` tests completion detection, existing-goal backfill, missing-goal
  behavior, and marker writing.
- `presentation/widgets/` tests the full wizard save flows plus individual step
  rendering, validation, selection, warnings, and finish states.

Router tests in `test/core/router/app_router_test.dart` cover the route-level
onboarding redirects and the transition from setup to diary home after
completion.
