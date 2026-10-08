# Diary Feature

Diary owns the daily log page, date selection, quick-eat buttons, logged meals,
nutrition bars, and diary-facing Burn Week and weekly check-in composition.

## Owns

- Diary page composition under `presentation/`.
- Diary date selection and other UI controllers under `presentation/`.
- Meal-section, nutrition, balance, and weekly-check-in adapters under
  `application/`.
- Diary dashboard cache persistence under `data/`.
- Diary-owned value objects under `domain/`.

## Does Not Own

- Raw calorie storage, goal calculation, or Burn Week persistence.
- Health Connect infrastructure or raw health services.
- Inventory storage, prepared meal storage, or inventory mutation logic.
- Home shell navigation chrome.

## Public Edge

- `presentation/diary_page.dart` is the main page.
- `presentation/widgets/diary_meals_section.dart` owns the meals logged on the
  selected day. Identical foods in one meal are
  merged into one row (`domain/diary_meal_entry_group.dart`) that expands to
  its single entries. Rows that open one entry tag their image with
  `HeroTags.loggedEntryImage`, so it flies into the entry details page.
- `presentation/diary_entry_details_page.dart` (`DiaryEntryDetailsPage`,
  routed at `AppRoutes.homeCaloriesEntryDetailsPath`) shows one logged entry
  in the food label look of the Inventory eat page: header, nutrition label
  for the eaten amount, and the amount ruler. The confirm button saves a
  changed amount and closes the page; a move to another meal or day, "log
  again", and remove save at once, each with an undo. Changes run through
  `DiaryEntryDetailsFlow`; a changed amount goes through the Inventory
  `InventoryEntryAmountService`, so the stock follows in the same write.
  Remove runs through `DiaryEntryDeleteFlow`, which asks whether an entry
  that took stock gives it back to the Vorrat. Both use
  `DiaryEntryChangeController`. Bundles (prepared meals and combined foods) show their foods
  instead of the ruler.
- `presentation/widgets/diary_macro_strip/` owns the compact kcal and macro
  strip pinned under the top bar. `diary_macro_strip_trigger.dart` reveals it
  in stages as the daily card's kcal bar and macro bars scroll away; each day
  view places the trigger sliver directly above its daily card.
- The diary page shows the Activity missing-weight prompt below the weekly
  check-in, and only on today.
- `presentation/widgets/diary_day_type_labels.dart` gives the emoji and the
  names of a day type. The Fortschritt tab uses them for its day rows.
- `presentation/widgets/diary_quick_eat_actions.dart`
  (`diaryQuickEatActions`) is public UI for `features/home`: the quick-eat
  actions for the selected day. The home shell shows them in its action panel
  when the "Essen" button in the middle of the bar is tapped. Its quick entry
  action opens `presentation/diary_quick_entry_page.dart`, which
  saves a calorie quick entry through the calories entry saver without an
  inventory item.
- `presentation/widgets/diary_meals_empty_state.dart` points to the "Essen"
  button on a day without logged food.
- `presentation/widgets/diary_burn_week_card/diary_balance_card.dart` owns the
  diary-facing daily calorie balance UI.
  The daily card uses the food label look (`FoodLabelColors`, `AppFonts`)
  without a frame: a big kcal-left number, a ruler with four equal quarters,
  and the macro rows. It is quiet by default (kcal and grams left only) and
  shows all numbers after a tap. Over the target it shows the overage with an
  "Over goal" label in the error color.
- `presentation/diary_home_widget_summary_provider.dart`
  (`diaryHomeWidgetSummaryProvider`) with its value type
  `application/diary_home_widget_summary.dart` (`DiaryHomeWidgetSummary`) is
  a narrow, flat summary of today's dashboard built for
  `features/home_widget`. The provider sits in `presentation/` because it
  derives from the dashboard controller's state. It carries eaten
  and target kcal from the same daily metrics as the balance card, plus the
  macro bars. It hides the calorie-log and Burn Week internals
  `DiaryDayDashboardData` carries; `home_widget` reads only this provider,
  never the dashboard controller directly.

Other features should compose the page or complete widgets instead of wiring
Diary application providers directly. `diaryHomeWidgetSummaryProvider` above
is the one accepted exception, for `features/home_widget`.

- `presentation/widgets/diary_weekly_checkin_sheet/` owns the weekly check-in
  as a tall bottom sheet in three steps: the review since the goal start with
  the choice between the measured and the previous TDEE, the training days of
  the next run (Calories `TrainingDayChips` and `TrainingWeekDepotChart`), and
  the new targets. "Woche starten" saves the training days of the run, then
  applies or rejects the check-in, in one Calories controller action. A reached goal shows its own page and asks for
  a new goal. The sheet controller keeps the step and the choices while the
  data reloads.
- `presentation/widgets/diary_weekly_checkin_preview_tiles.dart`
  (`DiaryWeeklyCheckInPreviewTiles`) are debug entries for the Home side menu.
  They open the weekly check-in sheet for the latest completed window, or for
  demo data without one, and save nothing. The Home menu shows them in its
  collapsed debug section.

## Providers

- Application providers live in `application/`.
- Cache/data providers live in `data/`.
- Controllers live in `presentation/` next to the UI state they own.
- Diary does not use a feature-level `provider/` folder.
- Providers are generated with `@riverpod`; there are no new manual providers.

Main application adapters and mappers:

- `application/diary_day_dashboard_mappers.dart`
- `application/diary_balance_provider.dart`
- `application/diary_weekly_checkin_provider.dart`
- `application/diary_provider_warmup.dart`
- `application/diary_quick_eat_inventory_provider.dart`
- `presentation/diary_home_widget_summary_provider.dart` (public, read by
  `features/home_widget`)
- `application/diary_plan_start_day_provider.dart` (earliest selectable diary day)
- `application/diary_day_type_provider.dart` (training/rest/pause status and
  updates through the calorie goal controller)
- `data/diary_day_dashboard_cache_repository.dart`
- `presentation/controllers/diary_day_dashboard_controller.dart`
- `presentation/controllers/diary_balance_details_controller.dart` (quiet or
  detailed daily card and macro strip; saved in `AppPreferences`)
- `presentation/diary_calendar_controller.dart` (selected day and
  `diaryCalendarBoundsProvider`; range rules in `domain/diary_calendar_bounds.dart`)

## Accepted Dependencies

- `core` for diary day normalization, routes, theme tokens, and shared widgets.
- `features/activity` for the complete activity and weight diary section, the
  missing-weight prompt, and the Activity-owned weight tracking flow.
- `features/calories` for calorie log data, goal settings, Burn Week state, and
  weekly check-in behavior through Diary application adapters. The weekly
  check-in sheet opens the public new-goal sheet
  (`presentation/widgets/calorie_new_goal_flow.dart`) when the active goal was
  reached. The entry details page saves its changes through
  the Calories `calorieEntrySaverProvider`.
- `features/health` for connection status and connection actions through
  `health_connection_actions.dart`.
- `features/inventory` for repository-backed quick-eat data, the public
  Inventory presentation flows used to complete inventory and manual-product
  entries, and the public eat page widgets of the entry details page.
- `core/widgets` for optional shell chrome when the diary page is embedded.

Keep these dependencies at page, application adapter, or complete-section
boundaries. Do not make callers assemble another feature's internal widgets and
providers.

## Tests

- `test/features/diary/application/`
- `test/features/diary/presentation/`
