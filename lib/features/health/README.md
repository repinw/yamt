# Health Feature

Health owns platform health access, Health Connect permission state, raw health
activity data, health weight samples, and manual fallback weight entries.

## Owns

- Health platform services and repositories under `data/`.
- Health connection, activity, workout, energy, and weight domain models under
  `domain/`.
- Health connection and manual weight controllers under
  `presentation/controllers/`.

## Does Not Own

- Calorie goal settings, weekly check-in state, or calorie refresh behavior.
- Diary page composition or activity card layout.
- App authentication flows.

## Public Edge

- `presentation/controllers/health_connection_controller.dart`
- `presentation/controllers/manual_health_weight_entries_controller.dart`
- Service providers in `data/` for health connection, diary health data, health
  weight samples, and manual weight fallback storage.
- Domain models in `domain/` used by Activity, Calories, Diary, and Settings.

Other features may consume these public controllers, providers, services, and
domain types directly. Calorie-owned side effects from health changes belong in
the consuming calorie or activity application layer.

## Providers

- Repository and service providers live in `data/`.
- Controllers live in `presentation/controllers/`.
- Providers use Riverpod code generation.

Main providers:

- `data/diary_health_service_provider.dart`
- `data/health_connection_service_provider.dart`
- `data/health_weight_service_provider.dart`
- `data/manual_health_weight_repository_provider.dart`
- `presentation/controllers/health_connection_controller.dart`
- `presentation/controllers/manual_health_weight_entries_controller.dart`

## Accepted Dependencies

- `core` for preferences, Firestore infrastructure, and local day helpers.
- `features/auth` for scoping Firestore manual weight entries to the current
  user.

Health must not depend on Calories. Calories and Activity own calorie-specific
refresh or weekly check-in side effects caused by health and weight changes.

## Tests

- `test/features/health/data/`
- `test/features/health/domain/`
- `test/features/health/presentation/controllers/`
