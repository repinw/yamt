# Testing Guide

This document explains how to run and add tests in `yamt`.

## Quick Commands

Run quality checks before opening a PR:

```bash
flutter analyze
flutter test
flutter test --coverage
```

Run only a changed area while iterating:

```bash
flutter test test/features/settings
flutter test test/features/auth
flutter test test/core/router/app_router_test.dart
```

## Test Layout

Put tests near their feature area:

- `test/core/...`: shared constants and router behavior.
- `test/features/auth/...`: auth providers and widgets.
- `test/features/home/...`: home UI behavior.
- `test/features/settings/...`: settings page, providers, widgets.
- `test/l10n/...`: localization coverage checks.
- `test/helpers/...`: fakes and shared test helpers.

## Conventions

- Use file names like `<subject>_test.dart`.
- Use clear test names that describe behavior and expected result.
- Follow Arrange-Act-Assert in each test.
- Prefer fakes or stubs; use `mocktail` only when needed.
- Cover both success and failure branches for provider logic.

## Riverpod Test Pattern

For provider/controller tests:

- Create a `ProviderContainer` with required overrides.
- Call `addTearDown(container.dispose)` in every test.
- Assert state transitions (`AsyncData`, `hasError`, thrown exceptions).
- Verify dependency calls with `verify(...)` when mocking.

## Widget Test Pattern

For widgets that show localized text:

- Wrap with `MaterialApp`.
- Set `localizationsDelegates` and `supportedLocales` from
  `AppLocalizations`.
- Include a `Scaffold` wrapper when testing buttons, snackbars, or dialogs.

## Change Checklist

Before merging:

- `flutter analyze` passes.
- Targeted tests for changed files pass.
- New behavior includes tests (provider and/or widget level).
