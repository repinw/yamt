import 'package:material_ui/material_ui.dart';

/// Keys that tests use to find the app update UI.
abstract final class AppUpdateKeys {
  /// The update button on the update-required page.
  static const requiredUpdateAction = Key('app_update_required_action');

  /// The snackbar that says a newer version exists.
  static const availableSnackBar = Key('app_update_available_snack_bar');
}
