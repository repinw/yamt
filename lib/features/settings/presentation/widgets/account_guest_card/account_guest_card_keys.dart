import 'package:material_ui/material_ui.dart';

/// Stable keys for the guest card of the account page.
abstract final class AccountGuestCardKeys {
  /// Button that opens the email link dialog.
  static const linkEmailPasswordButton = ValueKey<String>(
    'account-guest-card-link-email-password-button',
  );
}
