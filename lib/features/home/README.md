# Home Feature

Home owns the tab shell, shared top chrome, tab navigation, and shell-level
layout surfaces that feature pages can opt into.

## Owns

- Home shell routing and tab selection.
- Shared shell chrome widgets used by embedded feature pages.
- Shell-only buttons and indicators such as the heart counter.

## Does Not Own

- Feature-specific toolbar actions.
- Inventory, diary, cookbook, statistics, or settings domain behavior.
- Feature-specific data providers or mutation workflows.

## Public Edge

Other features may consume these public Home entry points:

- `HomePage`
- `HomeShellChrome`
- `HomeShellTabTopChrome`
- `HomeTabType`

`HomeShellTabTopChrome` accepts caller-provided `actions` so feature-owned
toolbar actions stay in the feature that owns them.

## Providers

Home currently owns no Riverpod providers.

## Accepted Dependencies

Home may depend on feature controllers needed to render shell-owned tab labels,
selection state, and debug controls. Feature-specific buttons should be passed
in by the owning feature instead of imported by Home.

## Tests

Home tests live under `test/features/home/`.
