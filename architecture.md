# Architecture Rules

AI agents write the code in this Flutter project. This file and the files in
`architecture/` are the source of truth for how that code is structured. Keep
the codebase small and plain: when two designs follow these rules, choose the
one with fewer files and types.

## How to Use This File

- **Writing code:** read this file, then the files that
  [What to Read](#what-to-read) names for your work, then
  `lib/features/<feature>/README.md` for the feature you touch, then the code.
- **Before a push to `master`:** run the
  [Pre-Push Review](architecture/pre-push-review.md).
- **Rules beat existing code.** Much existing code breaks these rules (see
  [Legacy](architecture/legacy.md)). An existing file never proves that a
  pattern is allowed.
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

Flutter with Dart 3.13 constructors (`const new({super.key})`), Riverpod 3
with code generation, `material_ui`, go_router with hand-written routes,
Firebase, and ARB files in English and German. NEVER add a package without
asking the user. The full list and its rules are in
[Stack](architecture/stack.md).

## Where New Code Goes

Feature code lives in `lib/features/<feature>/` under `domain/`, `data/`,
`application/`, or `presentation/`. Feature-independent code lives in
`lib/core/<area>/`, strings in the ARB files, and a test on the same path
under `test/`. The table for every kind of file and the file name rules are in
[Where New Code Goes](architecture/where-new-code-goes.md).

## What to Read

All files are in `architecture/`. The last column gives the section name or
number that the rules had before the split.

| Your work                                                          | Read                     | Before          |
| ------------------------------------------------------------------ | ------------------------ | --------------- |
| Add a package, pick an SDK API                                     | `stack.md`               | Stack           |
| Create, move, or name a file                                       | `where-new-code-goes.md` | Where New Code… |
| Model, domain rule, which layer code belongs to                    | `layers.md`              | §1              |
| Repository, DTO, access to Firebase or storage                     | `data-layer.md`          | §2              |
| Provider or controller                                             | `riverpod.md`            | §3              |
| Throw, catch, or show an error                                     | `errors.md`              | §4              |
| Page or widget, theme, accessibility, strings, a file that grows   | `widgets-and-ui.md`      | §5, §9, §10     |
| Use another feature, add a feature, cross-feature work, `lib/core` | `feature-boundaries.md`  | §6, §7          |
| Route, navigation, route arguments, closing a page or sheet        | `navigation.md`          | §8              |
| Write, move, or run a test                                         | `testing.md`             | §11             |
| Ignore comment, generated file, stored data shape, migration       | `hygiene.md`             | §12             |
| Feature README                                                     | `feature-readme.md`      | §13             |
| Code that breaks the rules, baseline, allowlist                    | `legacy.md`              | Legacy          |
| Before a push to `master`                                          | `pre-push-review.md`     | Pre-Push Review |
