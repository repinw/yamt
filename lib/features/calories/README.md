# Calories Feature

## Purpose

Calories owns calorie logging, goal settings, Burn Week state, weekly check-in
state, learned TDEE, and the calorie side effects of health and weight
changes.

## Owns

- Calorie entries, the entry cache, product overrides, goal settings, and the
  Burn Week run state, stored by the repositories in `data/`.
- Calorie entries, goals, calculator inputs, weekly check-ins, learned TDEE,
  and Burn Week rules in `domain/`.
- The session-wide calorie state in `application/`: goal settings, macro
  settings, the Burn Week run, the visible week window, resolved daily goals,
  the week overview, learned TDEE per day, weekly check-in data and actions,
  the entry mutation stream, and the calorie reactions to weight changes.
  Later features read and change this state.
- The debug dump tooling in `application/` (dump builders), `data/` (text
  file export), and `presentation/`; the Home side menu shows it only in
  debug builds.
- Calorie pages, dialogs, sheets, and the controllers and view models they
  own in `presentation/`.

## Does Not Own

- Health Connect access, permission state, or raw health weight data.
- Diary page ordering, date navigation, or diary-level composition.
- Activity card layout or activity-owned action orchestration.
- Inventory item storage, prepared meal storage, or household scope state.
  Inventory-backed save and delete run through calorie-owned ports that
  inventory implements, so Calories does not depend on Inventory.

## Public UI

- `CalorieEntryDetailsFlow` for the entry details page, which Diary owns. It
  saves a meal or day change, changes the amount, logs an entry again, and
  removes it, each at once with an undo snack bar. Removing an entry with stock
  asks whether it goes back to the inventory.
- The TDEE analytics page (`AppRoutes.homeCaloriesAnalytics`) for expenditure,
  the flux range corridor, and goal anticipation. It can preselect goal cycles
  through `AppRoutes.homeCaloriesAnalyticsCyclesParam`.
- The goal archive page (`AppRoutes.homeSettingsGoalArchive`) lists the
  current and archived goals and opens analytics for selected goal cycles.
- `CalorieGoalReachedFlow` checks a recorded weight, shows the one-time
  reached-goal prompt, and optionally opens the new-goal sheet.
- The new-goal flow opens the calculator sheet that ends the active goal and
  starts a new one.
- `TrainingDayChips` and `TrainingWeekDepotChart` pick the training days of
  a week and show how the week's calories spread over training and rest days.
  Onboarding and the weekly check-in use them.
- Calorie entry editors, goal dialogs, calculator sheets, the consumed-unit
  labels, and the debug menu section of the Home side menu.

## Rules

- Saving an entry is optimistic. The repository writes through the Firestore
  local cache and does not wait for the server, so a save works offline.
  Follow-up writes (skipped-day reset, product override, check-in snapshot
  invalidation) run in the background.
- A quick entry (`CalorieEntry.isQuickEntry`) holds calories and macros typed
  in by hand, without a food. The typed values are the totals, so it has no
  real amount and cannot change it.
- An entry logged from the inventory keeps what it still takes from the stock
  in `sourceInventoryAmountToRestore`, so a later delete returns the right
  amount. A failed amount change puts the stock back.
- `CalorieCalculatorProfile` derives the current age from its optional
  `birthDate`, falling back to the stored `ageYears` for profiles saved before
  birthdays existed.
- Health must not depend on Calories. Calorie reactions to weight changes live
  in Calories `application/`.

### TDEE Learning

Calories uses a pure intake and weight-trend model. The calculator profile
produces an initial TDEE from height, weight, age, sex, and selected activity level.
Goal mode and speed then apply deficit or surplus to create the initial daily target.

Health Connect is restricted strictly to body weight readings (`HealthDataType.weight`).
The app does not read wearable activity (steps, workouts, active calories), so
tracked activity never changes TDEE or the daily target.

#### Calorie Cycling & Training Days

Users can configure training days (e.g. Mo, We, Fr) and a kcal offset (+200..+300 kcal).
The weekly budget is preserved budget-neutrally:

```text
N_training = count of training days
N_rest = 7 - N_training
offset_rest = (N_training * offset_training) / N_rest
trainingGoal = baseGoal + offset_training
restGoal = max(1200, baseGoal - offset_rest)
```

`N_training` counts the training days of the 7-day run of the day, with the
per-day overrides, so every run keeps the base goal times seven. A day type
change in the diary or a run training edit on the profile page moves calories
only between the days of that run; earlier runs keep their goals. When past
days of the run get a new goal, the carryover passes the difference on to the
days left. Before a goal starts counting there is no run, and the weekly
schedule counts instead.

The diary header includes a toggle (`🏋️ Trainingstag`, `🛋️ Ruhetag`, `⏸️ Pausentag`).

#### Learning Windows & Interpolation

Weekly learned TDEE uses an expanding window first, then a rolling 28-day window:

```text
week 1: days 1-7
week 2: days 1-14
week 3: days 1-21
week 4: days 1-28
week 5+: latest 28 days only
```

The measured learning signal is calculated strictly from intake and weight trend:

```text
measuredTdee = averageIntake - weightTrendKgPerDay * 7700
newDataWeight = 0.5 * learningDays / 28
newLearnedTdee = oldLearnedTdee * (1 - newDataWeight) + measuredTdee * newDataWeight
```

A short window at the start of a goal is noisy, so it moves the learned TDEE
less than a full 28-day window.

#### Pause Days & Missing Days

- A day without logged entries or explicitly set to pause acts as a **Pausentag**.
- Pausentage (Urlaub, Krankheit, Wettkampf) are neutral: no streak penalty, ignored in learning.
- In a 7-day check-in window:
  - Missing/pause days (< 3 days) are auto-interpolated from the logged average of tracked days without blocking the check-in.
  - Check-in triggers every 7 days from the anchor start date.
  - >= 3 missing days blocks learning due to insufficient data.

#### Check-in Plan

- The check-in plans the run that contains the day it is done. It suggests
  the training weekdays of the reviewed run. After a late check-in, the past
  days of that run keep their type, because their goals were already in use.
- The targets of the next run come from the measured or the previous goal:
  the training and rest day split of the planned sessions, and the macros
  before and after. The macros count training when the goal has weekly
  training days, as the diary targets do.
- The training days are saved before the decision, so a failed save leaves
  the check-in open.
- The debug preview shows the latest completed window, or made-up data when
  the goal has none, and saves nothing.

Weight handling in the weekly runs uses raw daily weights and a robust slope:

```text
health samples per day -> median
manual weight overrides health median
weight points -> Theil-Sen slope (median of pairwise slopes) -> kg/day trend
```

The runs never use the smoothed trend weight from Health. A simulation showed
that pre-smoothed weights delay the learned TDEE by one to two weeks without
making it calmer. The TDEE analytics page shows the smoothed trend weight as
its weight line, weight numbers, and goal projection.

#### Macro Weight

The protein and fat targets of a day use the macro weight from the goal
history (`macroWeightKgForDay`), not the current calculator profile weight.
A weekly check-in snapshot stores the trend weight on its window end, or on the
last weigh-in before it, as `macroWeightKg`; a rejected check-in stores it too.
A calculated goal entry supplies its profile weight as the start weight. A
check-in without any weigh-in keeps the previous weight. The smoothed trend
weight is right here because the macros need a calm level, not a slope.

#### Body Data in New Goals

When a calculator profile exists, the calculator flow shows one "Your body
data" step (`CalorieGoalBodySummary`) instead of the sex, height, and age
steps, and the learned TDEE goal sheet shows the same list. Its "Edit in
profile" link closes the goal sheet and opens `AppRoutes.homeProfile`, where
the body data is edited. Weight, activity level, and the goal stay in the
flow, because a new goal asks them anew.

#### Body Data Edits

`applyBodyEdit` (`domain/calorie_goal_body_edits.dart`) changes height, sex,
birthday, or start weight after onboarding. The calculator profile always
takes the edit, so the macros follow it: the height caps the macro reference
weight and the sex sets the fat factor. With a learned TDEE the calorie goal
and the goal history stay. Without one, the edit corrects the active
calculated goal from its start: its profile and calorie goal are calculated
again, and weekly check-ins that kept the old goal take the new one. The start
weight is fixed once a TDEE is learned. `CalorieBodyEditService` shows today's
calorie goal and macros before and after an edit and saves it.

#### Run Training Days

`withRunTrainingDays` (`domain/calorie_run_training_plan.dart`) sets the
training days of the current 7-day run. It writes the same per-day overrides
as a day type change in the diary, only for the days of that run; pause days
keep their type, and later runs follow the weekly schedule again.
`CalorieRunTrainingService` shows each changed day's calorie goal and the run
total before and after, and the other days whose goal changes, and saves the
days.
