# AI rules for Flutter

@/home/wladik/.codex/RTK.md

## Stack
- Flutter
- Riverpod 3 (codegen with `@riverpod`)
- go_router
- firebase
- freezed

## Interaction Guidelines
- speak english
- use caveman skill
- If a request is ambiguous, ask for clarification and target platform.
- When suggesting a new dependency from `pub.dev`, explain why it is needed.

## Architecture
- Use `architecture.md` as the source of truth for feature boundaries,
  layering, provider ownership, widget structure, and cross-feature dependency
  direction.
- Read `architecture.md` before generating or modifying code that changes
  architecture, feature boundaries, providers, or shared abstractions.

## Widget Folder Structure
- For feature-first UI code, organize large widgets as component folders.
- Put large widgets under
  `lib/features/<feature>/presentation/widgets/<widget_name>/`.
- Put the main widget in `<widget_name>/<widget_name>.dart`.
- Put smaller widgets/helpers used only by that large widget in the same
  `<widget_name>/` folder.
- Split widgets as small as practical, even if that creates more classes/files.
  Optimize for AI-readable context: an agent should be able to edit one focused
  widget without loading every sibling widget in the folder.
- When changing one widget, inspect sibling/support widgets only if their API,
  behavior, or layout contract is affected by the change.
- Import the main widget file directly from callers.
- Do not use hand-written `part` files or barrel export files for these widget
  splits. Generated `part` files (for example `*.g.dart` and `*.freezed.dart`)
  are allowed.

## Lint Rules
- Use `flutter_lints` in `analysis_options.yaml`.

## State Management
- Use Riverpod 3 providers and `@riverpod` code generation.
- Do not introduce `ChangeNotifier` for app state unless explicitly requested.
- Check `ref.mounted` after async gaps before writing provider state.

## Routing
- Use `go_router` navigation APIs.
- Do not use `Navigator` directly unless explicitly required by platform
  constraints.

## Localization
- All user-facing text must be localized via `AppLocalizations`.
- Add keys in `lib/l10n/app_en.arb` and `lib/l10n/app_de.arb`.
- Regenerate l10n after changes.

## Data Handling & Serialization
- Use `freezed` for immutable models/unions when needed.
- Use `json_serializable` and `json_annotation` for JSON parsing/encoding.
- Use `fieldRename: FieldRename.snake` for JSON key naming.

## Logging
- Use structured logs from `dart:developer` (`log`).

## Code Generation
- Run codegen after generator-related changes:
  `dart run build_runner build --delete-conflicting-outputs`.
- This includes updates to Riverpod, `freezed`, and `json_serializable`.

## Code Quality
- Keep code maintainable with clear separation of concerns.
- Keep solutions as simple as possible first (KISS).
- Prefer direct, local code over scalable abstractions unless there is a real
  current need.
- Do not add architecture or boilerplate "for later".
- Prefer minimal working changes now; refactor later when explicitly requested
  or when duplication/complexity already exists.
- Use explicit, descriptive names; avoid abbreviations.
- Handle errors explicitly; do not fail silently.
- Keep lines <= 80 characters.
- Use `PascalCase` for classes, `camelCase` for members/functions, and
  `snake_case` for files.
- Keep functions focused and small (target < 20 lines).
- Keep naming explicit (`...Controller`, `...Page`, `...Card`).
- Split large methods into focused private methods or extracted widgets.
- Split every Widget into own class even though they are small.
- NO hand-written part bullshit, real files and widgets, no barrel files.
  Generated `part` files are allowed.
- Keep comments short and only for non-obvious logic.

## Dart Best Practices
- Follow Effective Dart: <https://dart.dev/effective-dart>.
- Use `async`/`await` with robust error handling for async workflows.
- Write sound null-safe code; avoid `!` unless guaranteed non-null.
- Use pattern matching when it improves clarity.
- Use records for compact multi-value returns when clearer than a class.
- Prefer exhaustive `switch` statements/expressions.

## Flutter Best Practices
- Prefer small private widget classes over large build helpers only when the
  current code is already complex enough to justify extraction.
- Break down large `build()` methods into reusable widgets.
- Use `ListView.builder`/`SliverList` for long lists.
- Use `const` constructors and constants where possible.

## Testing
- Follow Arrange-Act-Assert (or Given-When-Then).
- Prefer fakes/stubs over mocks.
- See `docs/testing.md` for project testing conventions.
- Never change correct working code only to satisfy outdated tests. Update tests
  to match intended behavior instead.

## Quality Gates
- Run `flutter analyze` when i say i want to commit
- Run targeted tests for changed areas.
- Add/update tests for new widgets and provider behavior.

## UI/UX
- Keep dialogs/errors clear and action-oriented.
- Prefer consistent feedback patterns (snackbar/dialog styles).

## Theming Project Policy
- Theming is centralized. Do not add ad-hoc per-widget design systems.
- Define and reuse design tokens/constants in
  `lib/core/constants/app_ui_constants.dart`.
- Configure app-wide styling through `ThemeData` and component themes
  (for example `appBarTheme`, `cardTheme`, `elevatedButtonTheme`).
- Support `ThemeMode.light`, `ThemeMode.dark`, and `ThemeMode.system`.
- Generate base colors with `ColorScheme.fromSeed`.
- Keep typography in `TextTheme`; avoid inline `TextStyle` unless needed for
  one-off local exceptions.

## Documentation
- Write `dartdoc` comments for public APIs.
- Explain why, not what: comments should capture intent and rationale.

## Accessibility (A11Y)
- Ensure text contrast is at least 4.5:1 against background.
- Test UI with increased system text scaling.
- Use `Semantics` labels for interactive/non-obvious UI elements.
- Test core user flows with TalkBack (Android) and VoiceOver (iOS).

## Riverpod Async Safety

- Riverpod 3 throws if `Ref`/`Notifier` is used after disposal.
- In providers/notifiers, after any async gap, check `ref.mounted`
  before using `ref` or writing state.
- In widget code, do not use `WidgetRef` after an async gap.
- `WidgetRef` is tied to `BuildContext` and can become unsafe when
  widget unmounts.
- In widget callbacks:
  capture notifier/container before `await`, or move async work into
  provider/notifier.
- If widget must continue after `await`, first check `context.mounted`,
  then reacquire what you need from
  `ProviderScope.containerOf(context, listen: false)`.
- `riverpod_lint` has `avoid_ref_inside_state_dispose`, but it does not
  catch all async-gap `WidgetRef` misuse. Treat this as manual project
  rule, not lint-covered.
