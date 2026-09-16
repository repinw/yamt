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

### Mandatory MVVM Design

New features and new UI flows are designed according to MVVM:

- **View:** Flutter pages and widgets render state and forward user
  interactions. They contain no business rules, no direct data persistence, and
  no raw data mapping.
- **ViewModel:** Riverpod controllers hold UI state, coordinate user actions,
  and expose a testable state to the view. In code, we use the name
  `Controller`, not `ViewModel`.
- **Model:** Domain models and pure business rules represent domain data and
  calculations independently of Flutter, serialization formats, and Riverpod.

Dependencies strictly flow from View to Controller, and from Controller to
Logic, Domain, and Data layers. New views must not call repositories, services,
or persistence directly.

### Riverpod Code Generation & Tooling

- State management and dependency injection use Riverpod code generation
  exclusively (`riverpod_annotation`).
- Always use the `@riverpod` annotation for providers and controllers.
- Do not use legacy manual providers such as `StateProvider`,
  `StateNotifierProvider`, or `ChangeNotifierProvider`.
- Every annotated provider/controller file must include the generated part file
  (`part 'filename.g.dart';`).
- Prefer direct, explicit imports of concrete files. Do not add hand-written
  barrel export files or barrel classes.
- Generated `part` files such as `*.g.dart` and `*.freezed.dart` are allowed.
  Hand-written `part` files are prohibited.
- `riverpod_lint` must be enabled in `analysis_options.yaml`.
- Do not use `// ignore:` or `// ignore_for_file:` comments to suppress linter
  rules or compiler diagnostics. Resolve the underlying root cause in code or
  architecture cleanly instead.

## Feature Layout

Feature code lives under `lib/features/<feature>/`.

    lib/features/<feature>/
    ├── README.md       # Feature-specific ownership, contracts, and usage notes
    ├── data/           # Repositories, DTOs, API/client implementations, data sources
    ├── domain/         # Pure entities, value objects, pure helpers, interface contracts
    ├── application/    # (Optional) Services/workflows coordinating multiple inputs
    └── presentation/   # Pages, widgets, controllers, and UI presentation models

Not every feature needs every folder. Add folders only when the feature has
code that naturally belongs there.

### Pragmatic Application Layer (No Pass-Through Services)

- The `application/` layer is **optional**. Use it only when coordinating
  multiple repositories or orchestrating non-trivial business flows.
- **No 1:1 Pass-Through Use-Cases:** Do not create dummy service classes that
  simply forward calls to a single repository method. Controllers are allowed
  to depend directly on repositories for simple operations.

### Domain Purity & DTOs

- **Domain Models are Pure Dart:** Domain entities and value objects must never
  depend on serialization libraries, SQLite schemas, or API-specific key names.
- **No Serialization in Domain:** Methods like `fromJson` and `toJson` belong
  strictly in Data Transfer Objects (DTOs) in `data/`.
- **Data Layer Owns Mapping:** Conversion between domain entities and external
  formats (`toDomain()`, `fromDto()`) must live inside the `data/` layer.
- **Immutability:** Domain entities and UI state classes should be immutable
  (prefer `@freezed` or standard immutable class definitions with `copyWith`).

## Feature README

Feature-specific architecture belongs in `lib/features/<feature>/README.md`.
Use the README for:

- What the feature owns
- What the feature explicitly does not own
- Public widgets/pages other features may use
- Important providers and where they live
- Accepted cross-feature dependencies
- Tests that cover the feature
- Migration notes for legacy structure

Keep this root architecture file generic. If a rule only applies to one feature,
document it in that feature's README.

## Core

`lib/core` is for feature-independent primitives only:

- App-wide constants and layout tokens
- App theme, theme extensions, and typography tokens
- Generic reusable widgets (buttons, input fields, loading spinners)
- Routing configuration and infrastructure
- Small domain helpers with no feature dependency

Do not move feature-specific models into `core` just to avoid thinking about
ownership. If a shared concept depends on a feature's domain models, keep it in
the feature that naturally owns that data.

## Widget & File Structure

- **CRITICAL: Split Large Files**: AI and contributors must always split large
  files, providers, controllers, services, and models. If a file exceeds
  250–300 lines or starts handling multiple responsibilities, split it into
  smaller, highly focused files immediately.
- **Prefer small files over large page/service files**: High complexity and
  large files are strictly prohibited.
- For larger widgets, use component folders under
  `lib/features/<feature>/presentation/widgets/<widget_name>/`.
- Put the main widget in `<widget_name>/<widget_name>.dart`.
- Put small helpers and sub-widgets used only by that widget in the same folder.
- Callers import the concrete main widget file directly.
- **Method & Function Size**:
  - Keep business logic, data mapping, and controller methods small and focused
    (target < 40 lines). Split complex logic out into private helpers or
    domain services.
  - For declarative Flutter `build()` methods, prioritize semantic clarity:
    extract sub-trees into dedicated `StatelessWidget` classes whenever a
    sub-tree represents a self-contained visual component, has distinct state
    dependencies, or impairs the readability of the parent build method. Avoid
    arbitrary micro-splitting that hurts readability without structural benefit.

## Controller Naming & State Management

The architecture pattern is MVVM, but naming is strictly controller-based.

- Classes that hold UI state with Riverpod `Notifier` or `AsyncNotifier` are
  named `<Feature>Controller`.
- Controller files end with `_controller.dart`.
- Do not use `ViewModel` in class names or file names.
- Pure presentation models that do not own state may be named as models,
  metrics, or state objects, but not `ViewModel`.

### Lifecycle: KeepAlive vs. AutoDispose

- **UI Controllers & Page State:** Default to `@riverpod` (`autoDispose`). They
  must be cleaned up when navigating away from the screen.
- **Repositories, Core Services & Sync Engines:** Must explicitly use
  `@Riverpod(keepAlive: true)` to maintain persistent caches, client sessions,
  and long-running database connections.
- **No Unlistened `ref.read` / `container.read` on AutoDispose `.future`:**
  Never call `ref.read(provider.future)` or `container.read(provider.future)`
  on auto-disposed providers without an active subscription (`ref.listen` /
  `container.listen`). Reading `.future` on an unobserved auto-disposed provider
  causes Riverpod to dispose the provider during its asynchronous loading
  phase, throwing `StateError (Bad state: The provider X was disposed during
  loading state, yet no value could be emitted.)`. In mutations and services,
  read data directly from the repository or pass required entities from the
  caller. If an unmounted controller must wait for an auto-disposed provider,
  keep a subscription via `container.listen` across the async operation.

### Reactive UI: `watch` vs. `listen`

- **`ref.watch` is for UI building:** Use `ref.watch` inside widget `build()`
  methods to observe state and trigger re-renders. Never execute imperative side
  effects (such as showing a `SnackBar`, opening a dialog, or triggering route
  navigation) inside a `ref.watch` callback or the build body.
- **`ref.listen` is for side effects:** One-off actions triggered by state
  changes must use `ref.listen` inside `build()` or lifecycle hooks to ensure
  they fire exactly once per transition.

### UI State vs. Local Ephemeral State

Do not mirror transient widget state into Riverpod controllers.

- **Local Widget State:** Keep `TextEditingController`, `FocusNode`,
  `ScrollController`, `TabController`, and ephemeral animation/hover states
  inside `StatefulWidget` or Flutter hooks.
- **Controller State:** Push values to the controller only when submitting a
  form, triggering debounced remote operations, or updating business state.

### Error Handling & Asynchronous Mutations

- **Domain Exceptions:** Repositories must catch client/transport exceptions
  (e.g., HTTP, database) and map them to explicit, domain-specific typed
  exceptions (e.g., `UserNotFoundException`, `NetworkConnectionException`)
  before re-throwing. This allows `AsyncValue.guard` to cleanly capture them.
- **Preserve Previous State During Async Loading:** When triggering actions on
  existing UI state, preserve the current data instead of replacing it with a
  blank loading state:

      Future<void> updateProfile(UserProfile data) async {
        state = const AsyncLoading<UserProfile>().copyWithPrevious(state);
        state = await AsyncValue.guard(
          () => ref.read(userRepositoryProvider).update(data),
        );
      }

- **Separation of Queries and Actions:** For dedicated form submissions or
  one-off actions that do not hold persistent screen data, use an
  `AsyncNotifier<void>` or manage an action-specific `AsyncValue<void>` state.
- After async gaps in providers or notifiers, check `ref.mounted` before using
  `ref` or mutating state.

## Navigation & Routing

Routing configuration and route paths live in `lib/core/routing/`.

- **Type-Safe Routes Preferred:** Use `go_router` with code generation
  (`go_router_builder`) whenever possible to guarantee compile-time safety for
  routes and arguments.
- **Views Trigger Navigation:** Navigation is a presentation responsibility.
  Widgets and pages execute route transitions via `context.go()` or
  generated route extensions. Controllers coordinate logic and state, but must
  never accept a `BuildContext` or trigger navigation directly.
- **Primitive Route Parameters Only:** Routes must accept only primitive types
  (e.g., `id: String`, `index: int`) via path or query parameters.
  - **Never pass domain objects or DTOs as navigation arguments.**
  - Passing IDs ensures deep linking compatibility, supports web reloads, and
    prevents displaying stale data when models are updated elsewhere. The
    destination page reads the ID and queries its own provider.

## Feature Boundaries

- A feature owns its own data access, domain concepts, application services,
  providers, and presentation components.
- Other features should consume only the owning feature's intentional public
  edge, such as a page, section widget, domain type, or interface contract.
- Do not assemble another feature's internal widgets or providers from outside
  that feature.
- If a group of widgets always needs the same providers, wrap that group in a
  feature-owned section widget and let that section collect the providers.
- If two features need the same concept, place it in the feature that naturally
  owns the underlying data. Use `core` only when the concept is truly
  feature-independent.
- **Decoupled Feature Contracts (`abstract interface class`)**: When building
  self-contained or modular features (such as scanner engines, product search
  hubs, or third-party integrations), features must define external
  dependencies as lightweight `abstract interface class` contracts in their
  domain layer. The consuming feature or application layer provides concrete
  implementations via Riverpod providers. This eliminates tight cross-feature
  coupling and enables fast, isolated unit testing with fakes.
- **Zero Cross-Feature Controller/Presentation Imports**: A feature must never
  import another feature's `presentation/controllers/`, `presentation/flows/`,
  or internal state notifiers. Controllers belong strictly to the feature that
  hosts them and must never be wired or called across feature boundaries.
- **Caller Owns Side Effects (Hubs, Pickers, Modals)**: Reusable search hubs,
  pickers, modals, or editors must never import or execute caller controllers,
  mutation flows, or persistence logic. The hub is a presentation and editing
  surface: it either returns the edited result directly to the caller via
  navigation (`Navigator.pop(context, result)`), or delegates completion
  effects through domain `abstract interface class` contracts implemented by the
  caller. Dependencies must always point from caller to callee, never backwards.

## Dependency Direction

General dependency rules:

- Features may depend on `core`.
- `core` must not depend on features.
- Feature-to-feature dependencies must be explicit and small.
- Prefer depending on another feature's public edge, not its internals.
- Never depend on another feature's presentation controllers or mutation flows.
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

## Testing

Tests live with the code owner:

- Feature tests belong in `test/features/<feature>/`.
- Shared core helpers and widgets belong in `test/core/`.
- When moving ownership of a class, move its tests with it and update imports
  instead of keeping compatibility re-exports.
- **Riverpod Unit Testing:** Unit-test controllers and notifiers using a
  `ProviderContainer` with explicit dependency `overrides`, rather than
  instantiating controller classes manually.
- Verify state transitions by asserting emitted `AsyncValue` sequence states.
- **Testing AutoDispose & Stream Provider Lifecycles:** In UI flow tests,
  fake/mock at the repository layer using real or asynchronous `Stream`
  instances rather than overriding high-level presentation or application
  providers with static synchronous values. Overriding with synchronous values
  masks auto-dispose timing errors that only manifest when bottom sheets or
  dialogs unmount.
- Never change correct working code only to satisfy outdated tests. Update tests
  to match intended behavior instead.

## Theme, Styling & Localization Guidelines

All styling, colors, typography, and UI strings must be centralized to
support scalability, light/dark modes, and internationalization.

### Design Tokens & Theme

- **Strictly No Hardcoded Colors or TextStyles in Widgets**: 
  - Never use inline color definitions (e.g., `Color(0xFF...)`, `Colors.blue`)
    or inline `TextStyle()` configurations inside feature widgets.
  - Colors must always be resolved via `Theme.of(context).colorScheme.<token>`
    (e.g., `primary`, `surface`, `onSurface`).
  - Text typography must always use `Theme.of(context).textTheme.<style>` (e.g.,
    `bodyMedium`, `titleLarge`).
- **Design Tokens**: Spacing, paddings, and border radii must use shared
  constants or layout tokens defined in `lib/core/theme/` (e.g.,
  `AppSpacing.md`).
- **Domain-Specific Theme Extensions**: When features require custom semantic
  colors not covered by `ColorScheme` (e.g., status indicators, macro-nutrient
  badges), define a custom `ThemeExtension` inside `lib/core/theme/extensions/`.
- **Theme State Management**: The active theme mode (light, dark, system) is
  managed by a dedicated Riverpod controller in
  `lib/core/theme/logic/theme_controller.dart`. UI widgets only observe the
  mode via `Theme.of(context)`.

### Localization (l10n / i18n)

- **Strictly No Hardcoded Strings in UI**:
  - Never write user-facing raw string literals in presentation widgets.
  - All labels, error messages, placeholders, and tooltips must be resolved
    via generated localization (e.g., `AppLocalizations.of(context).key` or
    `context.l10n.key`).
  - Dynamic messages must use localized strings with interpolation arguments
    rather than Dart string concatenation.