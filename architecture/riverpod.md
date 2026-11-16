# Riverpod

Read this when you declare, read, or change a provider or a controller. Index:
[architecture.md](../architecture.md).

## Declaration and Location

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

## Lifecycle

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

## Reading Providers

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
  `ProviderDisposedException: The provider X was disposed during loading
  state`. Read the repository, take the data from the caller, or hold a
  `container.listen` subscription for the whole operation. *Enforced by:
  `test/architecture/autodispose_future_read_test.dart`.*

## Rendering AsyncValue

Render with `asyncValue.when(data: ..., loading: ..., error: ...)`. It keeps
showing the previous data during a refresh. A hand-written `switch` easily
shows a spinner instead.

## Async Actions

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

## Local State

Keep `TextEditingController`, `FocusNode`, `ScrollController`,
`AnimationController`, and hover or animation flags in a `StatefulWidget`.
Send values to a controller only on submit, on a debounced search, or when
business state changes.

## Enforced By

- Architecture test (`test/architecture/architecture_test.dart`): rules
  `legacy-riverpod`, `export`, `bare-keep-alive`.
- `test/architecture/autodispose_future_read_test.dart`.
- Lint: `avoid_unlistened_read_future` (`tools/architecture_lints`).
