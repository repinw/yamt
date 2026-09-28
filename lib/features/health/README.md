# Health Feature

## Purpose

Health owns platform health access, Health Connect permission state, health
weight samples, and manual fallback weight entries. It reads only weight.

## Owns

- Health platform services and repositories under `data/`.
- Health connection and weight domain models under `domain/`.
- The trend weight: one daily weight from manual entries and Health samples,
  interpolated between weigh-ins and smoothed, so water swings do not show as
  weight changes.
- The health connection state and the manual weight entries under
  `application/`. Both are state-holding controllers that later features read
  and mutate: the connection state carries the connect, install, permission
  settings, and disconnect actions; the manual weight entries carry save and
  delete, which fall back to manual storage when Health is not ready and
  refresh the recent weight trend.

## Does Not Own

- Calorie goal settings, weekly check-in state, or calorie refresh behavior.
- Diary page composition.
- App authentication flows.

## Rules

- Health has no presentation layer. Later features render the connection
  state and the weights themselves.
- Health must not depend on Calories. Calories and Activity own the calorie
  refresh and weekly check-in side effects of weight changes.
- Saving a manual weight writes to Health when access is ready and clears the
  fallback entry of that day; otherwise the entry stays in the fallback
  repository. A save or delete refreshes the recent weight trend.
