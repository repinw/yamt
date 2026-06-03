# Calorie Learning And Flex Rules

This document summarizes the agreed product rules for:

- first-week TDEE learning
- flex target and carryover
- manual target recalculation
- activity handling before and after learning

## 1. Goal Runs And Starter Day

Goal runs are anchored to the user's goal start, not to calendar weeks.

Normal future start:

- If the user starts tomorrow or later, that date is day 1.
- The first check-in is due after 7 full counted days.
- The first learning window uses all 7 days.

Same-day start:

- Today is a starter day.
- The goal is active today and the app can show a useful budget.
- The starter day is not used for learned TDEE calculation.
- The first check-in is due after 6 normal tracked days.
- The first learning window uses only those 6 full days.
- Later check-ins use normal 7-day windows.

Same-day manual recalculation:

- The app checks today's food entries and asks whether today was tracked.
- If the user says today was not tracked, today becomes a starter day.
- If the user says today was tracked, today counts as day 1 of the new run.
- Old carryover is cut either way when the new target starts.

Example for same-day start on April 24, 2026:

- April 24: starter day, active budget, excluded from learning
- April 25-30: counted days
- May 1: first check-in due, calculation uses April 25-30
- May 1-7: next normal 7-day window
- May 8: next check-in

Weight handling for that first shifted window:

- The onboarding/start-day weight can still be used as the start baseline.
- Missing first counted-day weight is acceptable if a usable start baseline
  exists.
- An end-of-window weight is still required.
- If no usable baseline weight or no end weight exists, block the check-in.

## 2. Flex Target And Carryover

Flex target uses one canonical carryover balance for Classic and Balance.
Classic switches can hide activity or carryover for the current display, but
they do not create a separate carryover ledger.

Core rules:

```text
cycle_carryover_before_today =
  sum(full_day_goal[finished_day] - eaten[finished_day])

remaining_cycle_days =
  count(today through the end of the current 7-day run)

daily_carryover_adjustment =
  cycle_carryover_before_today / remaining_cycle_days

raw_flex_target[today] =
  base_target[today] + activity_bonus[today] + daily_carryover_adjustment

display_flex_target[today] = max(0, raw_flex_target[today])
```

Notes:

- Eating too much lowers the following days by spreading the overage across
  the remaining days in the current run.
- Eating too little raises the following days by spreading the unused calories
  across the remaining days in the current run.
- Carryover must come from the raw balance, not the clamped display value.
- Past days use the canonical full-day goal, including activity bonus that was
  available on that day.

Forward recalculation only happens if history changes, for example:

- user edits food on an earlier day
- user changes a skipped day
- user changes a past goal start or target

## 3. Manual Target Recalculation

Manual recalculation starts a new balance cycle.

Agreed rule:

- Carryover from the old cycle does not flow into the new manual target.
- Carryover resets to `0` at the selected new `goalStartAt`.
- Past days remain part of history, but no longer affect the new cycle.

Implications:

- Recalculate starting today: reset today.
- Recalculate starting in the future: old cycle continues until that date.
- Recalculate starting in the past: recalculate the timeline forward from that
  date.

## 4. Activity Before The First Weekly Check-In

The selected PAL is converted into expected daily activity kcal and saved with
the goal snapshot.

```text
expectedActivityKcal = BMR * (PAL - 1)
```

Rules:

- Non-tracking users keep the normal PAL-based target.
- Tracking users split the calculator target into Base-TDEE plus tracked
  activity credit.
- Today should never feel punished for tracking a workout.
- Expected activity and tracked activity use the same tracker correction:

```text
baseTarget = totalTarget - expectedActivityKcal * 0.75
activityBonus = trackedActivityKcal * 0.75
dynamicTargetToday = baseTarget + activityBonus
```

- If tracking starts mid-run, days before tracking are unknown, not zero.
- Tracking logic starts from the tracking start date only.
- The first Health Connect action that returns `ready` writes
  `activityTrackingStartDate` as the current diary day.
- Passive status loading must not write settings, because calorie providers
  can be loading at the same time.
- If old users have no tracking start date yet, calorie math treats the
  current diary day as the start for that calculation. Earlier days stay
  unknown until a real tracking start date is saved.
- The saved expected activity kcal is a snapshot. It changes only when the
  user recalculates the goal or a learned goal update writes a new baseline.

Reason:

- The onboarding activity level already raises the base target.
- Removing expected activity before adding tracked activity avoids double
  dipping for active users.

Suggested product behavior:

- Base target still comes from TDEE and chosen activity level.
- Health-off users see the normal Total-TDEE target.
- Health-on users earn back 75% of tracked activity after expected activity is
  removed from the Total-TDEE target.
- If the user does not eat all of that bonus, normal carryover can still move
  it forward.
- Classic can hide today's activity bonus, but the canonical Balance ledger
  still uses it for carryover.

## 5. Weekly Learned TDEE After 7 Full Days

Learned TDEE updates on 7-day boundaries, not every day.

Reason:

- The user needs a stable base target for meal planning.
- Daily TDEE changes make the budget feel random and hard to trust.
- Food, weight, and activity are noisy; a 7-day boundary gives enough signal.

Boundary logic:

- Days 1-7 are learned together.
- The learned target from days 1-7 applies from day 8.
- Days 1-14 are learned together at the second boundary.
- The learned target from days 1-14 applies from day 15.
- Later windows keep the same pattern, capped by the maximum learning lookback.
- Between boundaries, the learned base target stays fixed.

Historical edits:

- Food, skipped-day, weight, activity, or goal-start changes are source data.
- When source history changes, affected weekly calculations must be rebuilt
  forward from that changed day.
- Cached weekly learned TDEE snapshots are convenience/cache, not truth.
- Weekly check-in UI is acknowledgement and explanation; the math source is
  the diary history.
- If a weekly check-in is blocked by missing source data and the user dismisses
  it, the app keeps using the last valid learned TDEE. The blocked window stays
  parked until the missing data is entered, then the cascade can continue.

After each weekly boundary:

- calculate average burned/active calories across the learning window
- count heart days as perfect days by substituting that day's goal kcal
- subtract the average credited activity from measured Total-TDEE
- keep learned Base-TDEE as the learned base target input
- learn maintenance TDEE separately from the user's target mode and speed

Important:

- Average credited activity is removed from learned Base-TDEE, then today's
  credited activity can be added back.
- The weekly check-in must smooth maintenance TDEE, not target calories.
- Lose/gain/maintain is applied after smoothing the learned maintenance TDEE.
- Daily activity and carryover can still change the display target, but the
  learned base target changes only at weekly boundaries.

Weekly boundary logic:

```text
measuredTdee = avgIntake - weightChangePerDay * 7000
measuredBaseTdee = measuredTdee - averageTrackedActivity * 0.75
smoothedTdee = blend(oldLearnedBaseTdee, measuredBaseTdee)
baseTarget = smoothedTdee +/- deficit_or_surplus
weeklyBaseTarget = clamp_change_from_previous_week(baseTarget)
```

Daily display logic after a learned weekly target exists:

```text
activityBonus = todayBurned * 0.75
dynamicTargetToday = weeklyBaseTarget + activityBonus
flexTargetToday = dynamicTargetToday + carryover
```

Agreed UX behavior:

- Normal training day should not feel punished.
- Rest day uses the learned Base-TDEE target.
- Tracked activity can raise the target.
- If the user becomes less active over time, the next weekly TDEE update can
  lower the learned baseline naturally.

## 6. Product Intent

The system should feel fair and motivating:

- partial first days must not poison TDEE learning
- carryover should be stable and predictable
- manual recalculation should create a clean restart
- early workouts should feel rewarded
- normal or rest days should not feel punitive

## 7. Legacy Math Migration

Legacy settings without `calorieMathVersion` are hard-migrated to version `2`.

Rules:

- Keep the active daily goal and calculator profile.
- Backfill `expectedActivityKcal` from learned activity first, then stored
  expected activity, then `BMR * (PAL - 1)`.
- Replace old goal history with one fresh goal snapshot.
- Preserve the active 7-day run day for already active goals by restarting the
  migrated snapshot at the current run start.
- This drops legacy carryover before the current run without pushing a user
  from week 3 day 3 back to day 1.
- Preserve future goal starts if the user has selected tomorrow or later.
- Drop pending weekly check-ins, skipped starter days, old carryover, and old
  eating-window fields.

Reason:

- Small existing user base.
- Old carryover/activity/window math can create large wrong targets.
- A hard restart gives predictable numbers under the new single math model.
