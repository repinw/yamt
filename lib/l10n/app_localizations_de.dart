// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get welcomeTitle => 'Willkommen';

  @override
  String get homeTitle => 'Startseite';

  @override
  String get homeInventory => 'Vorrat';

  @override
  String get homeShopping => 'Einkauf';

  @override
  String get homeCalories => 'Kalorien';

  @override
  String get homeSettings => 'Einstellungen';

  @override
  String get settingsLanguageTitle => 'Sprache';

  @override
  String get settingsLanguageSubtitle => 'App-Sprache auswählen';

  @override
  String get settingsNotificationsTitle => 'Benachrichtigungen';

  @override
  String get settingsNotificationsSubtitle => 'Erinnerungen und Hinweise verwalten';

  @override
  String get settingsAccountTitle => 'Konto';

  @override
  String get settingsAccountSubtitle => 'Profil und Anmeldung verwalten';

  @override
  String get settingsAboutTitle => 'Über die App';

  @override
  String get settingsAboutSubtitle => 'App-Version und Informationen';

  @override
  String get appSubtitle => 'Yet Another Meal Tracker';

  @override
  String get login => 'Login';

  @override
  String get register => 'Registrieren';

  @override
  String get loginAsGuest => 'Als Gast anmelden';

  @override
  String get loginWithGoogle => 'Mit Google anmelden';

  @override
  String get registerWithGoogle => 'Mit Google registrieren';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get authSwitchToRegister => 'Noch kein Konto? Registrieren';

  @override
  String get authSwitchToLogin => 'Bereits ein Konto? Login';

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get confirmPasswordLabel => 'Passwort bestätigen';

  @override
  String get validationPasswordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String get authFailed => 'Authentifizierung fehlgeschlagen';

  @override
  String get authErrorInvalidEmail => 'Die E-Mail-Adresse ist ungültig.';

  @override
  String get authErrorUserDisabled => 'Dieses Benutzerkonto wurde deaktiviert.';

  @override
  String get authErrorUserNotFound => 'Kein Konto mit dieser E-Mail gefunden.';

  @override
  String get authErrorWrongPassword => 'Das Passwort ist falsch.';

  @override
  String get authErrorInvalidCredential => 'Die Anmeldedaten sind ungültig.';

  @override
  String get authErrorEmailAlreadyInUse => 'Für diese E-Mail existiert bereits ein Konto.';

  @override
  String get authErrorWeakPassword => 'Das Passwort ist zu schwach.';

  @override
  String get authErrorOperationNotAllowed => 'Diese Anmeldemethode ist nicht aktiviert.';

  @override
  String get authErrorTooManyRequests => 'Zu viele Anfragen. Bitte später erneut versuchen.';

  @override
  String get authErrorNetworkRequestFailed => 'Netzwerkfehler. Bitte Internetverbindung prüfen.';

  @override
  String get authErrorRequiresRecentLogin => 'Bitte melde dich erneut an, um fortzufahren.';

  @override
  String get authErrorAccountExistsWithDifferentCredential => 'Es existiert bereits ein Konto mit einer anderen Anmeldemethode.';

  @override
  String get authErrorCredentialAlreadyInUse => 'Diese Anmeldeinformation wird bereits von einem anderen Konto verwendet.';

  @override
  String get authErrorProviderAlreadyLinked => 'Dieser Anmeldeanbieter ist bereits mit deinem Konto verknüpft.';

  @override
  String get authErrorGoogleSignInCanceled => 'Google-Anmeldung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get authErrorGoogleIdTokenMissing => 'Google-Anmeldung hat kein gültiges Token geliefert.';
}
