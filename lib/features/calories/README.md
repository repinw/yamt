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
- The goal list: every goal with its dates, pace, start and end weight, and
  reached date. Progress reads it for its goal menu and past goal card.
- The closed day: today closed early by the signed-in user, saved only on
  this device, so
  tomorrow's week overview counts today as finished and gives tomorrow its
  carryover.
- Plans: food the signed-in user plans to eat on a later day, stored
  encrypted apart from the calorie entries so no sum counts them, and the
  actions that save and delete them.
- `calorieEntryDayChange`: a write outside Calories, such as a delete with
  its stock, reports the entry's day. Calories then refreshes the diary
  overview and marks the weekly check-ins from that day as stale.
- The debug dump tooling in `application/` (dump builders), `data/` (text
  file export), and `presentation/`; the Home side menu shows it only in
  debug builds.
- Calorie pages, dialogs, sheets, and the controllers and view models they
  own in `presentation/`.

## Does Not Own

- Health Connect access, permission state, or raw health weight data.
- Diary page ordering, date navigation, or diary-level composition.
- Activity card layout or activity-owned action orchestration.
- Showing past goals: Progress shows them in its "Ziel" scope menu; there is
  no goal archive page.
- Inventory item storage, prepared meal storage, or household scope state.
  Inventory saves, changes, and deletes the entries that took stock, so
  Calories does not depend on Inventory and has no port for it.

## Public UI

- `CalorieGoalReachedFlow` checks a recorded weight, shows the one-time
  reached-goal prompt, and optionally opens the new-goal sheet.
- The new-goal flow opens the calculator sheet that ends the active goal and
  starts a new one. It completes with whether a new goal was saved and can
  show a back arrow for callers that return to where the user came from.
- `TrainingDayChips` and `TrainingWeekDepotChart` pick the training days of
  a week and show how the week's calories spread over training and rest days.
  Onboarding and the weekly check-in use them.
- Calorie entry editors, goal dialogs, calculator sheets, the consumed-unit
  labels, and the debug menu section of the Home side menu.
- `showCalorieEntryEditor` opens the new-entry editor on the root navigator.
  It saves nothing: it completes with the entry on save and with null when
  the editor closes any other way, and the caller saves the entry.

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

Users can configure training days (e.g. Mo, We, Fr) and the kcal of one
session (default 250). The planned training days split the week:

```text
N_planned = planned training days of the 7-day run
restGoal = max(1200, baseGoal - N_planned * session / 7)
trainingGoal = max(1200, baseGoal - N_planned * session / 7 + session)
```

The plan is the weekly schedule with the planned per-day overrides
(`trainingDayOverrides`) that the weekly check-in and the profile set, so
every run keeps the base goal times seven, and a plan edit moves calories
only between the days of its run. A day type change in the diary is outside
the plan (`unplannedTrainingDayOverrides`): the day gains or loses one session
and the other days keep their goals, so the run total moves by one session.
Before a goal starts counting there is no run, and the weekly schedule counts
instead.

The diary header includes a toggle (`🏋️ Trainingstag`, `🛋️ Ruhetag`, `⏸️ Pausentag`).

#### Daily TDEE

`DailyTdeeEstimator` (domain) estimates the TDEE every day from the first goal
on. The Fortschritt TDEE chart and the weekly check-in read it.

```text
weight level  += 0.25 * (weigh-in - predicted level)    (Holt)
weight trend  += 0.06 * (level change - trend)
intake        += 0.15 * (day intake - intake)
measured TDEE  = intake - trend (kg/day) * 7700
updates 0-5: +0.33 of the gap, 6-12: +0.66, update 13: all of it,
then at most 150 kcal per week; never below max(750, 0.85 * BMR)
```

- A day without intake (or a pause day) counts with yesterday's TDEE plus
  the trend energy. With 4 or more such days in the last 7 the TDEE holds.
- Weights under 25 kg and intake outside 0-50 000 kcal are ignored.
- An update is a day the TDEE moved; held days do not use up the ramp-up.
- Today keeps yesterday's value, because today's diary is not complete yet.
- It is computed on read from entries and weights; nothing is stored.

#### Weekly Check-in TDEE

The check-in takes the daily TDEE at the last day of its window
(`calculateWeeklyCheckInFromDailyTdee`). The daily TDEE runs from the start
of the first goal through the window end, so the check-in reads all diary
days and weights since then.

```text
new goal = TDEE -/+ pace (kg/week) * 7700 / 7   (lose / gain; maintain: TDEE)
new goal moves at most 200 kcal from the corrected goal of the window end
```

A declined check-in keeps the goal from before the check-in.

#### Goals Follow the Daily TDEE

Every counting day moves its stored goal by how far the daily TDEE changed
since that goal was set (`goalTdeeOffsets`). Budget readers get the moved
goals from `calorieBudgetSettingsProvider`; writes keep using the stored
settings, and the offsets are never saved.

```text
day goal  = stored goal + TDEE known when the day starts - reference TDEE
TDEE known when the day starts = the estimate of the day before
                                 (of yesterday for today and later days)
reference = check-in goal: the TDEE of its check-in
            other goal with a profile: the TDEE of the day before it took
            effect, else the calculator TDEE
            goal without either: no offset
```

- Every day from the first goal through the end of the running week has an
  offset; days keep it after their week ends. The carryover still starts
  fresh with each run. Offsets are computed on read, so an edit of an old
  entry or a late weight can still move the goals of later days.
- A falling TDEE never pushes a goal under the 1200 kcal minimum budget.
- Until the offsets are computed, the stored goals stand, so a budget never
  waits; an unchanged offset rebuilds nothing.
- The history comes from `watchEntriesFrom`, which starts from the local
  cache and decrypts only the entries a change touched; Health weights load
  once per diary day.

#### Pause Days & Missing Days

- A day without logged entries or explicitly set to pause acts as a **Pausentag**.
- Pausentage (Urlaub, Krankheit, Wettkampf) are neutral: no streak penalty, ignored in learning.
- In a 7-day check-in window:
  - Missing/pause days (< 3 days) are auto-interpolated from the logged average of tracked days without blocking the check-in.
  - Check-in triggers every 7 days from the anchor start date.
  - >= 3 missing days in the window blocks the check-in.

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

Weights per day: the median of all manual weights and the Health samples of
all devices, read from the cloud (`weightSeriesProvider`). The daily TDEE smooths these raw weights itself; the smoothed
trend weight from Health is only the weight line, weight numbers, and goal
projection of the charts.

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

`withRunTrainingDays` (`domain/calorie_run_training_plan.dart`) plans the
training days of the current 7-day run. It writes planned per-day overrides
for the days of that run and drops their day type changes from the diary, so
the run total is the base goal times seven again. Pause days keep their type,
and later runs follow the weekly schedule again.
`CalorieRunTrainingService` shows each changed day's calorie goal and the run
total before and after, and the other days whose goal changes, and saves the
days.
