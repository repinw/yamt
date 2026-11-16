# Pre-Push Review

Read this when you are about to push to `master`. Index:
[architecture.md](../architecture.md).

Run this review before you push to `master`.

1. List changed files: `git diff --name-only origin/master...HEAD`.
2. Run the tests of the affected features. They MUST pass before you refactor.
3. Review every changed file in `lib/` and `test/` as the checklist says.
   Fix what fails.
4. Delete the code that the change leaves unused: files that no import chain
   from `lib/main.dart` reaches, and symbols without a user in `lib/`. A use in
   tests alone does not count. Delete the tests that test only the removed
   code. Dead code that the change does not touch stays for a refactoring
   task.
5. A refactor MUST NOT change behavior. Commit it separately from behavior
   changes, with the `refactor:` type.
6. Run the gates.

## Checklist

The gates check only the rules marked *Enforced by*. Review each changed file
against all other rules, section by section, including
[Where New Code Goes](where-new-code-goes.md) and
[File Names](where-new-code-goes.md#file-names). Check these first, because
no test catches them: the repository shape, cross-feature workflows, the
provider lifecycle, error display, and hardcoded strings. Report existing
compatibility code in changed files to the user.

## Gates

1. `dart run build_runner build` if annotated files changed. On a clean
   tree, `tool/check_provider_hashes.sh` then finds stale provider hashes;
   the pre-push hook in `tool/git-hooks` runs it on every push once
   `git config core.hooksPath tool/git-hooks` is set, and CI runs it on every
   pull request.
2. `flutter gen-l10n` if ARB files changed.
3. `tool/ci_changed_file_lints.sh` reports no new issue, and
   `tool/ci_analyze.sh` passes. It analyzes `lib`, `test` and
   `integration_test` and fails on every issue except `max_file_lines`, which
   fires in every old file over 300 lines. The first script compares the
   changed files with `origin/master` one by one: in a file that you changed,
   no rule may fire more often than there.
4. `flutter test -d flutter-tester test/architecture` passes.
5. Tests of the affected features pass.
6. `npx jscpd lib` lists no clone in a file that you changed. The project
   baseline still has clones, so the command itself fails.
7. The change leaves no unreachable file and no unused symbol (step 4).
8. After a UI change, the integration tests of the affected features pass on
   the emulator. CI runs them after the merge to `master`, not on the pull
   request; a failed run opens an issue, which the next change fixes first.

## Enforced By

- The gates are the checks: `tool/check_provider_hashes.sh`,
  `tool/ci_changed_file_lints.sh`, `tool/ci_analyze.sh`, the tests under
  `test/architecture/`, and jscpd.
