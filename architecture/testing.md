# Testing

Read this when you write, move, or run a test. Index:
[architecture.md](../architecture.md).

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
- A UI change (a page, a widget, the theme, the router, or ARB strings) needs
  an integration test in `integration_test/<feature>/` that drives the changed
  page. If none exists, write one. A change to the look only gets a smoke test
  that opens the page and fails on any exception. Use the fakes of UI flow
  tests, and find widgets by key, not by text. Every
  `*_page.dart` under `lib/features/` (except route models and onboarding
  intro steps) must be imported by an integration test or by a test helper
  that one imports. *Enforced by:
  `test/architecture/integration_page_coverage_test.dart`.*
- Run integration tests only on the Android emulator:
  `TARGET=<file> tool/android_integration_emulator.sh run`. NEVER run them on
  a physical device without the user's explicit yes.
- Test Firestore repositories with `fake_cloud_firestore`. Prefer fakes over
  `mocktail`.
- Widget tests with localized text use `appLocalizationsDelegates` and
  `AppLocalizations.supportedLocales` (see
  `test/helpers/l10n_test_utils.dart`).
- While you work, run only the affected folders, for example
  `flutter test -d flutter-tester test/features/diary`. Use `--coverage` only when you need it,
  because it is slow.
- When you move a class, move its tests. NEVER keep a re-export.
- If behavior changed on purpose, update the test. NEVER bend correct code to
  pass an outdated test.

## Enforced By

- `test/architecture/integration_page_coverage_test.dart`.
