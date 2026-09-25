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
  `HeroTags.loggedEntryImage`, so it flies into the Calories details sheet.
- `presentation/widgets/diary_macro_strip/` owns the compact kcal and macro
  strip pinned under the top bar. `diary_macro_strip_trigger.dart` reveals it
  in stages as the daily card's kcal bar and macro bars scroll away; each day
  view places the trigger sliver directly above its daily card.
- `presentation/widgets/diary_weekly_progress_section.dart` is the weekly
  budget, activity, and weight card. The Progress tab shows it; the diary page
  does not. The diary page shows only the Activity missing-weight prompt, below
  the weekly check-in, and only on today.
- `presentation/widgets/diary_quick_eat_dock.dart` (`DiaryQuickEatDock`) is
  public UI for `features/home`: the quick-eat buttons for the selected day.
  The home shell shows it in the floating action button slot of the diary tab,
  so it moves with the bottom navigation bar. The day view pads its content by
  `diaryQuickEatDockHeight`.
- `presentation/widgets/diary_burn_week_card/diary_balance_card.dart` owns the
  diary-facing daily and weekly calorie balance UI.
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

## Providers

- Application providers live in `application/`.
- Cache/data providers live in `data/`.
- Controllers live in `presentation/` next to the UI state they own.
- Diary does not use a feature-level `provider/` folder.
- Providers are generated with `@riverpod`; there are no new manual providers.

Main application adapters and mappers:

- `application/diary_entries_provider.dart`
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
- `data/diary_day_dashboard_cache_store.dart`
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
  check-in dialog opens the public new-goal sheet
  (`presentation/widgets/calorie_new_goal_flow.dart`) when the active goal was
  reached.
- `features/health` for connection status and connection actions through
  `health_connection_actions.dart`.
- `features/inventory` for repository-backed quick-eat data and the public
  Inventory presentation flows used to complete inventory and manual-product
  entries.
- `core/widgets` for optional shell chrome when the diary page is embedded.

Keep these dependencies at page, application adapter, or complete-section
boundaries. Do not make callers assemble another feature's internal widgets and
providers.

## Tests

- `test/features/diary/application/`
- `test/features/diary/presentation/`
