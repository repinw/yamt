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

- `application/calorie_weight_state_refresh.dart` refreshes calorie state after
  health weight changes.
- `application/calorie_entry_deleter.dart` exposes calorie-entry deletion to
  integrating application layers without exposing the legacy controller.
- `application/daily_nutrition_target_resolver_service.dart` provides
  `dailyNutritionTargetResolverProvider` implementing
  `domain/daily_nutrition_target_resolver.dart` to resolve daily nutrition
  and macro targets including calorie cycling and carryover.
- Legacy controllers and derived providers under `provider/` are current public
  edge for existing Diary, Activity, Settings, Home, Onboarding, and Inventory
  integrations.
- Domain models under `domain/` used by Diary, Activity, and Settings.
  `CalorieCalculatorProfile` carries an optional `birthDate` and derives the
  current age with `ageAt(now)`, falling back to the stored `ageYears` for
  profiles saved before birthdays existed.
  `CalorieGoalCalculatorFormController.updateBirthDate` stores it and keeps
  `ageYearsText` in sync with `clockProvider`.
- Complete presentation surfaces such as calorie entry editors, goal dialogs,
  calculator sheets, and diary health card parts.
- The entry details sheet (`AppRoutes.homeCaloriesEntryDetailsPath`,
  `presentation/widgets/calorie_entry_details_content.dart`). It opens on a
  `HeroSheetPage`; the entry image uses `HeroTags.loggedEntryImage(entryId)`,
  so a caller that shows the same image can fly it into the sheet. Meal, day,
  and amount changes save at once with an undo
  (`calorie_entry_details_actions.dart`). The nutrition table follows the food
  label layout and shows `CalorieEntry.nutrientDetails` when the entry has
  them.
- `domain/calorie_nutrient_details.dart` holds label nutrients beyond the
  macros (saturated and polyunsaturated fat, sugar, fiber, salt).
  `CalorieProductProfile` and `CalorieEntry` carry them; integrating features
  fill them when they log food.
- `domain/calorie_entry_edits.dart` holds the pure rules for changing the
  amount and logging an entry again.
- `presentation/pages/tdee_analytics_page.dart` for visual TDEE expenditure,
  flux range corridor, and goal anticipation analysis (routed via
  `AppRoutes.homeCaloriesAnalytics`).
- `debug/calorie_debug_menu_section.dart`, a debug-only list of dump actions
  that the Home side menu shows only in debug builds.

Other features should depend on domain types or complete widgets instead of
reassembling Calories internals. New calorie-owned side effects should live in
`application/` providers that react to owner feature state, instead of expanding
the legacy `provider/` surface or exposing action wrappers to sibling features.

## Providers

- New use-case providers live in `application/`.
- Repository providers live with repository implementations in `data/`.
  `CalorieLogRepositoryContract.cachedById` returns the last entry the
  repository read or wrote without a backend call; `calorieEntryById` uses it
  so the details sheet renders on its first frame.
- Saving an entry is optimistic. The repository and the inventory commit
  stores write through the Firestore local cache and do not wait for the
  server, so a save works offline and Firestore sends it later. Follow-up
  writes (skipped-day reset, product override, serving suggestion) run in
  the background.
- The feature-level `provider/` folder is legacy structure and currently holds
  calorie controllers and derived state. Do not add new provider files there
  unless working inside existing legacy code where moving would create
  unrelated churn.
- Providers use Riverpod code generation.

Main application providers:

- `application/calorie_weight_state_refresh.dart`
- `application/calorie_entry_delete_flow.dart`
- `application/calorie_inventory_entry_save_handler.dart`
- `application/tdee_analytics_provider.dart`
- `application/daily_nutrition_target_resolver_service.dart`

## TDEE Learning

Calories uses a pure intake and weight-trend model. The calculator profile
produces an initial TDEE from height, weight, age, sex, and selected activity level.
Goal mode and speed then apply deficit or surplus to create the initial daily target.

Health Connect is restricted strictly to body weight readings (`HealthDataType.weight`).
Wearable activity readings (steps, active calories burned) are decoupled from TDEE calculation.

### Calorie Cycling & Training Days

Users can configure training days (e.g. Mo, We, Fr) and a kcal offset (+200..+300 kcal).
The weekly budget is preserved budget-neutrally:

```text
N_training = count of training days
N_rest = 7 - N_training
offset_rest = (N_training * offset_training) / N_rest
trainingGoal = baseGoal + offset_training
restGoal = max(1200, baseGoal - offset_rest)
```

The diary header includes a toggle (`🏋️ Trainingstag`, `🛋️ Ruhetag`, `⏸️ Pausentag`).

### Learning Windows & Interpolation

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
newLearnedTdee = oldLearnedTdee * 0.70 + measuredTdee * 0.30
```

### Pause Days & Missing Days

- A day without logged entries or explicitly set to pause acts as a **Pausentag**.
- Pausentage (Urlaub, Krankheit, Wettkampf) are neutral: no streak penalty, ignored in learning.
- In a 7-day check-in window:
  - Missing/pause days (< 3 days) are auto-interpolated from the logged average of tracked days without blocking the check-in.
  - Check-in triggers every 7 days from the anchor start date.
  - >= 3 missing days blocks learning due to insufficient data.

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
