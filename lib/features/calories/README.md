# Calories Feature

Calories owns calorie logging, goal settings, Burn Week state, weekly check-in
state, and calorie-owned side effects from health or weight changes.

## Owns

- Calorie repositories and commit stores under `data/`.
- Calorie entries, goals, calculator inputs, weekly check-in, and Burn Week
  domain models under `domain/`.
- Calorie use-case providers and reactive cross-feature sync under
  `application/`.
- Calorie pages, dialogs, sheets, and section widgets under `presentation/`.
- Debug-only dump and export surfaces under `debug/`.
- Legacy calorie controllers and derived providers under `provider/`.

## Does Not Own

- Health Connect infrastructure, permission state, or raw health services.
- Diary page ordering, date navigation, or diary-level composition.
- Activity card layout or activity-owned action orchestration.
- Inventory item storage, prepared meal storage, or household scope state.

## Public Edge

- `application/calorie_health_connection_sync.dart` reacts to Health
  connection readiness and records the calorie activity-tracking start day.
- `application/calorie_weight_state_refresh.dart` refreshes calorie state after
  health weight changes.
- Legacy controllers and derived providers under `provider/` are current public
  edge for existing Diary, Activity, Settings, Home, Onboarding, and Inventory
  integrations.
- Domain models under `domain/` used by Diary, Activity, and Settings.
- Complete presentation surfaces such as calorie entry editors, goal dialogs,
  calculator sheets, and diary health card parts.
- Debug-only surfaces under `debug/`, currently composed by the Diary home shell
  only in debug builds.

Other features should depend on domain types or complete widgets instead of
reassembling Calories internals. New calorie-owned side effects should live in
`application/` providers that react to owner feature state, instead of expanding
the legacy `provider/` surface or exposing action wrappers to sibling features.

## Providers

- New use-case providers live in `application/`.
- Repository providers live with repository implementations in `data/`.
- The feature-level `provider/` folder is legacy structure and currently holds
  calorie controllers and derived state. Do not add new provider files there
  unless working inside existing legacy code where moving would create
  unrelated churn.
- Providers use Riverpod code generation.

Main application providers:

- `application/calorie_health_connection_sync.dart`
- `application/calorie_weight_state_refresh.dart`
- `application/calorie_entry_delete_flow.dart`
- `application/calorie_inventory_entry_save_handler.dart`

## TDEE Learning

Calories starts with a classic calculator target. The calculator profile
produces Total-TDEE from height, weight, age, sex, and selected activity level.
Goal mode and speed then apply deficit or surplus to create the initial daily
target.

When Health activity tracking is connected, the target is split into a base
goal and tracked activity credit:

```text
baseGoal = totalTdeeGoal - expectedActivityKcal * 0.75
dailyGoal = baseGoal + trackedActivityTodayKcal * 0.75
```

Without Health activity tracking, users see the normal Total-TDEE-based goal.

Weekly learned TDEE uses an expanding window first, then a rolling 28-day
window:

```text
week 1: days 1-7
week 2: days 1-14
week 3: days 1-21
week 4: days 1-28
week 5+: latest 28 days only
```

The measured learning signal is calculated from intake, weight trend, and
tracked activity in the same learning window:

```text
measuredTotalTdee = averageIntake - weightTrendKgPerDay * 7000
measuredBaseTdee = measuredTotalTdee - averageTrackedActivityKcal * 0.75
newLearnedBaseTdee = oldLearnedBaseTdee * 0.70 + measuredBaseTdee * 0.30
```

The learned value is a base target without tracked activity credit. Daily UI
adds today's tracked activity back with the same 75% correction.

Heart days count as perfect days for learning. The backend substitutes that
day's goal kcal and ignores raw logged intake for the heart day. This keeps the
7-day balance intact without letting one marked day distort TDEE learning.

Missing intake blocks learning when at least three intake days are missing.
Skipped intake days are interpolated from logged-day average. Weight learning
requires enough boundary data to form at least two weight points; two-point
calculations are allowed but marked low confidence.

Weight handling uses median filtering plus a trendline:

```text
health samples per day -> median
manual weight overrides health median
weight points -> local median-of-three smoothing
linear regression slope -> kg/day trend
```

## Accepted Dependencies

- `core` for routing, theme tokens, shared widgets, and local day helpers.
- `features/auth` for user-scoped calorie repositories and cache storage.
- `features/health` for public health controllers, services, and domain data
  used by calorie goals and connection sync.

Inventory-backed save/delete behavior is supplied through calorie-owned ports.
The concrete inventory adapters live in `features/inventory` so Calories does
not depend on Inventory.

Keep health-triggered calorie effects in Calories application providers. Health
must not depend on Calories.

## Tests

- `test/features/calories/application/`
- `test/features/calories/data/`
- `test/features/calories/domain/`
- `test/features/calories/presentation/`
- `test/features/calories/provider/`
