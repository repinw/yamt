# App Update Feature

App Update tells the user about a newer app version and records which
version runs on each device of a user.

## Owns

- The page that replaces the app while it is older than the minimum
  version, and the button that opens Google Play or TestFlight.
- The snackbar that names a newer version once per version.
- The app version of each device in `users/{uid}/clients/{installId}`.

## Does Not Own

- The version check itself (`config/app_version`, `AppUpdateStatus`): it
  lives in `lib/core`, because the router and future migrations need it
  before any feature.
- Setting the versions: the release does that with admin access
  (`tool/set_app_version.sh`).

## Public UI

- `AppUpdateHintListener`: wraps the app below its `ScaffoldMessenger`.
