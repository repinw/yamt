# Diary Quick Eat Menu Plan

## Summary

- Add a `+` button to each diary meal category.
- The `+` opens a compact anchored up/down menu like the inventory FAB menu,
  not a large sheet.
- Menu actions: inventory, barcode scan, manual search, KI.
- Do not offer receipt scan from diary.

## Key Changes

- Add `DiaryMealQuickAddMenu` in the diary meal card header.
- Use compact anchored menu behavior:
  - opens near the `+` button
  - expands up or down based on space
  - shows icon plus short localized label per action
  - closes when the user taps outside
- Add `DiaryQuickEatFlow.openSource(...)` for selected quick-eat action.
- Inventory action opens a picker for available inventory items and prepared
  meals.
- Barcode, manual search, and KI reuse the existing eat-now flow with a
  quick-eat-only mode.
- Add manual-add route args:
  - `initialAction`
  - `quickEatOnly`
  - `preselectedMealType`
  - `preselectedLoggedAt`
- Add barcode as an initial manual-add action.
- Keep existing inventory FAB and manual-add behavior unchanged.

## Behavior

- Category `+` preselects that meal type and the selected diary day.
- Selected day logs with current time on that date.
- Future selected dates clamp to today.
- Quick-eat-only mode hides inventory/store buttons.
- Manual search, barcode, and KI default to Eat.
- Successful log returns to diary and refreshes meal/nutrition providers.

## Tests

- Diary meal test: every category has `+`; tapping it opens the compact menu
  and does not toggle the meal card.
- Menu test: shows inventory, barcode, manual search, and KI; does not show
  receipt actions.
- Inventory picker test: lists available inventory items and prepared meals,
  filters depleted ones.
- Flow tests: selected meal/date is passed into inventory item, prepared meal,
  manual search, barcode, and KI flows.
- Manual add tests: quick-eat-only hides Inventory action and barcode can start
  directly.
- Run `flutter gen-l10n` and targeted Flutter tests.

