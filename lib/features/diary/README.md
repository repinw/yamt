# Diary Feature

Diary owns the daily log page, date selection, quick-eat buttons, logged meals,
the daily budget card, and diary-facing Burn Week and weekly check-in
composition.

## Owns

- Diary page composition under `presentation/`.
- Diary date selection and other UI controllers under `presentation/`.
- Meal-section, nutrition, and balance adapters and the diary weekly
  check-in rules under `application/`.
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
- `presentation/widgets/diary_budget_card/` owns the daily budget card
  (#907): kcal and macro columns, the "Details" and "Nach Plan" chips, the
  training and pause toggles that set the day type through
  `DiaryDayTypeUpdater`, the ledger with the link to the budget sheet, the
  run week's day types, closing the day before, and the menu a long press
  opens (#928, in the sheet frame of `diary_dashboard/`): the pace marker
  switch and the parts of the day (`DiaryMealShares`, `DiaryMealTimes`,
  saved on the device), which also set the meal headings' kcal against
  each meal's part. `DiaryBudgetCardData` (`presentation/models/`) maps
  `DiaryBalanceCardData` and the day's macros for it;
  `diary_burn_week_card/diary_balance_card.dart` loads it.
- The diary page shows the Activity missing-weight prompt below the weekly
  check-in, and only on today.
- `presentation/widgets/diary_day_type_labels.dart` gives the emoji and the
  names of a day type. The Fortschritt tab uses them for its day rows.
- `presentation/diary_tab_change_flow.dart` (`diaryTabLeft`) is public UI
  for `features/home`: the home shell tells the diary when the user leaves
  its tab, and the diary selects today again (#753). A plan saved later in
  another tab still opens its day. After at least 5 minutes in the
  background, or on a new date, the diary page also returns to today; a
  shorter absence, such as a camera photo or a permission prompt, keeps the
  chosen day. A hidden diary pager jumps instead of sliding, since its muted
  ticker would hold the slide and undo a newer day later. When the earliest
  selectable day moves, for example when the plan loads after a cold start,
  the pager starts new pages on the selected day instead of jumping (#817).
- `presentation/widgets/diary_quick_eat_actions.dart`
  (`diaryQuickEatActions`) is public UI for `features/home`: the quick-eat
  actions for the selected day. The home shell shows them in its action panel
  when the "Essen" button in the middle of the bar is tapped. Its quick entry
  action opens `presentation/diary_quick_entry_page.dart`, which
  saves a calorie quick entry through the calories entry saver without an
  inventory item.
- `presentation/progress_photo_capture_flow.dart`
  (`showProgressPhotoCapture`) is public UI for `features/home` and
  `features/progress`: the sheet
  that adds a progress photo for a pose and a day, from the camera or the
  gallery, and saves it through the Health progress photo repository. It
  takes a preset pose and day and returns whether a photo was saved. Diary
  owns it because the weekly check-in adds photos too: its photo step shows
  the first, a middle, and today's photo of a pose since the goal start.
  `presentation/widgets/progress_photo_frame.dart` (`ProgressPhotoFrame`) is
  public UI for `features/progress` too: one decrypted photo in a portrait
  frame. So is `progressPhotoPoseLabel` in
  `presentation/widgets/progress_photo_capture_sheet.dart`, the name of a
  pose.
- `presentation/widgets/diary_budget_card/diary_budget_line.dart`
  (`DiaryBudgetLine`) is public UI for `features/settings`: the eaten,
  planned and over parts of a budget line. The color editor of the design
  "Individuell" draws its diary preview with it, so the preview bars look
  like the card's.
- `presentation/widgets/diary_budget_card/diary_budget_view_switch.dart`
  (`DiaryBudgetViewSwitch`, "Übrig | Gegessen") and
  `presentation/widgets/diary_budget_card/diary_budget_day_type_buttons.dart`
  (`DiaryBudgetDayTypeButtons`, training and pause) are public UI for
  `features/settings` too: plain widgets without controllers, which the
  same preview shows at the top of its budget card.
- `presentation/widgets/diary_meals_empty_state.dart` points to the "Essen"
  button on a day without logged food.
- `presentation/widgets/diary_burn_week_card/diary_balance_card.dart` loads
  the day's balance and macros and shows them in the budget card
  (`diary_budget_card/`), or the loading skeleton and the retry content.
- `presentation/diary_home_widget_summary_provider.dart`
  (`diaryHomeWidgetSummaryProvider`) with its value type
  `application/diary_home_widget_summary.dart` (`DiaryHomeWidgetSummary`) is
  a narrow, flat summary of today's dashboard built for
  `features/home_widget`. The provider sits in `presentation/` because it
  derives from the dashboard controller's state. It carries eaten
  and target kcal from the same daily metrics as the balance card, plus the
  macro bars. It hides the calorie-log and Burn Week internals
  `DiaryDayDashboardData` carries; `home_widget` reads only this provider,
  never the dashboard controller directly. It stays `null` until the data key
  is ready: the app starts the home widget sync during the splash, and
  without the key today's dashboard would load zeros and save them over the
  last good numbers. Once signed out it is all zeros, so the widget drops the
  last account's numbers.

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
  data reloads. "Ziel ändern" closes the sheet for the Calories new-goal
  sheet; when that closes without a new goal, the section opens the check-in
  again and keeps the sheet controller alive in between, so the step and the
  choices stay.
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
- `application/diary_weekly_checkin_provider.dart` (diary rules over the
  calorie check-in data: reached goal, latest weight, missing weight)
- `application/diary_provider_warmup.dart`
- `application/diary_quick_eat_inventory_provider.dart`
- `presentation/diary_home_widget_summary_provider.dart` (public, read by
  `features/home_widget`)
- `application/diary_plan_start_day_provider.dart` (earliest selectable diary day)
- `application/diary_day_type_provider.dart` (training/normal/pause status and
  updates through the calorie goal controller)
- `data/diary_day_dashboard_cache_repository.dart`
- `presentation/controllers/diary_day_dashboard_controller.dart`
- `presentation/controllers/diary_balance_details_controller.dart` (quiet or
  detailed daily card; not saved, closed after a restart)
- `presentation/diary_calendar_controller.dart` (selected day and
  `diaryCalendarBoundsProvider`; range rules in `domain/diary_calendar_bounds.dart`)

## Accepted Dependencies

- `core` for local day math, routes, theme tokens, and shared widgets.
- `features/activity` for the complete activity and weight diary section, the
  missing-weight prompt, and the Activity-owned weight tracking flow.
- `features/calories` for calorie log data, goal settings, Burn Week state, and
  the weekly check-in, read and changed through the calorie check-in
  providers and `CalorieWeeklyCheckInController`. The weekly
  check-in sheet opens the public new-goal sheet
  (`presentation/widgets/calorie_new_goal_flow.dart`) for "Ziel ändern" and
  when the active goal was reached. The entry details page saves its changes through
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
