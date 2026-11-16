# Navigation

Read this when you add a route, navigate, pass route arguments, or close a
page, sheet, or dialog. Index: [architecture.md](../architecture.md).

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
- **System back with an open keyboard:** `KeyboardBackScope`
  (`lib/core/widgets/`) in the builder of `MaterialApp.router` lets the first
  system back close the keyboard; the next one leaves. Every page, sheet, and
  dialog gets this. NEVER add a `PopScope` for it. A field that unfocuses on
  a tap outside uses `onTapUpOutside`, NEVER `onTapOutside`: the back
  gesture's pointer-down reaches the app first, so `onTapOutside` would drop
  the focus and the page would close with the keyboard.

## Enforced By

- Architecture test (`test/architecture/architecture_test.dart`): rules
  `route-extra-cast`, `tap-outside-unfocus`.
