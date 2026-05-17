# Diary Feature

Diary owns the daily log page, date selection, meal sections, nutrition bars,
and diary-facing Burn Week and weekly check-in composition.

## Owns

- Diary page composition under `presentation/`.
- Diary date selection and other UI controllers under `presentation/`.
- Meal-section, nutrition, balance, and weekly-check-in adapters under
  `application/`.
- Diary-owned value objects under `domain/`.

## Does Not Own

- Raw calorie storage, goal calculation, or Burn Week persistence.
- Health Connect infrastructure or raw health services.
- Inventory storage, prepared meal storage, or inventory mutation logic.
- Home shell navigation chrome.

## Public Edge

- `presentation/diary_page.dart` is the main page.
- `presentation/widgets/diary_meals_section.dart` owns diary meal cards.
- `presentation/widgets/diary_burn_week_card/diary_balance_card.dart` owns the
  diary-facing daily and weekly calorie balance UI.

Other features should compose the page or complete widgets instead of wiring
Diary application providers directly.

## Providers

- Application providers live in `application/`.
- Controllers live in `presentation/` next to the UI state they own.
- Diary does not use a feature-level `provider/` folder.
- Providers are generated with `@riverpod`; there are no new manual providers.

Main application adapters:

- `application/diary_entries_provider.dart`
- `application/diary_meal_sections_provider.dart`
- `application/diary_nutrition_bars_provider.dart`
- `application/diary_balance_provider.dart`
- `application/diary_weekly_checkin_provider.dart`
- `application/diary_intro_trigger_provider.dart`
- `application/diary_provider_warmup.dart`
- `application/diary_quick_eat_inventory_provider.dart`

## Accepted Dependencies

- `core` for diary day normalization, routes, theme tokens, and shared widgets.
- `features/activity` for the complete activity and weight diary section.
- `features/calories` for calorie log data, goal settings, Burn Week state, and
  weekly check-in behavior through Diary application adapters.
- `features/health` for connection status needed by intro flows.
- `features/inventory` for quick-eat inventory and prepared-meal flows through
  Inventory's public presentation flow APIs and Diary application adapters.
- `core/widgets` for optional shell chrome when the diary page is embedded.

Keep these dependencies at page, application adapter, or complete-section
boundaries. Do not make callers assemble another feature's internal widgets and
providers.

## Tests

- `test/features/diary/application/`
- `test/features/diary/presentation/`
