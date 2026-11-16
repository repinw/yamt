# Files, Widgets, UI, and Localization

Read this when you build or change a page or a widget, a file grows, or you
touch colors, text styles, spacing, accessibility, or strings. Index:
[architecture.md](../architecture.md).

## Files and Widgets

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

## UI: Theme, Text, Accessibility

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

## Localization

- NEVER write a user-facing string literal in a widget. This includes labels,
  errors, hints, tooltips, and semantics labels.
- Access strings with `AppLocalizations.of(context)!`.
- Add every key to `app_en.arb` and `app_de.arb` in the same change.
- Use ARB placeholders and plurals. NEVER concatenate messages.

## Enforced By

- Architecture test (`test/architecture/architecture_test.dart`): rule
  `theme-values`.
- `test/architecture/file_size_test.dart`.
- Lints: `max_file_lines` (`tools/architecture_lints`),
  `prefer_const_constructors`, `use_build_context_synchronously`.
- By hand: jscpd (`.jscpd.json`), gate 6 of the
  [Pre-Push Review](pre-push-review.md). No test or CI job runs it.
