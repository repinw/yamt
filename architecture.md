# Architecture Rules

AI agents write the code in this Flutter project. This file is the source of
truth for how that code is structured.

## How to Use This File

- **Writing code:** read this file, then `lib/features/<feature>/README.md`
  for the feature you touch, then the code.
- **Before a push to `master`:** run the [Pre-Push Review](#pre-push-review).
- **Rules beat existing code.** Some existing code breaks these rules (see
  [Legacy: Do Not Copy](#legacy-do-not-copy)). An existing file never proves
  that a pattern is allowed.
- **MUST / NEVER** are hard rules. **Prefer** is a default that you may break
  for a clear reason. State the reason in your summary.
- **Enforced by** names the check that fails. Rules without it are checked
  only in review.
- **Blocked by a rule?** Stop and describe the conflict. NEVER work around a
  rule with an ignore comment, an allowlist entry, or a hidden exception.
- This file holds generic rules. Feature details belong in the feature README,
  product behavior in `features.md`, test commands in `docs/testing.md`.

## Stack

Exact versions are in `pubspec.yaml`. These points differ from older Flutter
code that you may know:

- **Dart 3.13 constructors:** write `const new({super.key})`, not
  `const MyWidget({super.key})`. *Enforced by:
  `unnecessary_type_name_in_constructor`.*
- **Riverpod 3** with code generation. Functional providers take a plain
  `Ref ref`. There are no generated `FooRef` types.
- **Material:** import `package:material_ui/material_ui.dart`. NEVER import
  `package:flutter/material.dart`.
- **go_router** with hand-written routes. `go_router_builder` is not used.
- **Backend:** Firebase (Auth, Firestore, Storage, App Check, Firebase AI).
- **Lints:** `very_good_analysis`, `riverpod_lint`.
- **Tests:** `flutter_test`, `mocktail`, `fake_cloud_firestore`.
- **Localization:** ARB files, English and German.

NEVER add a package without asking the user. NEVER add an alternative to the
stack (for example `flutter_hooks`, `get_it`, `bloc`, `go_router_builder`).

## Where New Code Goes

Paths are relative to `lib/features/<feature>/` unless they start with `lib/`.

| You add                                         | Location                                                  |
| ----------------------------------------------- | --------------------------------------------------------- |
| Entity, value object, pure calculation          | `domain/`                                                 |
| Typed exceptions of the feature                 | `domain/<feature>_exceptions.dart`                        |
| Contract that the feature needs from outside    | `domain/`, as `abstract interface class`                  |
| Repository and its provider                     | `data/<subject>_repository.dart`                          |
| Firestore document mapping                      | `data/<entity>_document_codec.dart`                       |
| Workflow across repositories or features        | `application/`                                            |
| Adapter that implements a contract              | `application/`                                            |
| Page                                            | `presentation/<name>_page.dart`                           |
| Controller                                      | `presentation/controllers/<name>_controller.dart`         |
| Widget                                          | `presentation/widgets/`                                   |
| Widget with private sub-widgets                 | `presentation/widgets/<name>/<name>.dart`                 |
| UI model without state                          | `presentation/models/`                                    |
| Exception-to-message mapping                    | `presentation/<feature>_error_message_mapper.dart`        |
| Feature-independent widget, token, or utility   | `lib/core/<area>/`                                        |
| Route                                           | `lib/core/router/`, path in `lib/core/constants/app_routes.dart` |
| User-facing string                              | `lib/l10n/app_en.arb` and `lib/l10n/app_de.arb`            |
| Test                                            | Same path under `test/`                                   |

Add a layer folder only when the feature has code for it.

## 1. Layers

The project uses feature-first structure, Clean Architecture layers, and MVVM
with Riverpod.

- **View** (pages, widgets) renders state and forwards input. It MUST NOT
  contain business rules, persistence, or mapping.
- **Controller** (`Notifier`, `AsyncNotifier`) holds UI state and coordinates
  actions. It is the ViewModel of MVVM.
- **Domain** holds pure Dart types and business rules.
- **Data** talks to Firebase, HTTP, and local storage, and maps their formats.
- **Application** (optional) coordinates several repositories or features.

Dependencies point one way: view, then controller, then application, then
domain and data. Data depends on domain. Domain depends on nothing.

- A view MUST NOT call a repository, a service, or Firebase.
- A controller may call a repository directly. NEVER create an application
  service that only forwards to one repository method.
- Domain MUST NOT import Flutter, Riverpod, Firebase, or `json_annotation`.
  `@freezed` is allowed. `fromJson`, `toJson`, and Firestore field names are
  not.
- Domain and application code MUST NOT call `DateTime.now()`. Pure functions
  take `now` or `today` as a parameter. Providers and controllers read the
  time from `clockProvider` in `lib/core/`. If it does not exist, create it:

  ```dart
  @Riverpod(keepAlive: true)
  DateTime Function() clock(Ref ref) => DateTime.now;
  ```

- Domain types and UI state MUST be immutable: `@freezed`, or `final` fields
  with `copyWith`. Collections in state MUST NOT be mutated after creation.
- Prefer `sealed class` and `switch` pattern matching for closed sets of
  results, states, and exceptions.

## 2. Data Layer

- **SDK access:** repositories get SDK instances (`FirebaseFirestore`,
  `FirebaseAuth`, `FirebaseStorage`, `http.Client`) from providers in
  `lib/core/provider/`. NEVER call `.instance` in a feature.
- **Method names:** `watchX()` returns a `Stream`. `loadX()` returns a
  `Future`. Writes are `saveX()`, `addX()`, `updateX()`, `deleteX()`.
- **Mapping:** Firestore maps are converted in `data/` with top-level
  `decodeX(...)` and `encodeX(...)` functions in a `*_document_codec.dart`
  file. Create a DTO class only when the external shape differs a lot from the
  domain type.
- **Interfaces:** create an `abstract interface class` for a repository only
  when another feature consumes it, or when there are two production
  implementations. Tests do not need an interface: a fake can `implement` the
  concrete class and replace it through a provider override.
- **Interface names:** name the interface by role (`CalorieLogRepository`) and
  the implementation by technology (`FirestoreCalorieLogRepository`). NEVER
  use an `I` prefix, `Impl` suffix, or `Contract` suffix.
- **Errors:** a repository MUST catch transport exceptions
  (`FirebaseException`, HTTP errors) and rethrow typed feature exceptions. See
  [Errors](#4-errors).

## 3. Riverpod

### Declaration and Naming

- MUST declare providers and controllers with `@riverpod` or `@Riverpod(...)`.
  NEVER use `StateProvider`, `StateNotifierProvider`, `ChangeNotifierProvider`,
  or `package:flutter_riverpod/legacy.dart`. *Enforced by: `riverpod_lint`.*
- Annotated files include `part '<file>.g.dart';`. Hand-written `part` files
  and barrel files are forbidden. Import concrete files.
- A class that holds UI state is `<Subject>Controller` in
  `<subject>_controller.dart`. NEVER use `ViewModel` in a name.

### Location

- Put a provider in the file of the thing it provides. NEVER create a
  `providers/` or `provider/` folder in a feature.
- App-wide infrastructure providers live in `lib/core/`, for example Firebase
  SDK providers in `lib/core/provider/`.
- `domain/` contains no providers.

### Lifecycle

- UI controllers and page state: `@riverpod` (auto-dispose).
- Repositories, SDK clients, and sync engines: `@Riverpod(keepAlive: true)`.
- To cache an expensive auto-dispose result, call `ref.keepAlive()` and close
  the link with a timer in `ref.onCancel`. NEVER switch to `keepAlive: true`
  only to hide a disposal bug.
- Family parameters MUST have value equality: primitives, records, enums, or
  `@freezed` types.

### Reading Providers

- **In a provider's `build`:** depend on another provider with `ref.watch`.
  For async values use `await ref.watch(otherProvider.future)`.
- **In a widget's `build`:** `ref.watch` to render. Use
  `ref.watch(provider.select((s) => s.field))` when the widget needs only part
  of the state.
- **Side effects** (snackbar, dialog, navigation): `ref.listen` in `build`.
  NEVER run side effects in the `build` body.
- **In callbacks and controller methods:** `ref.read`. NEVER `ref.read` in
  `build`.
- NEVER call `ref.read(p.future)` or `container.read(p.future)`. An
  auto-dispose provider without a listener disposes during loading and throws
  `StateError: The provider X was disposed during loading state`. Read the
  repository, take the data from the caller, or hold a `container.listen`
  subscription for the whole operation. *Enforced by:
  `test/architecture/autodispose_future_read_test.dart`.*

### Rendering AsyncValue

Render with `asyncValue.when(data: ..., loading: ..., error: ...)`. It keeps
showing the previous data during a refresh. A hand-written `switch` easily
shows a spinner instead.

### Async Actions

After every `await` in a provider or controller, check `ref.mounted` before
you use `ref` or `state`. Riverpod 3 keeps the previous value when you set
`AsyncLoading`. NEVER call `copyWithPrevious` (it is `@internal`).

```dart
Future<bool> save(Entry entry) async {
  state = const AsyncLoading();
  final result = await AsyncValue.guard(
    () => ref.read(entryRepositoryProvider).saveEntry(entry),
  );
  if (!ref.mounted) return false;
  state = result;
  return !result.hasError;
}
```

A controller for a one-off action uses `AsyncNotifier<void>`.

### Local State

Keep `TextEditingController`, `FocusNode`, `ScrollController`,
`AnimationController`, and hover or animation flags in a `StatefulWidget`.
Send values to a controller only on submit, on a debounced search, or when
business state changes.

## 4. Errors

- Declare feature exceptions as a
  `sealed class <Feature>Exception implements Exception` with subclasses in
  `domain/<feature>_exceptions.dart`.
- A controller captures errors with `AsyncValue.guard`.
- A view turns an error into text only through the feature's
  `<Feature>ErrorMessageMapper`. The mapper returns an `AppLocalizations`
  string and has a generic fallback.
- NEVER show `error.toString()` or a raw SDK message to the user.
- NEVER catch an exception without rethrowing, logging, or showing it.

## 5. Files and Widgets

- A Dart file in `lib/` MUST NOT exceed 300 lines. Split by responsibility
  before you reach the limit. *Enforced by:
  `test/architecture/file_size_test.dart`.*
- One public class per file. Private helpers used only by that class may stay.
- Prefer methods under 40 lines.
- Extract a sub-tree into a `StatelessWidget` when it is a visual component,
  has its own state dependencies, or makes the parent hard to read. Prefer a
  widget class over a `_buildX()` method.
- Use `const` constructors and `const` widget instances. *Enforced by:
  `prefer_const_constructors`.*
- Build lists of unknown or long length with `ListView.builder` or slivers.
  Give stateful or reorderable list items a `ValueKey` with a stable ID.
- Sort, filter, and group data in a controller or provider, never in `build`.
- Use `MediaQuery.sizeOf(context)` and the other `*Of` methods, never
  `MediaQuery.of(context).size`.
- After an `await` in a widget, check `context.mounted` before you use
  `context`. *Enforced by: `use_build_context_synchronously`.*
- Before you create a widget or helper, search `lib/core/widgets/`,
  `lib/core/utils/`, and the feature. Duplicated blocks of 8 or more lines
  fail jscpd (`.jscpd.json`).

## 6. Feature Boundaries

A feature owns its data access, domain, application services, providers, and
presentation.

- Other features use only the **public edge** that the feature README lists: a
  page, a complete section widget, a domain type, or a contract.
- NEVER import another feature's `presentation/controllers/` or internal
  providers. NEVER assemble another feature's internal widgets.
- If widgets always need the same providers, the owning feature exposes one
  section widget that reads them.
- **Cross-feature workflows:** the feature where the user action starts owns
  the workflow in its `application/`. It declares a narrow contract in its
  `domain/` for what it needs. An adapter in its `application/` implements the
  contract with the other feature's public repository or service.
- **Reusable hubs, pickers, modals, editors** MUST NOT call caller
  controllers or persistence. They return the result by popping their route,
  or call a contract that the caller implements.
- A concept that two features need belongs to the feature that owns the data.
  Use `lib/core` only if the concept has no feature dependency.

### Dependency Direction

- Features may depend on `lib/core`. `lib/core` MUST NOT depend on features.
  **Exception:** `lib/core/router/`, `lib/app.dart`, and `lib/main.dart` are
  composition roots and may import feature pages.
- A feature-to-feature dependency MUST target the public edge and be listed in
  the README of the depending feature.
- NEVER create a dependency cycle. Break it with a contract in the consuming
  feature, or move the concept to the feature that owns the data.

## 7. Core

`lib/core` holds feature-independent code only: `config/`, `constants/`
(layout tokens, route paths), `data/` (generic storage helpers), `domain/`,
`l10n/`, `router/`, `theme/`, `widgets/`, `utils/`, and infrastructure in
`debug/`, `device/`, `preferences/`, `provider/`.

NEVER move a feature type into `lib/core` to avoid an ownership decision.

## 8. Navigation

- Paths are constants in `AppRoutes`. A path with parameters is built only
  with its `AppRoutes.*Path(...)` method. NEVER write a path string literal
  elsewhere.
- Views navigate. A controller MUST NOT take a `BuildContext` or navigate. It
  returns a result, and the view decides:

  ```dart
  final saved = await ref.read(entryEditorControllerProvider.notifier).save(entry);
  if (!saved || !context.mounted) return;
  context.pop(true);
  ```

- **Persisted entity:** pass its ID in the path or query. The destination
  loads the entity from its provider.
- **Transient input without an ID** (unsaved draft, scan result, hub
  arguments): pass one typed args object in `extra`. Read it only with
  `requireRouteExtra` from `lib/core/router/route_page_helpers.dart`. NEVER
  cast `state.extra` directly.
- NEVER pass a persisted entity or a DTO in `extra`.
- **Closing:** close a go_router page with `context.pop(result)`. Close a
  dialog or bottom sheet with `Navigator.of(context).pop(result)`.

## 9. UI: Theme, Text, Accessibility

- Colors come from `Theme.of(context).colorScheme`. Semantic colors outside
  `ColorScheme` come from a `ThemeExtension` in `lib/core/theme/`.
  NEVER use `Colors.*` or `Color(0x...)` in a feature. `Colors.transparent` is
  allowed.
- Text styles come from `Theme.of(context).textTheme`, adjusted with
  `copyWith`. NEVER create `TextStyle(...)`.
- Spacing, insets, radii, durations, opacities, font sizes, and sizes use the
  tokens in `lib/core/constants/app_layout_constants.dart`. Add a token instead
  of a magic number.
- Every screen MUST work in light mode, dark mode, and with large text scaling.
  NEVER give a text container a fixed height.
- Tap targets are at least 48 by 48 logical pixels. An icon-only button MUST
  have a `tooltip` or a `Semantics` label.

## 10. Localization

- NEVER write a user-facing string literal in a widget. This includes labels,
  errors, hints, tooltips, and semantics labels.
- Access strings with `AppLocalizations.of(context)!`.
- Add every key to `app_en.arb` and `app_de.arb` in the same change.
- Use ARB placeholders and plurals. NEVER concatenate messages.

## 11. Testing

Commands and patterns: `docs/testing.md`.

- Tests mirror the code path: `test/features/<feature>/`, `test/core/`. Shared
  fakes live in `test/helpers/` and `test/support/`.
- Every new domain rule, controller action, and codec has a unit test.
- Test controllers through a `ProviderContainer` with `overrides`. NEVER
  construct a controller by hand. Assert the sequence of `AsyncValue` states.
- Override `clockProvider` or pass a fixed `now`. NEVER depend on the real
  time.
- In UI flow tests, fake the repository layer with real asynchronous
  `Stream`s. NEVER override presentation or application providers with
  synchronous values: that hides auto-dispose bugs that appear when sheets and
  dialogs close.
- Test Firestore repositories and codecs with `fake_cloud_firestore`. Prefer
  fakes over `mocktail`.
- When you move a class, move its tests. NEVER keep a re-export.
- If behavior changed on purpose, update the test. NEVER bend correct code to
  pass an outdated test.

## 12. Hygiene

- NEVER add `// ignore:` or `// ignore_for_file:`. Fix the cause, or propose a
  change to `analysis_options.yaml` if a lint is wrong for the whole project.
- NEVER edit generated files (`*.g.dart`, `*.freezed.dart`,
  `lib/l10n/app_localizations*.dart`). Change the source and regenerate.
- NEVER leave commented-out code, `print`, or unused code.
- NEVER add an abstraction, parameter, or option that the current task does
  not use.
- NEVER write backward-compatibility code. The app has no users yet, so no
  stored data or format needs to survive a change. This covers migrations,
  backfills, tolerant parsers (for example a string accepted as a number),
  fallbacks for fields that older documents lack, and special cases for data
  created before a change. Add new fields cleanly. If old local test data
  breaks, say so instead of coding around it.
- If you find existing backward-compatibility code, NEVER remove it on your
  own. Name it to the user with file and line, and let the user decide.

## 13. Feature README

Each feature has `lib/features/<feature>/README.md` with: **Owns**, **Does Not
Own**, **Public Edge**, **Providers**, **Dependencies**, **Tests**, **Legacy**.

Update it in the same change when the public edge, providers, or dependencies
change. If the feature has no README, create one.

## Legacy: Do Not Copy

These patterns exist in the codebase. They break the rules and are not
precedent:

- Files over 300 lines in the allowlist of
  `test/architecture/file_size_test.dart`.
- Feature-level `provider/` folders.
- Imports of another feature's `presentation/controllers/`.
- `fromJson` and `toJson` in `domain/`.
- `DateTime.now()` in `domain/`, `application/`, and controllers.
- `FirebaseFirestore.instance` and other `.instance` calls in features.
- Interfaces named with a `Contract` suffix.
- Direct casts of `state.extra`.
- Hardcoded `Colors.*`, `Color(0x...)`, `TextStyle(...)`, and strings in
  widgets.
- `// ignore` and `// ignore_for_file` comments.
- `lib/features/shared/` and the flat `lib/features/home/` folder.
- Features without a README.

Rules for legacy code:

- New code follows the rules, also inside a legacy file.
- NEVER add a file to the size allowlist. When you split an allowlisted file,
  remove its entry.
- NEVER add code to `lib/features/shared/` or a legacy `provider/` folder.
- Fix legacy code in files that your change touches. Leave untouched files for
  a dedicated refactoring task.

## Pre-Push Review

Run this review before you push to `master`.

1. List changed files: `git diff --name-only origin/master...HEAD`.
2. Run the tests of the affected features. They MUST pass before you refactor.
3. Check every changed file in `lib/` and `test/` against the checklist below.
   Fix what fails.
4. A refactor MUST NOT change behavior. Commit it separately from behavior
   changes, with the `refactor:` type.
5. Run the gates.

### Checklist

- **Placement:** each file matches [Where New Code Goes](#where-new-code-goes).
- **Size:** each file is under 300 lines with one responsibility. The size
  allowlist did not grow.
- **Layers:** no view calls a repository. Domain has no Flutter, Firebase,
  JSON, or `DateTime.now()`.
- **Data:** SDKs come from providers. Methods follow `watchX` and `loadX`.
  Transport exceptions become typed exceptions. Mapping is in a codec.
- **Riverpod:** `@riverpod` only. Correct lifecycle. `ref.mounted` after every
  `await`. No `read(p.future)`. No side effects in `build`.
- **Boundaries:** no foreign controllers. Cross-feature access goes through a
  public edge or a contract. The README is up to date.
- **Navigation:** paths from `AppRoutes`. IDs for persisted entities.
  `requireRouteExtra` for `extra`. `context.mounted` after `await`.
- **UI:** theme colors and text styles, layout tokens, `const`, tooltips on
  icon buttons, no hardcoded strings, keys in both ARB files.
- **Tests:** new behavior has tests. No real time. Repository-level fakes.
- **Hygiene:** no ignore comments, no edits to generated files, no new
  packages, no dead or commented-out code, no new backward-compatibility
  code. Existing compatibility code in changed files is reported to the user.

### Gates

1. `dart run build_runner build` if annotated files changed.
2. `flutter gen-l10n` if ARB files changed.
3. `flutter analyze` reports no new issues.
4. `flutter test test/architecture` passes.
5. Tests of the affected features pass.
6. `npx jscpd lib` reports no new duplicates.
