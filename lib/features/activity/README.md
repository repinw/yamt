# Activity Feature

Activity owns the diary-facing activity, steps, workouts, and weight surfaces.
It exposes complete widgets that other features can compose without wiring the
Activity providers themselves.

## Owns

- Activity, steps, workouts, and weight diary widgets under `presentation/`.
- Activity and weight value objects under `domain/`.
- Activity and weight aggregation services under `application/`.
- Riverpod providers that load Activity-owned application data.

## Does Not Own

- Health Connect infrastructure, permissions, and raw health services.
- Calorie goal calculation or calorie check-in state.
- Diary page ordering, meals, or date navigation.

## Public Edge

- `presentation/widgets/activity_weight_section/diary_activity_weight_section.dart`
  is the main diary section for activity, weight, and steps.
- `presentation/diary_weight_tracking_flow.dart` opens the Activity-owned
  diary weight entry flow for callers that already know which day needs weight.
- Dedicated cards under `presentation/widgets/` may be used by Activity tests
  and Activity-owned composition.

Other features should prefer the complete section widget instead of importing
Activity sub-widgets or Activity providers directly.

## Providers

- Application providers live in `application/`.
- Widget-only state belongs in `presentation/` next to the widget/controller
  that owns it.
- Activity does not use a feature-level `provider/` folder.

Current application providers:

- `application/diary_activity_weight_data_provider.dart`
- `application/diary_steps_summary_provider.dart`
- `application/diary_activity_weight_service.dart`
- `application/diary_weight_actions.dart`
- `application/diary_health_connect_action_provider.dart`

## Accepted Dependencies

- `core` for diary day normalization and shared primitives.
- `features/auth` for scoping local weight-prompt dismissal state to the active
  user when auth is available.
- `features/health` for health access, day activity data, workouts, and weight
  samples.
- `features/calories` for calorie profile inputs and calorie-owned weight state
  refresh.

Keep these dependencies at the Activity provider or action boundary. UI callers
should not have to assemble them.

## Tests

- `test/features/activity/application/`
- `test/features/activity/presentation/widgets/`
