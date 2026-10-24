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
  read the same scale store it once. Each copy lists, encrypted, the devices
  (install ids) whose Health store holds it. A sync mirrors deletions of the
  last 30 days: a copy loses the device whose Health no longer has it, and
  is deleted once no device holds it. Installs that recorded no app version
  in 30 days (`users/{uid}/clients`) no longer hold copies, so a reinstall
  does not keep old weights. A weight deleted in the app loses its copy at
  once. Older copies stay, because Health may
  not return older samples. The sync starts the day before the first goal,
  so without a goal (onboarding always sets one) only manual weights count. Every weight reader reads these
  samples, not the local Health store, through `weightSeriesProvider`: all
  manual weights and samples of a day count as their median. A failed read
  is an error, which the readers show. `latestWeighingKgProvider` gives the
  newest single weighing.
- Every weighing is its own entry: a manual one has a uuid id, one saved
  with Health is its own Health record. The cloud copy
  (`data/health_weight_sample_dto.dart` encodes it) has an ignored flag that
  applies on all devices (`setIgnored`). An app weight can only be changed on
  the device whose Health store holds it
  (`application/health_app_weight_service.dart`).
- `HealthConnectionService.openHealthApp` opens the Health app.
- The trend weight: one daily weight from manual entries and Health samples,
  interpolated between weigh-ins and smoothed, so water swings do not show as
  weight changes.
- The health connection state and the manual weight entries under
  `application/`. Both are state-holding controllers that later features read
  and mutate: the connection state carries the connect, install, permission
  settings, and disconnect actions; the manual weight entries carry add, update,
  and delete per entry, which fall back to manual storage when Health is not ready,
  and the ignore of a Health weighing (`setIgnored`).

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
- Saving a manual weight writes to Health when access is ready; otherwise
  the entry stays in the fallback repository. A Health save never clears the
  manual entries of the day. A weight saved to Health also goes to the cloud at once, so
  readers count it before the next sync. The recent weight trend follows
  the manual entries and the cloud samples by itself.
- A day holds one progress photo per pose; a new one replaces the old. The
  weight typed for a photo stays on the photo and is never a weight entry.
- Progress photos are never shared with the household. Decrypted image bytes
  stay in memory and never reach a disk cache.
