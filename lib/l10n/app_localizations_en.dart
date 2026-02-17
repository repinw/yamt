// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTitle => 'Welcome';

  @override
  String get appSubtitle => 'Yet Another Meal Tracker';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get loginAsGuest => 'Login as guest';

  @override
  String get createAccount => 'Create account';

  @override
  String get authSwitchToRegister => 'Don\'t have an account? Register';

  @override
  String get authSwitchToLogin => 'Already have an account? Login';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get validationPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get authFailed => 'Authentication failed';
}
