# Progress Feature

## Purpose

Progress is the Fortschritt home tab. It shows how the current goal, the
week, and the longer trends are going, so the diary can stay focused on today.

## Owns

- The Fortschritt tab page with its two scopes, "Aktuelles Ziel" and
  "Gesamt", and its sections: the current goal with the way to the goal
  archive, the progress photos (before and after, all photos grouped by goal,
  the slider comparison, and one photo in full size with its edits: replace,
  move to another day or pose, delete), the 7-day run with its week budget and one bar
  per day, the weight trend with the goal forecast, the TDEE per confirmed weekly check-in, and
  training days against rest days.
- The weight list (`ProgressWeightsPage`), opened from the weight section
  and from the profile's weight card: every weighing with day, time, weight,
  and source, grouped by 7-day runs, under the change of the trend and a chart
  with the goal weight. A tap on a weighing opens the edit sheet (own
  weighing: weight, day, time, delete) or the info sheet (ignore or count
  again; open in Health for other apps). An own Health weight saved by another
  device is view-only with a hint. Ignored weighings show greyed out and as
  hollow chart points. Chips switch between the current goal, the last four
  weeks, and all goals. Without Health, a card offers to connect it until the
  user dismisses it; then a small header icon does.
- The read models of these sections in `domain/` and the providers that build
  them from calorie and weight data in `application/`.
- The weight entry of the tab's action button: adds a weighing for today,
  filled with the newest single weighing (not the chart's last weigh-in). It saves through the diary weight flow of
  Activity, so every section that depends on the weight refreshes.

## Does Not Own

- Calorie entries, goal settings, weekly check-ins, and the learned TDEE
  (Calories). Which check-ins count as confirmed is decided by
  `CalorieTdeeHistory` in Calories.
- Weight data and the trend weight (Health).
- Storing, encrypting, and deleting progress photos (Health), the photo
  capture sheet and the photo frame (Diary).
- The goal archive page and the TDEE analytics page (Calories).
- Home shell navigation chrome.
- The weight dialog and saving a weight (Activity).
- Storing, changing, and ignoring weighings (Health); Progress only starts
  these actions from the weight list.

## Public UI

- `presentation/progress_weight_entry_flow.dart` (`showProgressWeightEntry`):
  the weight entry that the home shell's action button opens on the
  Fortschritt tab.

## Rules

- A progress photo shows the weight typed with it, else the trend weight of
  its day. Photos belong to the goal whose start is the latest one on or
  before their day; photos before the first goal form their own group.

- The day bars and the week budget split the eaten kcal by the kcal share of
  protein, carbohydrates, and fat, in the macro colors. The part over the goal
  is hatched.
- "Aktuelles Ziel" covers the current goal from its start; "Gesamt" covers
  all goals from the start of the first one and hides the goal card and the
  run. Charts cover at least 7 days, so a goal that just started still shows
  a trend. A dashed line marks each goal start inside a chart.
- Averages count only past or current days with entries that are no pause
  days. The training and rest day comparison ends the day before today.
- A TDEE point appears only after the user decided on the weekly check-in. A
  declined check-in keeps the previous TDEE and shows the calculated value as
  a hollow point.
