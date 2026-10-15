# Health Feature

## Purpose

Health owns platform health access, Health Connect permission state, health
weight samples, manual fallback weight entries, and the user's progress
photos. From the platform it reads only weight.

## Owns

- Health platform services and repositories under `data/`.
- Health connection and weight domain models under `domain/`.
- Health weight samples synced to the cloud (`health_weight_samples`,
  encrypted with the data key): every measurement once, keyed by a hash of
  its minute and weight that only the data key can produce, so devices that
  read the same scale store it once.
- The trend weight: one daily weight from manual entries and Health samples,
  interpolated between weigh-ins and smoothed, so water swings do not show as
  weight changes.
- The health connection state and the manual weight entries under
  `application/`. Both are state-holding controllers that later features read
  and mutate: the connection state carries the connect, install, permission
  settings, and disconnect actions; the manual weight entries carry save and
  delete, which fall back to manual storage when Health is not ready and
  refresh the recent weight trend.

- Progress photos: body photos per day and pose, end-to-end encrypted. Each
  file has its own key, kept in the sealed photo document.

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
- A day holds one progress photo per pose; a new one replaces the old. The
  weight typed for a photo stays on the photo and is never a weight entry.
- Progress photos are never shared with the household. Decrypted image bytes
  stay in memory and never reach a disk cache.
