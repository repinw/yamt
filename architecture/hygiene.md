# Hygiene

Read this when you are about to add an ignore comment, edit a generated file,
change a stored data shape, or meet compatibility code. Index:
[architecture.md](../architecture.md).

- NEVER add `// ignore:` or `// ignore_for_file:`. Fix the cause, or propose a
  change to `analysis_options.yaml` if a lint is wrong for the whole project.
  *Enforced by: architecture test.*
- NEVER edit generated files (`*.g.dart`, `*.freezed.dart`,
  `lib/l10n/app_localizations*.dart`). Change the source and regenerate.
- NEVER leave commented-out code, `print`, or unused code. *`print` is
  enforced by: `avoid_print`.*
- NEVER add an abstraction, parameter, or option that the current task does
  not use.
- Models parse strictly. When a change leaves stored data that the new app
  cannot read (a new required field, a moved path, a renamed value), write a
  migration that rewrites the stored data into the new shape. The app has
  real users, so their data MUST survive every release. Start the doc
  comment of the migration with `Temporary migration, added in <version>`.
  A migration runs only once `appUpdateStatusProvider`
  (`lib/core/data/app_version_config_repository.dart`) has a value that is
  not `AppUpdateRequired`: an app older than the minimum version MUST NOT
  rewrite data that a newer app migrated. A release with a migration raises the minimum version once it is
  live in both stores.
- Prefer a migration over backward-compatibility code: tolerant parsers (for
  example a string accepted as a number or a date), default values for
  fields that older documents lack, and special cases for data created
  before a change. Add such code only as a temporary bridge, marked
  `Temporary compatibility, added in <version>`.
- **Lifetime:** a migration or backward-compatibility code stays for the two
  release stages (minor versions) after the one that adds it and is removed
  from the third on. Code added in 3.4.1 stays in 3.5 and 3.6 and is removed
  in 3.7.0. In the same change, record the removal version in the memory or
  the roadmap, with file and symbol, so the release checklist removes it.
- If you find existing backward-compatibility code, NEVER remove it on your
  own. Name it to the user with file and line, and let the user decide.

## Enforced By

- Architecture test (`test/architecture/architecture_test.dart`): rule
  `ignore-comment`.
- Lint: `avoid_print`.
