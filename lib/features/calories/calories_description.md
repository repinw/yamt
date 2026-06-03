# Calories Feature

`lib/features/calories` is the calorie and goal engine of the app. The feature
provides the domain models, persistence, Riverpod providers, UI building blocks,
and flows used by the diary to log food, calculate daily and weekly goals,
aggregate macros, include health data, and keep Burn Week in sync.

The main diary page itself lives in `lib/features/diary`, but it depends on
almost all of the data and widgets from this feature. In practice,
`features/calories` is a vertical domain area rather than a single page.

## What It Does

- Creates, edits, and deletes calorie entries.
- Groups entries by meal and sums daily calories and macros.
- Uses barcode, OCR, global catalog, OFF cache, or user override products as
  entry form prefills.
- Saves inventory-backed entries atomically with inventory consumption.
- Optionally restores deleted entries back into inventory or prepared meals.
- Sets daily calorie goals manually or through the calorie calculator.
- Calculates goals from BMR, TDEE, activity level, goal mode, and goal speed.
- Reads health activity and weight data, combines it with manual weight entries,
  and refreshes calorie-owned state after weight changes.
- Splits Total-TDEE into Base-TDEE for Health users and grants 75% of tracked
  activity as extra eatable calories.
- Creates, blocks, dismisses, or applies weekly check-ins that learn TDEE from
  intake, weight trend, and activity.
- Reuses learned TDEE day by day until newer data or a new weekly boundary can
  update it.
- Calculates 7-day carryover and flexible daily goals.
- Manages Burn Week with stars, hearts, protected days, and week sync.
- Prints debug dumps for calories, settings, and weekly check-ins.

## Folder Structure

`application/`

Coordinates use-case style flows that need multiple repositories or other
features:

- `calorie_inventory_entry_save_handler.dart`: Defines the calorie-owned save
  and pending-consumption discard ports used by inventory-backed entries.
- `calorie_entry_delete_flow.dart`: Deletes entries and can restore inventory
  items or prepared-meal portions through injected callbacks. If deletion fails
  after restore, the flow tries to roll the restore back.

`data/`

Contains Firestore repositories and contracts:

- `CalorieLogRepositoryContract` and `FirestoreCalorieLogRepository`: Read,
  stream, save, and delete `CalorieEntry` documents under
  `users/{uid}/calorie_entries/{entryId}`.
- `CalorieSettingsRepository` and `FirestoreCalorieSettingsRepository`: Read,
  stream, and save `CalorieGoalSettings` under
  `users/{uid}/calorie_settings/default`. Malformed or obsolete math documents
  decode as empty settings and are replaced by the next clean save.
- `CalorieProductCacheRepositoryContract` and
  `FirestoreCalorieProductCacheRepository`: Resolve product profiles by checking
  user overrides first, then the global catalog, then the OFF cache.
- `InventoryCalorieEntryCommitStore`: Performs the atomic Firestore commit for
  a calorie entry plus inventory update.
- `BurnWeekRunStateRepository`: Stores Burn Week state as a field on the user
  document.
- `calorie_product_image_url.dart`: Normalizes product image URLs.

`domain/`

Contains pure feature logic with no UI:

- `CalorieEntry`: A single diary entry with name, brand, meal, consumed amount,
  unit, nutrition per 100 g/ml, and calculated totals. It supports normal
  entries, prepared-meal bundle entries, and onboarding placeholder entries.
- `CalorieGoalSettings`: Current goal settings plus goal history, pending
  weekly check-in, skipped intake days, activity tracking start, and learned
  TDEE snapshots.
- `CalorieGoalCalculator`: Calculates BMR/TDEE from profile, activity level,
  and goal mode. Goals are clamped to a minimum of 1200 kcal.
- `CalorieBudgetCalculator`, `calorie_balance_cycle.dart`, and
  `calorie_carryover_history.dart`: Calculate daily budgets, carryover, and
  7-day goal runs.
- `CalorieWeeklyCheckInCalculator` and
  `calorie_weekly_window_resolver.dart`: Calculate measured TDEE from intake
  and weight trend, smooth it with EMA, and cap target movement.
- `DiaryActivitySummary` and `calorie_activity_adjustment.dart`: Normalize
  health data, remove expected activity from Total-TDEE targets, and credit
  tracked activity.
- `BurnWeekRunState` and `burn_week_mock_logic.dart`: Model Burn Week, hearts,
  stars, safe zones, and game-loop decisions.
- `CalorieProductProfile` and `CalorieScannedSourceRef`: Product data from
  barcode, OCR, OFF, global catalog, or user overrides.
- `diary_day_window.dart`: Central local-day normalization and 7-day window
  helpers.

`provider/`

Connects domain, data, and UI through Riverpod:

- `CalorieEntriesController`: Streams entries for the selected day, saves and
  deletes optimistically, serializes mutations, invalidates overview and weekly
  check-in data, and saves user product overrides after scans.
- `CalorieGoalController`: Streams and mutates `CalorieGoalSettings`. It sets
  manual goals, saves calculator goals, moves goal starts, marks skipped intake
  days, saves learned TDEE targets, and seeds missing start weight.
- `resolvedCalorieGoalForDayProvider`: Resolves the effective goal for a day
  from stored goal, learned TDEE, health activity, activity baseline, and the
  minimum goal floor.
- `calorieWeekOverviewProvider`: Builds the visible 7-day overview with daily
  goals, intake, carryover, heart days, and future goal starts.
- `calorieWeeklyCheckInDataProvider` and builder: Decide whether a weekly
  check-in is due, blocked, stale, or ready, and load intake, weight, and
  activity data.
- `CalorieWeeklyCheckInController`: Syncs pending check-ins, stores learned
  TDEE snapshots, dismisses check-ins, and refills Burn Week hearts.
- `dailyLearnedTdeeGoalForDayProvider`: Derives a learned target for a day from
  completed weekly windows.
- `BurnWeekRunController` and `burnWeekLiveSyncProvider`: Keep Burn Week synced
  across days and weeks, reset or restart runs, spend hearts, and invalidate
  dependent calculations.
- Small controllers like `calorieDayController`,
  `calorieVisibleWindowController`, and `calorieOverviewRevisionProvider` hold
  UI state and invalidation points.

`presentation/`

Contains pages, dialogs, models, and reusable widgets:

- `CalorieEntryEditorPage` checks auth and delegates to
  `CalorieEntryEditorContent`.
- `CalorieEntryEditorContent` owns the create, edit, and details flow. New
  entries are prefilled from product profile, inventory context, selected meal,
  and selected date. Existing entries can change meal/date or be returned to
  inventory.
- `CalorieEntryEditorDraft` owns text controllers, validation, and parsing.
- `CalorieEntryEditorFormScaffold` builds the manual entry form.
- `calorie_entry_details_view/` contains the details bottom-sheet components.
- Goal widgets such as `calorie_goal_calculator_sheet.dart`,
  `calorie_goal_calculator_flow.dart`, and
  `calorie_learned_tdee_goal_sheet.dart` implement goal setting and the
  calculator UI.
- Weekly check-in widgets show hints, dialogs, and status messages.
- Burn Week widgets show the live overview and diary pacing state.
- `*_l10n.dart` files localize enums such as meals and units.
- `calories_page_keys.dart` collects stable keys for widget tests.

`*.g.dart`

Generated Riverpod and JSON files. They should not be edited manually.

## Important Data Flows

### Creating Or Editing An Entry

1. The UI opens `CalorieEntryEditorPage`.
2. `CalorieEntryCreatePrefill` builds initial values from product profile,
   inventory context, meal type, and date.
3. `CalorieEntryEditorDraft` validates and parses form values.
4. `CalorieEntry.create` or `copyWith(...).recalculateTotals()` creates the
   domain object.
5. `CalorieEntriesController.saveEntry` updates the selected day's state
   optimistically.
6. Persistence goes directly through `CalorieLogRepository` or through
   `InventoryBackedCalorieEntrySaveFlow`.
7. After a successful write, skipped intake days are cleared, scan overrides are
   saved, weekly check-in snapshots are invalidated, overview providers are
   marked changed, and optional post-persist hooks run.

### Inventory-Backed Saving

1. The editor receives a `CalorieInventoryCreateContext` with
   `pendingConsumptionId`, item data, and restore amount.
2. `InventoryBackedCalorieEntrySaveFlow` looks up the pending consumption in the
   inventory controller.
3. `InventoryCalorieEntryCommitStore` writes the calorie entry and reduces the
   inventory item in one Firestore transaction.
4. The inventory controller then finalizes the pending consumption locally.

### Delete And Restore

1. `CalorieEntryDeleteFlow.canRestoreSource` checks whether the inventory item
   or prepared meal still exists.
2. If requested, the flow restores inventory or prepared meal portions first.
3. It then deletes the diary entry.
4. If deletion fails, the restore is rolled back when possible.
5. On success, weekly check-in snapshots from the affected day are marked dirty.

### Goal Calculation

1. Goals live in `CalorieGoalSettings` and keep a history.
2. Manual goals are saved through `setGoal`; calculator goals through
   `saveCalculatedGoal`.
3. `CalorieGoalCalculator` calculates BMR, TDEE, expected activity, goal
   adjustment, and final daily goal.
4. `resolvedCalorieGoalForDayProvider` decides the effective goal for each day:
   stored goal, learned TDEE, or 0/default, plus activity bonus and minimum
   floor.
5. `calorieWeekOverviewProvider` uses the resolved goal for the week strip,
   carryover, and flexible daily goals.

### Weekly Check-in And Learned TDEE

1. Weekly window start and length come from `CalorieWeeklyWindowResolver`.
   Partial starter days are handled explicitly.
2. The builder loads intake, skipped days, heart days, health/manual weight, and
   active calories.
3. Check-ins are blocked when too much intake is missing, weight points are
   missing, or data is unstable.
4. Heart days stay in the 7-day learning window as goal-kcal days.
5. `CalorieWeeklyCheckInCalculator` calculates weight trend, average intake,
   measured TDEE, smoothed TDEE, and the new target.
6. `CalorieWeeklyCheckInController` stores snapshots as
   `CalorieGoalWeeklyCheckInSnapshot`, dismisses pending check-ins, and refills
   Burn Week hearts.
7. Later diary edits invalidate snapshots through `inputHash` / `invalidatedAt`
   so stale learning is not silently reused.

### Burn Week

1. `BurnWeekRunState` stores current week, run number, stars, hearts, heart
   days, and missed-tracking flags.
2. `burnWeekLiveSyncProvider` watches week overview, day overview, settings,
   and run state, then queues needed sync, restart, or reset mutations.
3. `BurnWeekRunController` persists run changes and invalidates weekly
   check-ins when heart days change.
4. Burn Week uses the same calorie and goal values as the diary, but heart days
   count as protected days that satisfy the goal for weekly math and carryover.

## Integrations

- `features/diary`: Main consumer of calorie providers and many calorie widgets.
- `features/inventory`: Implements calorie-owned save/delete ports for quick
  eat, pending consumption, inventory restore, and prepared-meal bundles.
- `features/health`: Steps, workouts, active energy, health weight, and manual
  weight entries.
- `features/auth` and `features/household`: Provide the current user ID and
  inventory owner.
- `features/scanner` / product flows: Provide barcode/OCR profiles and
  `CalorieScannedSourceRef`.
- `lib/features/calories/debug`: Debug-only calorie dump tools and debug app-bar menu.

## Persistence Model

- Calorie entries:
  `users/{uid}/calorie_entries/{entryId}`
- Goal settings:
  `users/{uid}/calorie_settings/default`
- Burn Week state:
  `users/{uid}.burn_week_run_state`
- Global product catalog:
  `calorie_product_catalog/{barcode}`
- OFF cache fallback:
  `off_products/{barcode}`
- User product overrides:
  `users/{uid}/calorie_product_overrides/{barcode}`
- Inventory updates:
  `users/{inventoryOwnerUid}/inventory_items/{itemId}`

All Firestore reads normalize data through `normalizeFirestoreJson`, making
timestamps decode reliably into domain objects.

## Tests

`test/features/calories` mirrors the feature structure:

- Domain tests cover entry math, goal settings, budget, balance, weekly
  check-in, Burn Week, JSON converters, and onboarding catch-up.
- Data tests cover Firestore repositories, product cache, clean settings decode,
  and inventory commit.
- Provider tests cover entries, goal controller, resolved goals, week overview,
  balance summary, weekly check-ins, daily learned TDEE, and Burn Week sync.
- Presentation tests cover the editor, details sheets, goal and weekly check-in
  widgets, Burn Week widgets, and stable widget keys.

When changing feature logic, start with domain or provider tests. UI tests
mainly cover rendering, keys, and dialog behavior.
