# Home Feature

Home owns the tab shell, tab navigation, and shell-level composition.

## Owns

- Home shell routing and tab selection: Diary, Inventory, Cookbook, Progress.
- Shell-only navigation state and bottom navigation chrome.
- The side menu (`presentation/widgets/home_slide_menu.dart` and
  `home_menu_panel.dart`). Opening it slides the whole shell to the right,
  shrinks it to a rounded card, and shows the menu behind it. Tapping the
  card, the close button, or system back closes it. The menu lists the
  signed-in user, the app-wide destinations (Profile, goal archive,
  household, kitchen utensils, shopping list, settings, about), an account
  entry at the bottom, and in debug builds the Calories debug actions. Only
  the Diary top bar opens the menu, through `HomeShellMenuButton` from
  `core/widgets` on its left side. Actions that belong to one tab do not go
  into the menu.
- The action button in the middle of the bottom bar and its action panel
  (`presentation/widgets/home_action_panel.dart`). It opens like the side
  menu, mirrored, with the tab's actions at the bottom right. Vorrat,
  Diary, and Cookbook have it; Fortschritt does not. Taps on each action
  are counted on the device (`HomeActionUsageController`), and the most used
  action of the panel gets a lime icon tile
  (`domain/home_action_ranking.dart`). The order of the actions stays fixed.

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

- `HomeActionUsageController` in `presentation/controllers/` holds the tap
  counts of the panel actions.
- `homeActionUsageRepositoryProvider` in `data/` stores them in the app
  preferences of the device.

## Accepted Dependencies

Home may depend on feature controllers needed to render shell-owned tab labels,
selection state, and debug controls. Feature-specific buttons should be passed
in by the owning feature instead of imported by Home.

## Tests

Home tests live under `test/features/home/`.
