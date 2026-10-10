# What's New Feature

What's New tells users who updated the app what the running version brings,
once per version.

## Owns

- The release notes bundled with the app, one file per version in
  `assets/whats_new/<version>.json` with German and English lists `new`,
  `improved`, and `fixed`. The release copies the file from
  `distribution/<version>/whats_new.json` and deletes the file of the
  previous version, since only the running version's file is read.
- The notice "New in <version>: <first new point>" with the action "See all",
  and the sheet that lists all notes in the device language.
- The last version whose notes this device saw, in the device preferences.

## Rules

- The notice shows once per version, when the version is newer than the last
  one seen, and only once the app is on a `/home` page, so never over
  sign-in, onboarding, or the update page. The version counts as seen when
  the notice shows. A version without a notes file shows nothing.
- The notice is an app snack bar, so another snack bar shown at the same
  moment (such as the "newer version available" hint) replaces it, and it
  does not come back.
- A fresh install sees nothing. A device counts as used before when some
  account finished the onboarding on it (the onboarding marker in the device
  preferences); without that marker and without a seen version, the app only
  stores the running version.
- A user who skipped versions sees only the notes of the running version.

## Does Not Own

- The app version itself (`appVersionProvider` in `lib/core`).
- The "newer version available" hint: App Update owns it.

## Public UI

- `WhatsNewListener`: wraps the app below its `ScaffoldMessenger`.
