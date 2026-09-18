# Onboarding Feature

`lib/features/onboarding` owns the calorie-goal onboarding experience. It is the
first-run flow that explains how the app derives a calorie target, collects the
data the calorie calculator needs, saves the initial goal, bootstraps Burn Week,
and records that the current user has completed the flow.

The feature lives outside `lib/features/calories`, but it is tightly integrated
with the calorie engine. `lib/features/calories` still owns the reusable calorie
models, calculator form controller, goal controller, log repository, and Burn
Week state. Onboarding owns the one-time guided setup. Shared calorie-goal UI
widgets live in `lib/features/calories`.

## Owns

- Shows one full-screen `IntroductionScreen` with fourteen pages: a welcome page,
  six explaining pages, six input pages, and a summary page.
- Offers **Get started** and **I already have an account** on the welcome page.
  The login action pushes `/welcome?from=onboarding` so an existing user can sign
  in without leaving onboarding.
- Explains the model in one idea per page: calories in against calories out, that
  the first number is an estimate from the entered details, that it is corrected
  every week against the real weight, that the goal then subtracts or adds
  calories, that the progress view shows the real trend, and what the rest of the
  kitchen features do.
- Collects gender and birthday, height and current weight, target weight, daily
  activity level, training schedule, and weekly pace through the calorie
  calculator form controller.
- Uses vertical scroll wheels instead of keyboards: day, month, and year for the
  birthday, and one wheel each for height, weight, target weight, and pace.
  Weight moves in steps of 0.1 kg, pace in steps of 0.05 kg per week.
- Asks about everyday movement only, in four steps from mostly sitting to
  physically hard work. Training days are a page of their own.
- Derives the goal mode from target weight against current weight, and skips the
  pace page when the user wants to maintain weight.
- Estimates the day the target weight is reached and shows it on the pace page.
- Warns about an ambitious pace and about a goal clamped to the minimum.
- Ends on a summary with two numbers: the calculated daily expenditure and the
  daily intake target, with the difference between them explained.
- Saves the calculated calorie goal through the calorie goal controller, always
  starting today.
- Bootstraps Burn Week from today.
- Marks calorie onboarding as completed in user-scoped app preferences.
- Automatically treats users with an existing saved calorie goal as completed,
  then backfills the completion marker.
- Drives router gating so authenticated users with completed profile setup are
  sent to calorie onboarding until this feature is complete.

## Does Not Own

- The calorie calculator itself, the goal controller, Burn Week state, or the
  calorie log. Those stay in `lib/features/calories`.
- Authentication and the guest account. Onboarding only links to `/welcome`.
- Any calorie goal change after the first one. Later edits happen in the calorie
  settings and the weekly check-in.

## Public Edge

- `presentation/calorie_goal_onboarding_page.dart`, mounted by
  `lib/core/router` at `AppRoutes.calorieGoalSetup`.
- `provider/calorie_goal_onboarding_completed_provider.dart` with
  `calorieGoalOnboardingCompletedProvider`,
  `markCalorieGoalOnboardingCompleted`, and
  `markCalorieGoalOnboardingCompletedFromContainer`, used by the router gate.
- `domain/calorie_goal_onboarding_preferences.dart` for the completion marker
  key, used by test helpers and the router tests.

Everything under `presentation/widgets/` and `presentation/controllers/` is
internal. No other feature assembles the intro pages.

## Providers

- `calorieGoalOnboardingCompletedProvider` (`keepAlive`): whether the current
  user finished onboarding.
- `calorieGoalOnboardingFinishFlowProvider`: the finish workflow.
- `calorieIntroControllerProvider` (auto-dispose): page index, validation-error
  visibility, saving state, and route-exit flag.

## Folder Structure

`application/`

Coordinates the cross-feature finish action:

- `calorie_goal_onboarding_finish_flow.dart`: Saves the calculated goal with
  today as the start date and bootstraps Burn Week.

`domain/`

Contains pure onboarding-specific logic:

- `calorie_goal_onboarding_preferences.dart`: Defines the per-user completion
  preference key and marker value.
- `goal_target_date_estimator.dart`: Estimates the day the target weight is
  reached from the current weight, the target weight, and the weekly pace.
- `intro_activity_option.dart`: The four everyday-activity levels onboarding
  offers and the calculator level each maps to. The calculator's extreme level
  is not offered here; it stays reachable from the calorie settings, and an
  existing extreme profile shows the closest offered level.

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

Contains the page, the intro flow, and its pages:

- `calorie_goal_onboarding_page.dart`: Loads existing calorie settings and
  starts the intro with either those settings or empty defaults.
- `calorie_goal_onboarding_keys.dart`: Stable widget keys used by tests.
- `controllers/calorie_intro_controller.dart`: Moves between pages, applies the
  per-page "can continue" rules and the maintain-mode pace skip, and tracks
  saving and route-exit flags.
- `models/`: UI models without widgets. `calorie_intro_page.dart` (page order,
  chapter numbers), `calorie_intro_state.dart` (controller state),
  `intro_chapter_accent.dart` (accent per chapter and its counterpart),
  `intro_input_page_args.dart` (what every input page shares), and
  `intro_weight_range.dart` (bounds and step of the weight wheels).
- `widgets/intro/calorie_intro_flow.dart`: Hosts `IntroductionScreen` over the
  animated backdrop, owns navigation, the rising haptics, route exit
  protection, and the control bar with back, next, and finish.
- `widgets/intro/calorie_intro_pages.dart`: Builds the raw page list in the
  order of `CalorieIntroPage` and wraps every page in its chapter theme.
- `widgets/intro/intro_chapter_labels.dart`: Localized chapter name, kicker,
  counter, section, and next-action label per page.
- `widgets/intro/calorie_intro_finish_handler.dart`: Saves the goal, shows
  localized save failures, marks onboarding complete, and exits the setup route.
- `widgets/intro/pages/`: One widget per page. `intro_story_page.dart` is the
  shared layout of the six explaining pages.
- `widgets/intro/fields/`: Building blocks shared by the pages.
  - Chapter look: `intro_backdrop.dart` (breathing blobs, `intro_stream_lines.dart`,
    vignette; stops under reduced motion), `intro_chapter_chrome.dart` (counter,
    section, progress segments), `intro_chapter_header.dart` (kicker, headline
    with highlighted words, lead), `intro_chapter_theme.dart` (tints the theme's
    accent roles with the chapter accent).
  - Page shells: `intro_scroll_body.dart` (centred, scrolls when needed),
    `intro_page_content.dart` (header on top of it), and
    `intro_fill_page_content.dart` (header on top, footer above the controls,
    pickers fill the rest; `intro_picker_stack.dart` splits that height).
  - Pickers: `intro_wheel.dart` with `intro_wheel_selection_band.dart`,
    `intro_vertical_wheel_field.dart`, `intro_birth_date_card.dart`,
    `intro_weekday_selector.dart`, all inside `intro_field_card.dart`.
  - Choices and results: `intro_choice_card.dart` on `intro_selectable_card.dart`,
    `intro_gender_card.dart`, `intro_week_depot_chart.dart`,
    `intro_summary_result_card.dart`.
  - Notes: `intro_page_note.dart` and `intro_warning_note.dart`.

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

### Intro Navigation

1. `CalorieGoalOnboardingPage` loads `CalorieGoalSettings`.
2. `CalorieIntroFlow` creates a calculator form provider from the saved
   calculator profile, using empty onboarding defaults where needed.
3. `IntroductionScreen` runs with `freeze: true`, so swiping is disabled and only
   the intro controls move between pages.
4. The shared next control asks `CalorieIntroController.next` for the target
   page. When the current page is incomplete the controller returns `null` and
   turns on validation errors instead of moving.
5. The identity page needs gender and a birthday, the body page needs height and
   weight, and the target page needs a target weight. Every picker shows a
   plausible starting value but reports nothing until the user moves it, so an
   untouched page still fails validation.
6. Maintain-weight users skip the pace page in both directions.

### Saving The Goal

1. The summary page calls the finish callback.
2. `CalorieIntroFinishHandler` reads the calculated profile from the form state.
3. `CalorieGoalOnboardingFinishFlow.saveGoal` receives a
   `CalorieGoalOnboardingFinishRequest` with the profile and today.
4. The goal controller saves the calculated goal starting today, with
   `countGoalStartDayForLearning` set to `false`, because onboarding usually
   happens in the middle of an untracked day.
5. Burn Week is bootstrapped from today.
6. On success, onboarding writes the completion marker.
7. The flow allows route exit and returns to the previous route or diary home.
8. On failure, saving state is reset and a localized failure snackbar is shown.

### Birthday And Age

1. The identity page offers day, month, and year wheels between 16 and 100 years
   back. Any wheel move emits one complete date; the day is clamped to the days
   of the selected month and the whole date to the age bounds.
2. `CalorieGoalCalculatorFormController.updateBirthDate` stores the birth date
   and derives `ageYearsText` from `clockProvider`.
3. `CalorieCalculatorProfile.birthDate` is persisted with the goal, and
   `ageAt(now)` derives the current age, falling back to the stored `ageYears`
   for profiles saved before birthdays existed.

## Accepted Dependencies

- `core/router`: Redirects users into or out of onboarding based on completion
  state.
- `features/auth`: Supplies the current user ID for completion markers.
- `core/preferences`: Stores the user-scoped onboarding completion marker.
- `features/calories`: Only through its public edge. Domain types
  (`CalorieCalculatorProfile`, `CalorieGoalSettings`,
  `CalorieGoalCalculationResult`, `CalorieActivityLevelOption`, the age
  calculator, diary day helpers) and the legacy `provider/` controllers the
  calories README lists for onboarding (calculator form controller, goal
  controller, Burn Week run controller). No calories widgets: the intro draws
  its own result and warning cards.
- `core/theme`: `IntroAccentColors` for the chapter accents.
- `core/widgets`: `AppHapticFeedback` for the rising haptics.
- `l10n`: Supplies all user-facing copy in the intro.

## Persistence Model

- Completion marker:
  `calorie_goal_onboarding_completed:{userId}` in app preferences, value `1`.
- Calculated goal:
  saved through `CalorieGoalController` into calorie goal settings.
- Burn Week:
  bootstrapped through `BurnWeekRunController`.

## Tests

`test/features/onboarding` mirrors the feature structure:

- `application/` tests the finish flow: goal saved for today, counting start
  day, Burn Week bootstrap, and the failed-save path.
- `domain/` tests preference keys and the target-date estimator.
- `presentation/controllers/` tests page navigation, per-page gating, the
  maintain-mode pace skip, and the saving flags.
- `presentation/models/` tests chapter numbering and page order;
  `presentation/widgets/intro/intro_chapter_labels_test.dart` tests the
  counter, kicker, section, and next-action labels.
- `domain/intro_activity_option_test.dart` tests the four levels and the
  nearest-level fallback.
- `presentation/widgets/intro/` drives the whole intro: the happy path to a
  saved goal, blocked pages, the estimated target date, the login action, and
  the save-failure snackbar. `intro_birth_date_card_test.dart` covers the
  birthday dials, including the day and age-bound clamping.
- `presentation/` tests that the page shows a spinner until settings load.

`integration_test/calories/calorie_onboarding_visible_flow_test.dart` runs the
same walk on a device, including keyboard avoidance.

Router tests in `test/core/router/app_router_test.dart` cover the route-level
onboarding redirects and the transition from setup to diary home after
completion.

## Legacy

- `provider/` is a feature-level provider folder. `architecture.md` forbids new
  ones. New providers go into `application/` or next to the thing they provide.
