# Progress Feature

## Purpose

Progress is the Fortschritt home tab. It shows how the current goal, the
week, and the longer trends are going, so the diary can stay focused on today.

## Owns

- The Fortschritt tab page and its sections: the current goal with the way to
  the goal archive, the 7-day run with its week budget and one bar per day,
  the weight trend of four weeks with the goal forecast, the TDEE per
  confirmed weekly check-in, and training days against rest days.
- The read models of these sections in `domain/` and the providers that build
  them from calorie and weight data in `application/`.

## Does Not Own

- Calorie entries, goal settings, weekly check-ins, and the learned TDEE
  (Calories). Which check-ins count as confirmed is decided by
  `CalorieTdeeHistory` in Calories.
- Weight data and the trend weight (Health).
- The goal archive page and the TDEE analytics page (Calories).
- Home shell navigation chrome.

## Rules

- The day bars and the week budget split the eaten kcal by the kcal share of
  protein, carbohydrates, and fat, in the macro colors. The part over the goal
  is hatched.
- Averages count only past or current days with entries that are no pause
  days. The training and rest day comparison covers the 28 days before today.
- A TDEE point appears only after the user decided on the weekly check-in. A
  declined check-in keeps the previous TDEE and shows the calculated value as
  a hollow point.
