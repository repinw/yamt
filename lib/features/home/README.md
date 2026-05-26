# Home Feature

Home owns the tab shell, tab navigation, and shell-level composition.

## Owns

- Home shell routing and tab selection.
- Shell-only navigation state and bottom navigation chrome.

## Does Not Own

- Feature-specific toolbar actions.
- Inventory, diary, cookbook, or settings domain behavior.
- Feature-specific data providers or mutation workflows.

## Public Edge

Other features may consume these public Home entry points:

- `HomePage`
Shared shell chrome primitives live in `core/widgets/` so feature pages do not
depend on Home just to render inside the shell.

## Providers

Home currently owns no Riverpod providers.

## Accepted Dependencies

Home may depend on feature controllers needed to render shell-owned tab labels,
selection state, and debug controls. Feature-specific buttons should be passed
in by the owning feature instead of imported by Home.

## Tests

Home tests live under `test/features/home/`.
