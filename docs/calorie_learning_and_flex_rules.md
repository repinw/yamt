# Calorie Learning And Flex Rules

This document summarizes the agreed product rules for:

- first-week TDEE learning
- flex target and carryover
- manual target recalculation
- activity handling before and after learning

## 1. Weekly TDEE Bugfix

Problem:

- If a user starts the goal mid-day, the first day is only partial.
- Using that partial day as a full day in the first 7-day learning window
  pulls the learned TDEE down incorrectly.

Agreed rule:

- If the goal starts mid-day, the first weekly check-in waits for 7 full days.
- The partial start day is ignored for first-week TDEE learning.
- We do not scale the partial day up.
- We do not use a 6-day learning window.

Example:

- Goal starts on April 8 at 18:00.
- Full tracking days are April 9 through April 15.
- The first weekly check-in is due on April 16.

Weight handling for that first shifted window:

- The onboarding/start-day weight can still be used as the start baseline.
- Missing day-2 weight is acceptable if a usable start baseline exists.
- An end-of-window weight is still required.
- If no usable baseline weight or no end weight exists, block the check-in.

## 2. Flex Target And Carryover

Flex target is calculated forward from the current cycle without
reinterpreting old days every day.

Core rules:

```text
carryover_in[today] = carryover_out[yesterday]

raw_flex_target[today] = base_target[today] + carryover_in[today]

display_flex_target[today] = max(0, raw_flex_target[today])

carryover_out[today] = raw_flex_target[today] - eaten_today
```

Notes:

- Surplus lowers the next day's flex target.
- Deficit raises the next day's flex target.
- Carryover must come from the raw balance, not the clamped display value.
- Past days are not re-decided every day.

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

Strict learned activity delta should not be used before the app has enough
data.

At the same time, a user who starts fresh and does sport on a full first day
should feel rewarded.

Agreed direction:

- Before the first weekly check-in, use a bootstrap activity bonus.
- Bonus applies only on full days.
- Bonus is positive-only.
- Do not apply negative activity penalties during the first learning week.
- Do not add all burned calories.
- Use only a fraction of workout calories.
- Show a small hint that the app is still learning the user's sport behavior.

Reason:

- The onboarding activity level already raises the base target.
- Adding all burned calories on top would double dip for active users.

Suggested product behavior:

- Base target still comes from TDEE and chosen activity level.
- Bootstrap workout bonus adds only a modest extra allowance.
- If the user does not eat all of that bonus, normal carryover can still move
  it forward.

## 5. Activity After 7 Full Days

After the first weekly check-in:

- calculate average burned/active calories across the learning window
- store that average as the expected activity baseline
- keep learned TDEE as the learned base target input

Important:

- Average burned calories are not added on top of learned TDEE again.
- Learned TDEE already includes the user's average activity pattern.

Day logic:

```text
baseTarget = learnedTdee +/- deficit_or_surplus
activityBonus = max(0, todayBurned - avgBurned)
dynamicTargetToday = baseTarget + activityBonus
flexTargetToday = dynamicTargetToday + carryover
```

Agreed UX behavior:

- Normal training day should not feel punished.
- Rest day should not lower the target.
- Extra activity above normal can raise the target.
- If the user becomes less active over time, the next weekly TDEE update can
  lower the learned baseline naturally.

## 6. Product Intent

The system should feel fair and motivating:

- partial first days must not poison TDEE learning
- carryover should be stable and predictable
- manual recalculation should create a clean restart
- early workouts should feel rewarded
- normal or rest days should not feel punitive
