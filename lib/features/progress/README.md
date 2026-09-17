# Progress Feature

Progress is the home tab that shows how the week and the longer trend are
going, so the diary can stay focused on today.

## Owns

- `presentation/progress_page.dart`, the Progress home tab.

## Does Not Own

- Calorie, weight, or activity data and their calculations.
- The weekly progress card itself (owned by Diary) and the TDEE analytics page
  (owned by Calories).
- Home shell navigation chrome.

## Public Edge

- `presentation/progress_page.dart` (`ProgressPage`), routed at
  `AppRoutes.homeProgress` as a home shell branch.

## Providers

Progress owns no providers. It reads the current day from `clockProvider` in
`lib/core/provider/`.

## Dependencies

- `core` for routes, layout tokens, the clock, and shell chrome.
- `features/diary` for `DiaryWeeklyProgressSection`.
- The TDEE analytics page of `features/calories`, opened by route only.

## Tests

- `test/features/home/home_page_test.dart` covers the tab and its position.
- `test/core/router/app_router_test.dart` covers navigation to the tab.

## Legacy

None.
