# Diary Burn Week Behavior

This note captures the first-version diary behavior for the new Balance UI.

## Carryover

- Carryover is not clamped to zero. If earlier days are far above target, the
  diary may show a negative amount left for the current day.
- Carryover resets at the start of each 7-day run. Old overflow does not keep
  dragging later runs down forever.
- During the first 7-day run without a learned TDEE, the user is learning the
  routine. The diary keeps showing the real balance, but game recovery controls
  and run-over dialogs stay hidden.

## First Week

- The first week is a learning week only while YAMT has no learned TDEE yet.
- Users should eat normally and track as completely as possible.
- Food, drinks, and weight entries matter because the weekly estimate depends on
  consistent data.
- Seven days are enough to improve the initial estimate, but not enough for a
  perfect picture. Fourteen days of consistent tracking gives a clearer view of
  the user's metabolism.
- If the user already completed week 1 and YAMT has a learned TDEE, changing the
  goal starts the next run in normal week-2 behavior. The intro stays hidden and
  Burn Week controls are available from the start day.

## Diary Intro

The first diary opening should explain:

- the estimated maintenance calories from the calculator profile,
- how the selected goal adjusts that estimate,
- the initial daily target,
- why accurate tracking is important,
- why 7 days improve the estimate and 14 days are better.

Do not mention recovery hearts in this intro. They are introduced after the
first week.
