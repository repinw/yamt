# Architecture Rules

AI agents write the code in this Flutter project. This file is the source of
truth for how that code is structured. Keep the codebase small and plain: when
two designs follow these rules, choose the one with fewer files and types.

## How to Use This File

- **Writing code:** read this file, then `lib/features/<feature>/README.md`
  for the feature you touch, then the code.
- **Before a push to `master`:** run the [Pre-Push Review](#pre-push-review).
- **Rules beat existing code.** Much existing code breaks these rules (see
  [Legacy](#legacy)). An existing file never proves that a pattern is allowed.
- **MUST / NEVER** are hard rules. **Prefer** is a default that you may break
  for a clear reason. State the reason in your summary.
- **Enforced by** names the check that fails. *Architecture test* means
  `test/architecture/architecture_test.dart`. Rules without *Enforced by* are
  checked only in review.
- **Blocked by a rule?** Stop and describe the conflict. NEVER work around a
  rule with an ignore comment, an allowlist entry, or a hidden exception.
- Feature details belong in the feature README. Product behavior belongs in
  `features.md`.

## Stack

Exact versions are in `pubspec.yaml`. These points differ from older Flutter
code that you may know:

- **Dart 3.13 constructors:** write `const new({super.key})`, not
  `const MyWidget({super.key})`. *Enforced by:
  `unnecessary_type_name_in_constructor`.*
- **Riverpod 3** with code generation. Functional providers take a plain
  `Ref ref`. There are no generated `FooRef` types.
- **Material:** import `package:material_ui/material_ui.dart`. NEVER import
  `package:flutter/material.dart`. *Enforced by: architecture test.*
- **go_router** with hand-written routes. `go_router_builder` is not used.
- **Backend:** Firebase (Auth, Firestore, Storage, App Check, Firebase AI).
- **Models:** `json_serializable` for JSON. `freezed` is optional.
- **Lints:** `very_good_analysis`, `riverpod_lint`.
- **Tests:** `flutter_test`, `mocktail`, `fake_cloud_firestore`.
- **Localization:** ARB files, English and German.

NEVER add a package without asking the user. NEVER add an alternative to the
stack (for example `flutter_hooks`, `get_it`, `bloc`, `go_router_builder`, or a
second AI SDK such as `google_generative_ai`).

## Where New Code Goes

Paths are relative to `lib/features/<feature>/` unless they start with `lib/`.

| You add                                           | Location                                                         |
| ------------------------------------------------- | ---------------------------------------------------------------- |
| Model, value object, pure calculation             | `domain/`                                                        |
| Exception type that the UI must tell apart        | `domain/<feature>_exceptions.dart`                               |
| Repository and its provider                       | `data/<subject>_repository.dart`                                 |
| Stored shape that differs a lot from the model    | `data/<subject>_dto.dart`                                        |
| Workflow across repositories or features          | `application/<name>_service.dart`                                |
| Page                                              | `presentation/<name>_page.dart`                                  |
| UI flow (sheet, controller call, snackbar, route) | `presentation/<name>_flow.dart`                                  |
| Controller                                        | `presentation/controllers/<name>_controller.dart`                |
| Widget                                            | `presentation/widgets/<name>.dart`                               |
| Widget split into several files                   | `presentation/widgets/<name>/<name>.dart`                        |
| Route arguments, UI model without state           | `presentation/models/`                                           |
| Feature-independent widget, token, or utility     | `lib/core/<area>/`                                               |
| Route                                             | `lib/core/router/`, path in `lib/core/constants/app_routes.dart` |
| User-facing string                                | `lib/l10n/app_en.arb` and `lib/l10n/app_de.arb`                  |
| Test                                              | Same path under `test/`                                          |

- Create a layer folder only when the feature has code for it. A feature has
  no folders besides the four layers. *Enforced by: architecture test.*
- `presentation/` holds `*_page.dart` and `*_flow.dart` files, plus the
  folders `controllers/`, `models/`, and `widgets/`. *Enforced by:
  architecture test.*

### File Names

- Role suffixes: `_page`, `_flow`, `_sheet`, `_dialog`, `_controller`,
  `_state`, `_repository`, `_dto`, `_service`, `_exceptions`, `_route_args`.
- Other widgets end with a plain noun (`_card`, `_tile`, `_row`, `_section`).
  Domain files carry their concept name (`macro_budget_calculator.dart`).
- In features, NEVER use a vague role: `_helpers`, `_support`, `_utils`,
  `_manager`, `_coordinator`, `_handler`, `_logic`, `_workflows`, `_bridge`,
  `_adapter`, `_store`, `_contract`, `_codec`. Name the responsibility
  instead. *Enforced by: architecture test.*

## 1. Layers

The project uses feature-first folders, a few layers inside each feature, and
MVVM with Riverpod.

- **View** (pages, flows, widgets) renders state and forwards input to
  controllers. It MUST NOT contain business rules, persistence, or mapping.
- **Controller** (`Notifier`, `AsyncNotifier`) holds UI state and coordinates
  actions. It is the ViewModel of MVVM.
- **Domain** holds pure Dart models and business rules.
- **Data** talks to Firebase, HTTP, and local storage.
- **Application** (optional) holds services that coordinate several
  repositories or features.

Dependencies point one way: view, then controller, then application, then
domain and data. Data depends on domain. Domain depends on nothing.

- A view MUST NOT call a repository, a service, or Firebase.
- A controller may call a repository directly. NEVER create a service that
  only forwards to one repository method.
- Domain MUST NOT import Flutter, Riverpod, or Firebase. Use `package:meta`
  and `package:collection`, not `package:flutter/foundation.dart`. *Enforced
  by: architecture test.*
- Models map themselves with `@JsonSerializable` (`fromJson`, `toJson`).
  Parse strictly: one type per field, no fallback values.
- Repositories pass Firestore data through `normalizeFirestoreJson`
  (`lib/core/data/firestore_json_normalizer.dart`), which turns `Timestamp`
  into `DateTime`. Date fields read it with one strict `JsonConverter` in
  `lib/core/domain/`. Create it if it does not exist.
- NEVER call `DateTime.now()` in domain, application, or controller code. Pure
  functions take `now` or `today` as a parameter. Providers and controllers
  read the time from `clockProvider` (`lib/core/provider/clock_provider.dart`).
  *Enforced by: architecture test.*
- Domain types and UI state MUST be immutable: `final` fields with
  `copyWith`, or `@freezed`. NEVER mutate a collection in state.
- Prefer `sealed class` and `switch` for closed sets of results, states, and
  exceptions.

## 2. Data Layer

- **One repository per data area:** one concrete class with its provider in
  `data/<subject>_repository.dart`. It talks to the SDK itself. NEVER add a
  store, gateway, or contract layer between a repository and the SDK.
- **SDK access:** `firebaseFirestoreProvider` and `firebaseStorageProvider`
  (`lib/core/provider/`), `firebaseAuthProvider`
  (`lib/features/auth/data/auth_service.dart`). NEVER call `.instance` in a
  feature. *Enforced by: architecture test.*
- **Data owner:** the repository watches
  `effectiveHouseholdDataOwnerUserIdProvider` for household data and
  `authStateChangesProvider` for private data. NEVER declare a per-feature
  session interface. *Enforced by: architecture test.*
- **Signed out:** Firestore (`null` during sign-out) or the owner id can be
  missing. This is a normal state, not a failure: reads return empty results.
  Writes throw a `StateError`.
- **Interfaces:** only for two production implementations, for example
  `HealthWeightService` with `MobileHealthWeightService` and a stub for other
  platforms. Name the interface by role and the implementation by technology.
  Tests need no interface: a fake can `implement` the concrete class and
  replace it through a provider override.
- **Method names:** `watchX()` returns a `Stream`, `loadX()` a `Future`.
  Writes are `saveX()`, `addX()`, `updateX()`, `deleteX()`.
- **DTO:** create `data/<subject>_dto.dart` only when the stored shape differs
  a lot from the model.
- **Errors:** a repository lets exceptions propagate (see [Errors](#4-errors)).

## 3. Riverpod

### Declaration and Location

- MUST declare providers and controllers with `@riverpod` or `@Riverpod(...)`.
  NEVER use `StateProvider`, `StateNotifierProvider`, `ChangeNotifierProvider`,
  or `package:flutter_riverpod/legacy.dart`. *Enforced by: architecture test.*
- Annotated files include `part '<file>.g.dart';`. Hand-written `part` files,
  barrel files, and `export` statements are forbidden. *Enforced by:
  architecture test (`export`).*
- A class that holds UI state is `<Subject>Controller` in
  `<subject>_controller.dart`. NEVER use `ViewModel` in a name.
- Put a provider in the file of the thing it provides. NEVER create a
  `provider/` or `providers/` folder in a feature. `domain/` has no providers.
  Feature-independent infrastructure providers live in `lib/core/provider/`.

### Lifecycle

- UI controllers and page state: `@riverpod` (auto-dispose).
- Repositories and services: `@riverpod`. They `ref.watch` their dependencies
  in `build` and keep the values, so they rebuild when the user or household
  changes. NEVER pass `ref` into their objects or use it in a later callback.
- SDK clients, sync engines, and session-wide caches:
  `@Riverpod(keepAlive: true)`. A keep-alive provider MUST NOT watch an
  auto-dispose provider.
- An action that must finish after its screen closes starts with
  `final link = ref.keepAlive();` and calls `link.close()` in `finally`.
  NEVER call `ref.keepAlive()` without closing the link. NEVER switch to
  `keepAlive: true` only to hide a disposal bug. *Enforced by: architecture
  test (a bare `ref.keepAlive();` statement).*
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

- A failure is an exception. Repositories and services throw. NEVER return
  `false`, `null`, or an empty value to hide a failure.
- A controller captures errors with `AsyncValue.guard` and exposes
  `AsyncError`, or returns `false` to the view.
- A view shows an ARB message that names the failed action ("Could not save
  entry."). NEVER show `error.toString()` or a raw SDK message.
- Tell error types apart only when the user can act on the difference (wrong
  password, no network). Then the repository throws a subclass of
  `sealed class <Feature>Exception` from `domain/<feature>_exceptions.dart`,
  and the view maps it to ARB text with a `switch`.
- NEVER catch an exception without rethrowing, logging, or showing it.

## 5. Files and Widgets

- A Dart file in `lib/` MUST NOT exceed 300 lines. Split by responsibility
  before you reach the limit. *Enforced by:
  `test/architecture/file_size_test.dart`.*
- A file has one main public class: a page, widget, controller, repository, or
  service. Small types that belong to it may share the file: its state class,
  enums, result types, and the subclasses of a sealed class.
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
- After an `await` in a widget or flow, check `context.mounted` before you use
  `context`. *Enforced by: `use_build_context_synchronously`.*
- Before you create a widget or helper, search `lib/core/widgets/`,
  `lib/core/utils/`, and the feature. jscpd (`.jscpd.json`) reports duplicated
  blocks of 8 or more lines.

## 6. Feature Boundaries

A feature owns its data access, domain, services, providers, and presentation.

### Feature Order

A feature may import only features that come earlier in this list:

```text
shared (legacy), auth, household, health, product_nutrition, recipes,
shoppinglist, calories, inventory, kitchen_utensils, product_search_hub,
scanner, ai_chef, cooking_flow, meal_templates, activity, diary, progress,
onboarding, home_widget, settings, home
```

- From an earlier feature, import only `domain/`, `data/`, `application/`,
  `presentation/models/`, and the widgets and flows under **Public UI** in its
  README. NEVER import its controllers or other presentation code.
  *Enforced by: architecture test (the README list is checked in review).*
- NEVER import a later feature. If you need to, stop and describe the
  dependency. Changing the order is a user decision. *Enforced by:
  architecture test.*
- A new feature enters the list in the same change, after every feature that
  it imports. *Enforced by: architecture test.*

### Cross-Feature Workflows

- A workflow that changes data of several features lives in `application/` of
  the latest of them. It calls the repositories and services of the earlier
  features directly. Its UI lives in that feature or in a later one.
- NEVER pass callbacks, contracts, or adapters into an earlier feature so that
  it can reach a later one.
- Hubs, pickers, and editors MUST NOT call their caller's controllers or
  persistence. They return the result by popping their route. When an earlier
  feature opens a later feature's hub, arguments and result use types of the
  earlier feature or of `lib/core`.
- A concept that two features need belongs to the earliest feature that owns
  its data. Use `lib/core` only if the concept has no feature dependency.
- `lib/core` MUST NOT depend on features. **Exception:** the composition roots
  `lib/core/router/`, `lib/app.dart`, and `lib/main.dart` may import feature
  pages, route arguments, and the providers that route redirects read.
  *Enforced by: architecture test.*

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
  cast `state.extra` directly. *Enforced by: architecture test.*
- NEVER pass a persisted entity or a DTO in `extra`.
- **Closing:** close a go_router page with `context.pop(result)`. Close a
  dialog or bottom sheet with `Navigator.of(context).pop(result)`.

## 9. UI: Theme, Text, Accessibility

- Colors come from `Theme.of(context).colorScheme`. Semantic colors outside
  `ColorScheme` come from a `ThemeExtension` in `lib/core/theme/`.
  NEVER use `Colors.*` or `Color(0x...)` in a feature. `Colors.transparent` is
  allowed. *Enforced by: architecture test.*
- Text styles come from `Theme.of(context).textTheme`, adjusted with
  `copyWith`. NEVER create `TextStyle(...)`. *Enforced by: architecture test
  (in features).*
- Spacing, insets, radii, durations, opacities, font sizes, and sizes use the
  tokens in `lib/core/constants/` (for example `app_layout_constants.dart`).
  Add a token instead of a magic number.
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

- Tests mirror the code path: `test/features/<feature>/`, `test/core/`.
  Shared fakes and helpers live in `test/helpers/`.
- Every new domain rule, controller action, and repository has a test.
- Test controllers through a `ProviderContainer` with `overrides` and
  `addTearDown(container.dispose)`. NEVER construct a controller by hand.
  Assert the sequence of `AsyncValue` states.
- Override `clockProvider` or pass a fixed `now`. NEVER depend on real time.
- In UI flow tests, fake the repository layer with real asynchronous
  `Stream`s. NEVER override presentation or application providers with
  synchronous values: that hides auto-dispose bugs that appear when sheets and
  dialogs close.
- Test Firestore repositories with `fake_cloud_firestore`. Prefer fakes over
  `mocktail`.
- Widget tests with localized text use `appLocalizationsDelegates` and
  `AppLocalizations.supportedLocales` (see
  `test/helpers/l10n_test_utils.dart`).
- While you work, run only the affected folders, for example
  `flutter test test/features/diary`. Use `--coverage` only when you need it,
  because it is slow.
- When you move a class, move its tests. NEVER keep a re-export.
- If behavior changed on purpose, update the test. NEVER bend correct code to
  pass an outdated test.

## 12. Hygiene

- NEVER add `// ignore:` or `// ignore_for_file:`. Fix the cause, or propose a
  change to `analysis_options.yaml` if a lint is wrong for the whole project.
  *Enforced by: architecture test.*
- NEVER edit generated files (`*.g.dart`, `*.freezed.dart`,
  `lib/l10n/app_localizations*.dart`). Change the source and regenerate.
- NEVER leave commented-out code, `print`, or unused code. *`print` is
  enforced by: `avoid_print`.*
- NEVER add an abstraction, parameter, or option that the current task does
  not use.
- NEVER write backward-compatibility code. The app has no users yet, so no
  stored data or format needs to survive a change. This covers migrations,
  backfills, tolerant parsers (for example a string accepted as a number or a
  date), default values for fields that older documents lack, and special
  cases for data created before a change. Add new fields cleanly. If old local
  test data breaks, say so instead of coding around it.
- If you find existing backward-compatibility code, NEVER remove it on your
  own. Name it to the user with file and line, and let the user decide.

## 13. Feature README

Each feature has `lib/features/<feature>/README.md` with **Purpose** (one or
two sentences), **Owns**, **Does Not Own**, **Public UI** (widgets and flows
that later features may use; omit the section if there are none), and
optional **Rules** (domain rules that the code does not make obvious).

Do not list providers, files, tests, or dependencies. Product behavior belongs
in `features.md`. Update the README in the same change when ownership or the
public UI changes.

## Legacy

Much existing code breaks these rules. It is not precedent.

- `test/architecture/architecture_baseline.dart` counts the known violations
  of each architecture test rule per file. The allowlist in
  `test/architecture/file_size_test.dart` lists the files over 300 lines.
- The tests do not catch these legacy patterns:
  - interfaces with one production implementation, and store layers with
    `*Document` types;
  - flows that receive callbacks to reach a later feature, for example
    `CalorieEntryDeleteFlow`;
  - repositories and stores that catch errors and return `bool`;
  - hardcoded strings in widgets;
  - `test/support/`, features without a README, and READMEs in the old
    format.
- **Compatibility code:** tolerant JSON readers in models, for example
  `FlexibleDateTimeConverter`, `FlexibleDoubleConverter`, `_readIntOrZero`,
  `_readDateTimeOrNow`, and `readJsonDateTime`. Report them and NEVER remove
  them on your own (see [Hygiene](#12-hygiene)).

### Rules for Legacy Code

- New code follows the rules, also inside a legacy file.
- NEVER make legacy worse: no new baseline or allowlist entry, no higher
  count, no new code in `lib/features/shared/` or a `provider/` folder.
- When you fix a counted violation, lower or remove its baseline entry in the
  same change. The architecture test fails until you do. When you split an
  allowlisted file, remove its allowlist entry.
- In a file that you touch, fix legacy code only when the fix is small (about
  20 lines) and belongs to the responsibility of your change. Name larger
  findings in your summary for a refactoring task.
- **Claude only:** also write every legacy finding that you do not fix into
  the backlog in your memory directory: one `<topic>-backlog.md` memory per
  finding, with file and line, plus its line in `MEMORY.md`. Update an
  existing backlog memory instead of adding a duplicate. Other agents skip
  this step.

### Planned Moves

Do these only in dedicated refactoring tasks:

- New feature `food_catalog` after `shoppinglist`: Open Food Facts search,
  `GlobalFoodItem`, barcodes, nutrition, serving suggestions, receipt aliases,
  and `product_nutrition`.
- The inventory completion of the product search hub moves into
  `product_search_hub`. This removes the only import against the order.
- `calories` keeps domain, data, and services. UI that only `diary` uses
  moves to `diary`. `shared` moves into `auth`, `progress` into `diary`.

## Pre-Push Review

Run this review before you push to `master`.

1. List changed files: `git diff --name-only origin/master...HEAD`.
2. Run the tests of the affected features. They MUST pass before you refactor.
3. Review every changed file in `lib/` and `test/` as the checklist says.
   Fix what fails.
4. A refactor MUST NOT change behavior. Commit it separately from behavior
   changes, with the `refactor:` type.
5. Run the gates.

### Checklist

The gates check only the rules marked *Enforced by*. Review each changed file
against all other rules, section by section, including
[Where New Code Goes](#where-new-code-goes) and [File Names](#file-names).
Check these first, because no test catches them: the repository shape,
cross-feature workflows, the provider lifecycle, error display, and hardcoded
strings. Report existing compatibility code in changed files to the user.

### Gates

1. `dart run build_runner build` if annotated files changed.
2. `flutter gen-l10n` if ARB files changed.
3. `flutter analyze` reports no issues.
4. `flutter test test/architecture` passes.
5. Tests of the affected features pass.
6. `npx jscpd lib` lists no clone in a file that you changed. The project
   baseline still has clones, so the command itself fails.
