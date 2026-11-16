# Legacy

Read this when you touch code that breaks the rules, a baseline or allowlist
entry, or compatibility code. Index: [architecture.md](../architecture.md).

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
  them on your own (see [Hygiene](hygiene.md)). The tolerant calorie
  readers and the tolerant user profile decoder came back in 3.4.1; every
  file that holds them carries `Temporary compatibility, added in 3.4.1`.
  They go from 3.7.0 on, once a migration has re-saved the private documents
  in the strict shape.

## Rules for Legacy Code

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

## Planned Moves

Do these only in dedicated refactoring tasks:

- New feature `food_catalog` after `shoppinglist`: Open Food Facts search,
  `GlobalFoodItem`, barcodes, nutrition, serving suggestions, receipt aliases,
  and `product_nutrition`.
- `calories` keeps domain, data, and services. UI that only `diary` uses
  moves to `diary`. `shared` moves into `auth`, `progress` into `diary`.

## Enforced By

- Architecture test (`test/architecture/architecture_test.dart`) with
  `test/architecture/architecture_baseline.dart`: fails when a count is higher
  or lower than the baseline.
- `test/architecture/file_size_test.dart` with its allowlist.
