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
  String get homeTitle => 'Home';

  @override
  String get homeInventory => 'Inventory';

  @override
  String get homeShopping => 'Shopping';

  @override
  String get homeCalories => 'Calories';

  @override
  String get homeSettings => 'Settings';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose app language';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsNotificationsSubtitle => 'Manage reminders and alerts';

  @override
  String get settingsAccountTitle => 'Account';

  @override
  String get settingsAccountSubtitle => 'Manage profile and sign-in';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String get settingsAboutSubtitle => 'App version and information';

  @override
  String get appSubtitle => 'Yet Another Meal Tracker';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get loginAsGuest => 'Login as guest';

  @override
  String get loginWithGoogle => 'Login with Google';

  @override
  String get registerWithGoogle => 'Register with Google';

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

  @override
  String get authErrorInvalidEmail => 'The email address is not valid.';

  @override
  String get authErrorUserDisabled => 'This user account has been disabled.';

  @override
  String get authErrorUserNotFound => 'No account found for this email.';

  @override
  String get authErrorWrongPassword => 'The password is incorrect.';

  @override
  String get authErrorInvalidCredential => 'The login credentials are invalid.';

  @override
  String get authErrorEmailAlreadyInUse => 'An account already exists for this email.';

  @override
  String get authErrorWeakPassword => 'The password is too weak.';

  @override
  String get authErrorOperationNotAllowed => 'This sign-in method is not enabled.';

  @override
  String get authErrorTooManyRequests => 'Too many requests. Please try again later.';

  @override
  String get authErrorNetworkRequestFailed => 'Network error. Please check your connection.';

  @override
  String get authErrorRequiresRecentLogin => 'Please log in again to continue.';

  @override
  String get authErrorAccountExistsWithDifferentCredential => 'An account already exists with a different sign-in method.';

  @override
  String get authErrorCredentialAlreadyInUse => 'This credential is already used by another account.';

  @override
  String get authErrorProviderAlreadyLinked => 'This sign-in provider is already linked to your account.';

  @override
  String get authErrorGoogleSignInCanceled => 'Google sign-in failed. Please try again.';

  @override
  String get authErrorGoogleIdTokenMissing => 'Google sign-in did not return a valid token.';
}
