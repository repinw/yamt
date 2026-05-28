# Project Architecture & Codex Guidelines

This document is the general architecture source of truth for this Flutter
project. Read it before generating or modifying code that changes feature
boundaries, state ownership, providers, UI composition, or shared abstractions.

This file defines rules and patterns. It must not become a catalog of concrete
features. Feature-specific responsibilities, public entry points, provider
lists, and dependency notes belong in that feature's `README.md`.

## Core Pattern

The project uses feature-first architecture with pragmatic Clean Architecture
layers and Riverpod-managed MVVM.

- State management and dependency injection use Riverpod code generation
  exclusively (`riverpod_annotation`).
- Always use the `@riverpod` annotation for providers and controllers.
- Do not use legacy manual providers such as `StateProvider` or
  `StateNotifierProvider`.
- Every annotated provider/controller file must include the generated part file
  (`part 'filename.g.dart';`).
- UI widgets should stay presentation-focused. They may hold local UI state,
  lifecycle hooks, scroll state, and animation state, but business rules and
  data aggregation belong in providers, controllers, services, or state
  classes.
- MVVM is the conceptual pattern, but state-management classes are named
  `Controller`, not `ViewModel`.
- Prefer direct, explicit imports of concrete files. Do not add hand-written
  barrel export files or barrel classes.
- Generated `part` files such as `*.g.dart` and `*.freezed.dart` are allowed.
  Hand-written `part` files are not.

## Feature Layout

Feature code lives under `lib/features/<feature>/`.

Common feature folders:

```text
lib/features/<feature>/
├── README.md       # feature-specific ownership and usage notes
├── data/           # repositories, DTOs, API/client implementations
├── domain/         # feature-owned entities, value objects, pure helpers
├── application/    # use-case/services that aggregate domain and data inputs
└── presentation/   # pages, widgets, controllers, UI-only helpers
```

Not every feature needs every folder. Add folders only when the feature has
code that naturally belongs there.

## Feature README

Feature-specific architecture belongs in `lib/features/<feature>/README.md`.
Use the README for:

- what the feature owns
- what the feature explicitly does not own
- public widgets/pages/controllers other features may use
- important providers and where they live
- accepted cross-feature dependencies
- tests that cover the feature
- migration notes for legacy structure

Keep this root architecture file generic. If a rule only applies to one feature,
document it in that feature's README.

## Core

`lib/core` is for feature-independent primitives only:

- app-wide constants and layout tokens
- app theme and theme extensions
- generic reusable widgets
- routing and infrastructure
- small domain helpers with no feature dependency

Do not move feature-specific models into `core` just to avoid thinking about
ownership. If a shared concept depends on a feature's domain models, keep it in
the feature that naturally owns that data.

## Widget & File Structure

- **CRITICAL: Split Large Files**: AI must always split large files, providers, controllers, services, and models. Do not let files grow large. If a file exceeds 250-300 lines or starts doing multiple things, split it into smaller, highly focused files immediately.
- **Prefer small files over large page/service files**: High complexity and large files are strictly prohibited.
- For larger widgets, use component folders under
  `lib/features/<feature>/presentation/widgets/<widget_name>/`.
- Put the main widget in `<widget_name>/<widget_name>.dart`.
- Put small helpers used only by that widget in the same folder.
- Callers import the concrete main widget file directly.
- Split widgets as small as practical when it improves editability and keeps
  each file focused.
- **Keep Functions Small**: Keep functions and methods extremely focused and small (target < 20 lines). Split complex logic out into private helpers or separate domain classes.

## Controller Naming

The architecture pattern is MVVM, but naming is strictly controller-based.

- Classes that hold UI state with Riverpod `Notifier` or `AsyncNotifier` are
  named `<Feature>Controller`.
- Controller files end with `_controller.dart`.
- Do not use `ViewModel` in class names or file names.
- Pure presentation models that do not own state may be named as models,
  metrics, or data objects, but not `ViewModel`.

## Feature Boundaries

- A feature owns its own data access, domain concepts, application services,
  providers, and presentation components.
- Other features should consume only the owning feature's intentional public
  edge, such as a page, section widget, controller, service, or domain type.
- Do not assemble another feature's internal widgets or providers from outside
  that feature.
- If a group of widgets always needs the same providers, wrap that group in a
  feature-owned section widget and let that section collect the providers.
- If two features need the same concept, place it in the feature that naturally
  owns the underlying data. Use `core` only when the concept is truly
  feature-independent.

## Dependency Direction

General dependency rules:

- Features may depend on `core`.
- `core` must not depend on features.
- Feature-to-feature dependencies must be explicit and small.
- Prefer depending on another feature's public edge, not its internals.
- Avoid dependency cycles. When a new dependency would create a cycle, extract
  the shared concept to the data-owning feature or to `core` if it is genuinely
  feature-independent.
- A page may compose another feature's finished UI surface, but should not wire
  that feature's internal sub-widgets and providers itself.

Concrete accepted dependencies belong in each feature's README, not here.

## Provider Ownership

- Providers are colocated with the implementation they provide. Do not create a
  global `providers/` folder for feature providers.
- Repository providers live in the feature's `data/` layer, ideally in the same
  file as the repository or in a directly adjacent `*_provider.dart` file.
- Controller providers live in the feature's `presentation/` layer, next to the
  controller. With Riverpod code generation, the generated provider stays with
  the annotated controller file.
- Application/use-case providers live in the feature's `application/` layer,
  next to the service/use case they provide.
- App-wide infrastructure providers that do not belong to one feature live in
  `core`, next to the infrastructure they provide.
- Domain should stay as provider-free as practical. Prefer pure domain models,
  value objects, and helpers there.
- A feature-level `provider/` folder is legacy/transition structure. Do not add
  new provider files there unless working inside existing code where moving the
  provider would create unrelated churn.
- After async gaps in providers/notifiers, check `ref.mounted` before using
  `ref` or writing state.

## Testing

Tests live with the code owner:

- Feature tests belong in `test/features/<feature>/`.
- Shared core helpers and widgets belong in `test/core/`.
- When moving ownership of a class, move its tests with it and update imports
  instead of keeping compatibility re-exports.
- Never change correct working code only to satisfy outdated tests. Update tests
  to match intended behavior instead.
